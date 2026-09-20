package com.ciberdefensa.aura

import android.content.Intent
import android.net.VpnService
import android.os.Debug
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.ciberdefensa.aura/shield"

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
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (resultCode == RESULT_OK) {
            val intent = Intent(this, AuraVpnService::class.java)
            startService(intent)
        }
    }
}
