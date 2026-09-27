package com.ciberdefensa.aura

import android.content.Intent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.IntentFilter
import android.net.VpnService
import android.os.Build
import android.os.Debug
import android.content.pm.PackageManager
import android.content.pm.ApplicationInfo
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private companion object {
        const val VPN_PERMISSION_REQUEST = 1081
    }

    private val SHIELD_CHANNEL = "com.ciberdefensa.aura/shield"
    private val TELEMETRY_CHANNEL = "com.ciberdefensa.aura/telemetry"
    private var pendingShieldResult: MethodChannel.Result? = null
    private var vpnReceiverRegistered = false
    private val vpnStateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val started = intent?.getBooleanExtra("started", false) ?: false
            val message = intent?.getStringExtra("message") ?: "Sin respuesta del servicio VPN."
            pendingShieldResult?.success(started)
            pendingShieldResult = null
            if (!started) android.util.Log.e("AuraVPN", message)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        registerVpnReceiver()

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
                    requestShieldStart(result)
                }

                "stopShield" -> {
                    val intent = Intent(this, AuraVpnService::class.java)
                    stopService(intent)
                    result.success(true)
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
        if (requestCode == VPN_PERMISSION_REQUEST) {
            if (resultCode == RESULT_OK) {
                startVpnService()
            } else {
                pendingShieldResult?.success(false)
                pendingShieldResult = null
            }
        }
    }

    private fun requestShieldStart(result: MethodChannel.Result) {
        if (pendingShieldResult != null) {
            result.error("VPN_BUSY", "Ya hay una solicitud VPN pendiente.", null)
            return
        }

        pendingShieldResult = result
        val consentIntent = VpnService.prepare(this)
        if (consentIntent != null) {
            startActivityForResult(consentIntent, VPN_PERMISSION_REQUEST)
        } else {
            startVpnService()
        }
    }

    private fun startVpnService() {
        try {
            val intent = Intent(this, AuraVpnService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
        } catch (exception: Exception) {
            pendingShieldResult?.success(false)
            pendingShieldResult = null
            android.util.Log.e("AuraVPN", "No se pudo iniciar AuraVpnService.", exception)
        }
    }

    private fun registerVpnReceiver() {
        if (vpnReceiverRegistered) return
        val filter = IntentFilter(AuraVpnService.ACTION_STATE)
        if (Build.VERSION.SDK_INT >= 33) {
            registerReceiver(vpnStateReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("DEPRECATION")
            registerReceiver(vpnStateReceiver, filter)
        }
        vpnReceiverRegistered = true
    }

    override fun onDestroy() {
        if (vpnReceiverRegistered) {
            unregisterReceiver(vpnStateReceiver)
            vpnReceiverRegistered = false
        }
        pendingShieldResult?.success(false)
        pendingShieldResult = null
        super.onDestroy()
    }
}
