import 'services/ai_brain.dart';

class AuraAIBrain {
  final AiBrain _aiBrain;

  AuraAIBrain({AiBrain? aiBrain}) : _aiBrain = aiBrain ?? AiBrain();

  Future<String> analyzeCyberThreat(String userInput) async {
    return _aiBrain.analizarAmenazaReal(
      tipoEvento: 'CONSULTA_MANUAL_DE_CIBERDEFENSA',
      logsDispositivo: [
        <String, dynamic>{'entradaUsuario': userInput},
      ],
    );
  }
}

