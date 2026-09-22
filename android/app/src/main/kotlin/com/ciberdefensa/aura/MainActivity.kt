package com.ciberdefensa.aura

import android.content.Intent
import android.net.VpnService
import android.os.Debug
import android.content.pm.PackageManager
import android.content.pm.ApplicationInfo
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val SHIELD_CHANNEL = "com.ciberdefensa.aura/shield"
    private val TELEMETRY_CHANNEL = "com.ciberdefensa.aura/telemetry"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            TELEMETRY_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "captureRiskTelemetry" -> {
                    val appRiskList = mutableListOf<Map<String, Any>>()
                    val pm = packageManager
                    val installedPackages = pm.getInstalledPackages(PackageManager.GET_PERMISSIONS)
                    val permisosCriticos = listOf(
                        "android.permission.READ_SMS",
                        "android.permission.RECEIVE_SMS",
                        "android.permission.RECORD_AUDIO",
                        "android.permission.CAMERA",
                        "android.permission.ACCESS_FINE_LOCATION",
                    )

                    for (pkg in installedPackages) {
                        val applicationInfo = pkg.applicationInfo ?: continue
                        if ((applicationInfo.flags and ApplicationInfo.FLAG_SYSTEM) == 0) {
                            val permisosSolicitados = pkg.requestedPermissions
                            if (permisosSolicitados != null) {
                                val coincidenciasRiesgo = mutableListOf<String>()
                                for (permiso in permisosSolicitados) {
                                    if (permisosCriticos.contains(permiso)) {
                                        coincidenciasRiesgo.add(permiso)
                                    }
                                }

                                if (coincidenciasRiesgo.isNotEmpty()) {
                                    val datosApp = mapOf(
                                        "name" to applicationInfo.loadLabel(pm).toString(),
                                        "package" to pkg.packageName,
                                        "target_sdk" to applicationInfo.targetSdkVersion,
                                        "risk_permissions" to coincidenciasRiesgo,
                                    )
                                    appRiskList.add(datosApp)
                                }
                            }
                        }
                    }

                    result.success(appRiskList)
                }

                "checkAppIntegrity" -> {
                    val isDebugActive =
                        Debug.isDebuggerConnected() || Debug.waitingForDebugger()
                    val dataPath = applicationContext.filesDir.absolutePath.lowercase()
                    val isCloned = dataPath.contains("virtual") ||
                        dataPath.contains("parallel") ||
                        dataPath.contains("dual") ||
                        dataPath.contains("multiple")
                    val integrityReport = mapOf(
                        "isDebuggerConnected" to isDebugActive,
                        "isVirtualEnvironment" to isCloned,
                        "isSecure" to (!isDebugActive && !isCloned),
                    )
                    result.success(integrityReport)
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SHIELD_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startShield" -> {
                    val intent = VpnService.prepare(applicationContext)
                    if (intent != null) {
                        startActivityForResult(intent, 0)
                    } else {
                        onActivityResult(0, RESULT_OK, null)
                    }
                    result.success(true)
                }

                "stopShield" -> {
                    val intent = Intent(this, AuraVpnService::class.java)
                    stopService(intent)
                    result.success(false)
                }

                "getLatestBlockedIps" -> {
                    val blockedIps = listOf<String>()
                    result.success(blockedIps)
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (resultCode == RESULT_OK) {
            val intent = Intent(this, AuraVpnService::class.java)
            startService(intent)
        }
    }
}
