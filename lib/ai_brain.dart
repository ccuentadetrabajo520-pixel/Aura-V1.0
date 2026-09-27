import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AuraAIBrain {
  static const String _modelName = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-2.5-flash',
  );
  static const MethodChannel _shieldChannel =
      MethodChannel('com.ciberdefensa.aura/shield');
  static const MethodChannel _telemetryChannel =
      MethodChannel('com.ciberdefensa.aura/telemetry');

  static const String _systemPrompt = '''
Eres el asistente de seguridad de Aura. Analiza únicamente los datos recibidos.
Invoca activarEscudoRed solo cuando el usuario pida explícitamente activar o
desactivar el escudo. Invoca ejecutarEscaneoDispositivo solo cuando pida un
escaneo. No afirmes que una acción tuvo éxito si la herramienta devuelve error.
Distingue evidencia de inferencia y responde en español de forma concisa.
''';

  static final List<Tool> _tools = [
    Tool(functionDeclarations: [
      FunctionDeclaration(
        'activarEscudoRed',
        'Activa o desactiva el escudo VPN de Aura cuando el usuario lo solicite.',
        Schema.object(
          properties: {
            'activo': Schema.boolean(
                description: 'true para activar, false para detener.'),
          },
          requiredProperties: ['activo'],
        ),
      ),
      FunctionDeclaration(
        'ejecutarEscaneoDispositivo',
        'Inspecciona telemetría de aplicaciones Android y permisos de riesgo.',
        null,
      ),
    ]),
  ];

  final String _apiKey;
  final GenerativeModel _model;

  AuraAIBrain({String? apiKey})
      : _apiKey = apiKey ?? const String.fromEnvironment('GEMINI_API_KEY'),
        _model = GenerativeModel(
          model: _modelName,
          apiKey: apiKey ?? const String.fromEnvironment('GEMINI_API_KEY'),
          generationConfig: GenerationConfig(temperature: 0.2),
          systemInstruction: Content.system(_systemPrompt),
          tools: _tools,
          toolConfig: ToolConfig(
            functionCallingConfig: FunctionCallingConfig(
              mode: FunctionCallingMode.auto,
            ),
          ),
        );

  Future<bool> setShieldActive(bool active) async {
    final result = await _shieldChannel.invokeMethod<bool>(
      active ? 'startShield' : 'stopShield',
    );
    return result ?? false;
  }

  Future<List<Map<String, dynamic>>> scanDevice() async {
    final raw = await _telemetryChannel.invokeListMethod<dynamic>(
      'captureRiskTelemetry',
    );
    return (raw ?? const <dynamic>[])
        .whereType<Map>()
        .take(100)
        .map((entry) => <String, dynamic>{
              for (final item in entry.entries) item.key.toString(): item.value,
            })
        .toList();
  }

  Future<String> analyzeCyberThreat(String userInput) async {
    if (_apiKey.isEmpty) {
      return 'CONFIGURACIÓN REQUERIDA: falta GEMINI_API_KEY.';
    }

    try {
      final chat = _model.startChat();
      var response = await chat.sendMessage(Content.text(userInput));

      for (var turn = 0; turn < 4; turn++) {
        final calls = response.functionCalls.toList();
        if (calls.isEmpty) {
          return response.text?.trim() ?? 'Gemini no devolvió una respuesta.';
        }

        final functionResponses = <FunctionResponse>[];
        for (final call in calls) {
          final result = await _executeTool(call);
          functionResponses.add(FunctionResponse(call.name, result));
        }
        response = await chat.sendMessage(
          Content.functionResponses(functionResponses),
        );
      }

      return response.text?.trim() ??
          'Se alcanzó el límite de acciones automáticas de esta consulta.';
    } catch (error) {
      return 'ERROR DE ANÁLISIS: no se pudo completar la consulta de Aura.';
    }
  }

  Future<Map<String, Object?>> _executeTool(FunctionCall call) async {
    try {
      switch (call.name) {
        case 'activarEscudoRed':
          final active = call.args['activo'];
          if (active is! bool) {
            return {
              'ok': false,
              'error': 'El argumento activo debe ser booleano.'
            };
          }
          final result = await setShieldActive(active);
          return {
            'ok': result,
            'requestedState': active ? 'active' : 'stopped',
          };
        case 'ejecutarEscaneoDispositivo':
          final findings = await scanDevice();
          return {'ok': true, 'count': findings.length, 'findings': findings};
        default:
          return {'ok': false, 'error': 'Herramienta no reconocida.'};
      }
    } on PlatformException catch (error) {
      return {'ok': false, 'error': error.message ?? 'Error del canal nativo.'};
    }
  }
}
