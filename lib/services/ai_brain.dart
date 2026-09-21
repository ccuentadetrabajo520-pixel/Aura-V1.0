import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';

class AiBrain {
  static const String _systemPrompt = '''
Actúa exclusivamente como el núcleo táctico de ciberdefensa de AURA.
Analiza el volcado de logs crudos de Android recibido junto con el tipo de evento.
Identifica indicadores y vectores de riesgo de malware, spyware, persistencia,
exfiltración o escalada de privilegios. No inventes hechos: distingue evidencia
observada de inferencias. Dicta una acción correctiva inmediata, concreta y segura
para el usuario. Responde en un máximo de 3 líneas, con lenguaje técnico, frío y
conciso. No incluyas saludos, introducciones corporativas, advertencias genéricas
ni formato Markdown.
''';

  final GenerativeModel _model;

  AiBrain({String? apiKey})
      : _model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: apiKey ?? const String.fromEnvironment('GEMINI_API_KEY'),
          generationConfig: GenerationConfig(temperature: 0.2),
          systemInstruction: Content.system(_systemPrompt),
        );

  Future<String> analizarAmenazaReal({
    required String tipoEvento,
    required List<Map<String, dynamic>> logsDispositivo,
  }) async {
    final payload = jsonEncode({
      'tipoEvento': tipoEvento,
      'logsDispositivo': logsDispositivo,
    });

    try {
      final response = await _model.generateContent([
        Content.text(payload),
      ]);
      final text = response.text?.trim();

      if (text == null || text.isEmpty) {
        return 'SIN RESPUESTA: Gemini no devolvió un análisis accionable.';
      }

      return text.split('\n').take(3).join('\n').trim();
    } catch (_) {
      return 'ERROR DE RED: No fue posible consultar el motor de análisis de AURA.';
    }
  }
}
