import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

enum SystemThreatLevel { secure, warning, critical }

class AuraSecurityEngine {
  static const MethodChannel _channel =
      MethodChannel('com.ciberdefensa.aura/telemetry');
  static const List<String> _rootBinaryPaths = [
    '/sbin/su',
    '/system/bin/su',
    '/system/xbin/su',
  ];

  Future<Map<String, dynamic>> checkDeviceIntegrity() async {
    Map<dynamic, dynamic>? nativeReport;
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

    final rootBinaryFound = await _hasRootBinary();
    final debuggerDetected = nativeReport?['isDebuggerConnected'] == true;
    final alteredEnvironment = nativeReport?['isVirtualEnvironment'] == true;
    final compromised =
        rootBinaryFound || debuggerDetected || alteredEnvironment;
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
      'isVirtualEnvironment': alteredEnvironment,
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
