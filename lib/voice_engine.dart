// voice_engine.dart - Motor de Voz Nativo de Aura
import 'package:flutter_tts/flutter_tts.dart';

class AuraVoiceEngine {
  final FlutterTts _flutterTts = FlutterTts();

  AuraVoiceEngine() {
    _initializeVoice();
  }

  void _initializeVoice() async {
    await _flutterTts.setLanguage("es-ES"); // Configura a Aura en español estándar
    await _flutterTts.setSpeechRate(0.55);   // Velocidad cibernética, sofisticada y fluida
    await _flutterTts.setVolume(1.0);        // Volumen de alerta al máximo
    await _flutterTts.setPitch(1.05);        // Tonalidad de voz robótica femenina estilizada
  }

  // Ejecuta la síntesis de voz en tiempo real
  Future<void> speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    }
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
