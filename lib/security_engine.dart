import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

enum SystemThreatLevel { secure, warning, critical }

class AuraSecurityEngine {
  static const MethodChannel _channel =
      MethodChannel('com.ciberdefensa.aura/telemetry');
  static const MethodChannel _antiTamperingChannel =
      MethodChannel('com.ciberdefensa.aura/anti_tampering');
  static const List<String> _rootBinaryPaths = [
    '/sbin/su',
    '/system/bin/su',
    '/system/xbin/su',
  ];

  Future<Map<String, dynamic>> checkDeviceIntegrity() async {
    Map<dynamic, dynamic>? nativeReport;
    Map<dynamic, dynamic>? antiTamperingReport;
    var nativeCheckFailed = false;

    try {
      nativeReport = await _channel.invokeMapMethod<dynamic, dynamic>(
        'checkAppIntegrity',
      );
      nativeCheckFailed = nativeReport == null;
    } on PlatformException {
      nativeCheckFailed = true;
    } on MissingPluginException {
      nativeCheckFailed = true;
    }

    try {
      antiTamperingReport =
          await _antiTamperingChannel.invokeMapMethod<dynamic, dynamic>(
        'checkIntegrity',
      );
      nativeCheckFailed = nativeCheckFailed || antiTamperingReport == null;
    } on PlatformException {
      nativeCheckFailed = true;
    } on MissingPluginException {
      nativeCheckFailed = true;
    }

    final rootBinaryFound = await _hasRootBinary();
    final debuggerDetected = nativeReport?['isDebuggerConnected'] == true ||
        antiTamperingReport?['isDebuggerConnected'] == true;
    final alteredEnvironment = nativeReport?['isVirtualEnvironment'] == true;
    final fridaDetected = antiTamperingReport?['fridaDetected'] == true;
    final adbBlocked = antiTamperingReport?['adbBlocked'] == true;
    final debuggerBlocked = antiTamperingReport?['debuggerBlocked'] == true;
    final signatureValid = antiTamperingReport?['signatureValid'] == true;
    final antiTamperingFailed = antiTamperingReport?['isSecure'] == false;
    final compromised =
        rootBinaryFound ||
        debuggerBlocked ||
        alteredEnvironment ||
        fridaDetected ||
        adbBlocked ||
        antiTamperingFailed;
    final level = compromised
        ? SystemThreatLevel.critical
        : nativeCheckFailed
            ? SystemThreatLevel.warning
            : SystemThreatLevel.secure;

    return {
      'level': level,
      'logs': compromised
          ? 'ALERTA: indicador de root, debugger o entorno alterado detectado.'
          : nativeCheckFailed
              ? 'AVISO: no se pudo completar la comprobación nativa de integridad.'
              : 'Aura Core: comprobaciones de integridad completadas.',
      'rootBinaryFound': rootBinaryFound,
      'isDebuggerConnected': debuggerDetected,
      'debuggerBlocked': debuggerBlocked,
      'isVirtualEnvironment': alteredEnvironment,
      'fridaDetected': fridaDetected,
      'adbEnabled': antiTamperingReport?['adbEnabled'] == true,
      'adbBlocked': adbBlocked,
      'signatureValid': signatureValid,
      'antiTamperingCheckFailed': antiTamperingFailed,
      'localDebugFallback':
          antiTamperingReport?['localDebugFallback'] == true,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Stream<Map<String, dynamic>> monitorDeviceIntegrity({
    Duration interval = const Duration(seconds: 5),
  }) async* {
    while (true) {
      yield await checkDeviceIntegrity();
      await Future<void>.delayed(interval);
    }
  }

  Future<bool> _hasRootBinary() async {
    for (final path in _rootBinaryPaths) {
      try {
        if (await File(path).exists()) return true;
      } on FileSystemException {
        continue;
      }
    }
    return false;
  }
}
