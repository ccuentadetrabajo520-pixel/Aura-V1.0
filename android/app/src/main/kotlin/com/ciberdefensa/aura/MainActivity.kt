package com.ciberdefensa.aura

import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.VpnService
import android.os.Debug
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.ciberdefensa.aura/shield"
    private val TELEMETRY_CHANNEL = "com.ciberdefensa.aura/telemetry"

    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
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
                "checkDebugger" -> {
                    val isDebugActive = Debug.isDebuggerConnected()
                    result.success(isDebugActive)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TELEMETRY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "captureRiskTelemetry" -> {
                    val riskPermissions = setOf(
                        "android.permission.READ_SMS",
                        "android.permission.RECEIVE_SMS",
                        "android.permission.RECORD_AUDIO",
                        "android.permission.CAMERA",
                        "android.permission.ACCESS_FINE_LOCATION"
                    )
                    val appRiskList = mutableListOf<Map<String, Any>>()

                    try {
                        val installedPackages = packageManager.getInstalledPackages(PackageManager.GET_PERMISSIONS)

                        for (pkg in installedPackages) {
                            val applicationInfo = pkg.applicationInfo ?: continue
                            if ((applicationInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0) {
                                continue
                            }

                            val requestedPermissions = pkg.requestedPermissions ?: continue
                            val requestedPermissionFlags = pkg.requestedPermissionsFlags ?: IntArray(requestedPermissions.size)
                            val grantedRiskPermissions = requestedPermissions.mapIndexedNotNull { index, permission ->
                                val isGranted = index < requestedPermissionFlags.size &&
                                    (requestedPermissionFlags[index] and PackageInfo.REQUESTED_PERMISSION_GRANTED) != 0
                                if (permission in riskPermissions && isGranted) permission else null
                            }

                            if (grantedRiskPermissions.isNotEmpty()) {
                                appRiskList.add(
                                    mapOf(
                                        "appName" to applicationInfo.loadLabel(packageManager).toString(),
                                        "packageName" to pkg.packageName,
                                        "targetSdkVersion" to applicationInfo.targetSdkVersion,
                                        "riskPermissions" to grantedRiskPermissions
                                    )
                                )
                            }
                        }

                        result.success(appRiskList)
                    } catch (exception: Exception) {
                        result.error("TELEMETRY_ERROR", exception.message, null)
                    }
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
