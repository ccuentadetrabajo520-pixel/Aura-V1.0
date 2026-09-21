import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'security_engine.dart';
import 'network_auditor.dart';
import 'voice_engine.dart';
import 'ai_brain.dart';
import 'radar_waves.dart';

void main() => runApp(const AuraApp());

class AuraApp extends StatelessWidget {
  const AuraApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aura Cyberdefense',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF020617),
      ),
      home: const AuraCoreScreen(),
    );
  }
}

class AuraCoreScreen extends StatefulWidget {
  const AuraCoreScreen({Key? key}) : super(key: key);

  @override
  State<AuraCoreScreen> createState() => _AuraCoreScreenState();
}

class _AuraCoreScreenState extends State<AuraCoreScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final AuraSecurityEngine _securityEngine = AuraSecurityEngine();
  final AuraNetworkAuditor _networkAuditor = AuraNetworkAuditor();
  final AuraVoiceEngine _voiceEngine = AuraVoiceEngine();
  final AuraAIBrain _aiBrain = AuraAIBrain();
  final TextEditingController _inputController = TextEditingController();
  
  String _securityStatus = "SECURE"; 
  String _liveConsoleLogs = "SISTEMA AURA: Núcleo defensivo activo e íntegro.";
  bool _shieldActive = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _securityEngine.monitorDeviceIntegrity().listen((event) {
      if (_securityStatus != "SCANNING") {
        setState(() {
          _liveConsoleLogs = event["logs"];
          if (event["level"] == SystemThreatLevel.critical) {
            _securityStatus = "THREAT";
            _voiceEngine.speak("Alerta crítica detectada. Posible inyección de memoria activa.");
          } else {
            _securityStatus = _shieldActive ? "THREAT" : "SECURE";
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _voiceEngine.stop();
    _inputController.dispose();
    super.dispose();
  }

  Color _getCoreColor() {
    if (_securityStatus == "SCANNING") return const Color(0xFF06B6D4);
    if (_securityStatus == "THREAT" || _shieldActive) return const Color(0xFFEF4444);
    return const Color(0xFF10B981);
  }

  void _triggerLocalScan() async {
    setState(() {
      _securityStatus = "SCANNING";
      _liveConsoleLogs = "INICIANDO AUDITORÍA INTERNA: Analizando firmas criptográficas y telemetría local...";
    });
    _voiceEngine.speak("Iniciando auditoría interna del sistema.");
    
    bool safetyCheck = await _networkAuditor.verifyGatewaySafety();
    
    setState(() {
      _securityStatus = safetyCheck ? "SECURE" : "THREAT";
      _liveConsoleLogs = safetyCheck 
          ? "ESCANEO COMPLETADO: No se encontraron anomalías en memoria ni aplicaciones espía."
          : "ALERTA: Gateway de red comprometido o sospechoso.";
    });

    _voiceEngine.speak(safetyCheck 
        ? "Análisis completado. Dispositivo seguro." 
        : "Alerta. Se han detectado riesgos potenciales en el canal de red.");
  }

  void _handleAIQuery() async {
    final query = _inputController.text.trim();
    if (query.isEmpty) return;

    _inputController.clear();
    setState(() {
      _liveConsoleLogs = "Aura procesando consulta analítica...";
    });

    final response = await _aiBrain.analyzeCyberThreat(query);
    
    setState(() {
      _liveConsoleLogs = response;
    });
    _voiceEngine.speak(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'AURA AI • SISTEMA DE CIBERDEFENSA',
                style: TextStyle(
                  letterSpacing: 3, 
                  fontWeight: FontWeight.bold, 
                  color: _getCoreColor().withOpacity(0.9),
                  fontSize: 13
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_securityStatus == "SCANNING")
                          AuraRadarWaves(animationValue: _pulseController.value, themeColor: _getCoreColor()),
                        CustomPaint(
                          painter: RobotFacePainter(
                            pulseValue: _pulseController.value,
                            themeColor: _getCoreColor(),
                            state: _securityStatus,
                          ),
                          size: const Size(290, 350),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getCoreColor().withOpacity(0.15)),
                ),
                child: Text(
                  _liveConsoleLogs,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Consola de entrada de texto interactiva para hablar con Aura
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: const InputDecoration(
                        hintText: "Consulta de ciberdefensa...",
                        hintStyle: TextStyle(fontSize: 12, color: Colors.white38),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: _getCoreColor()),
                    onPressed: _handleAIQuery,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getCoreColor().withOpacity(0.15), width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionButton("ESCANEAR", _triggerLocalScan, const Color(0xFF06B6D4)),
                    _buildShieldButton(),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback action, Color buttonColor) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: buttonColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: buttonColor.withOpacity(0.4)),
        ),
      ),
      onPressed: _securityStatus == "SCANNING" ? null : action,
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildShieldButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _shieldActive ? const Color(0xFFEF4444) : const Color(0xFF1E293B),
        foregroundColor: _shieldActive ? Colors.white : const Color(0xFF10B981),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _shieldActive ? Colors.transparent : const Color(0xFF10B981).withOpacity(0.4)),
        ),
      ),
      onPressed: () {
        setState(() {
          _shieldActive = !_shieldActive;
          _networkAuditor.toggleNetworkShield(_shieldActive);
          _liveConsoleLogs = _shieldActive 
              ? "ESCUDO DE RED ACTIVADO: Forzando aislamiento de puertos virtuales."
              : "ESCUDO DESACTIVADO: Retornando a monitoreo pasivo estándar.";
        });
        _voiceEngine.speak(_shieldActive ? "Escudo de red activado." : "Escudo desactivado.");
      },
      child: Text(_shieldActive ? "ESCUDO ACTIVO" : "ACTIVAR ESCUDO", style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class RobotFacePainter extends CustomPainter {
  final double pulseValue;
  final Color themeColor;
  final String state;

  RobotFacePainter({required this.pulseValue, required this.themeColor, required this.state});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = themeColor.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final glowPaint = Paint()
      ..color = themeColor.withOpacity(0.12 * (1.0 + pulseValue))
      ..style = PaintingStyle.fill;

    final facePath = Path()
      ..moveTo(size.width * 0.25, size.height * 0.15)..lineTo(size.width * 0.75, size.height * 0.15)..lineTo(size.width * 0.83, size.height * 0.48)..lineTo(size.width * 0.53, size.height * 0.88)..lineTo(size.width * 0.47, size.height * 0.88)..lineTo(size.width * 0.17, size.height * 0.48)..close();canvas.drawPath(facePath, glowPaint);canvas.drawPath(facePath, paint);canvas.drawLine(Offset(size.width * 0.38, size.height * 0.23), Offset(size.width * 0.62, size.height * 0.23), paint);if (state == "SCANNING") {double scanY = size.height * 0.15 + (size.height * 0.70 * pulseValue);final scanLine = Paint()..color = themeColor..strokeWidth = 2.5;canvas.drawLine(Offset(size.width * 0.18, scanY), Offset(size.width * 0.82, scanY), scanLine);}final leftEye = Rect.fromLTWH(size.width * 0.30, size.height * 0.42, 40, 10 + (2 * pulseValue));final rightEye = Rect.fromLTWH(size.width * 0.58, size.height * 0.42, 40, 10 + (2 * pulseValue));paint.style = PaintingStyle.fill;canvas.drawOval(leftEye, paint);canvas.drawOval(rightEye, paint);paint.style = PaintingStyle.stroke;final mouthPath = Path();double startX = size.width * 0.42;double endX = size.width * 0.58;double midY = size.height * 0.70;mouthPath.moveTo(startX, midY);for (double i = startX; i += 4) {double wave = (state == "THREAT")? math.sin((i + pulseValue * 45)) * 10: math.sin((i + pulseValue * 15)) * (3 + pulseValue * 3);mouthPath.lineTo(i, midY + wave);}canvas.drawPath(mouthPath, paint);}@overridebool shouldRepaint(covariant RobotFacePainter oldDelegate) => true;}
