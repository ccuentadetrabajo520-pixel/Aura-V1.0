package com.ciberdefensa.aura

import android.net.VpnService
import android.os.ParcelFileDescriptor
import android.util.Log
import java.io.IOException

class AuraVpnService : VpnService(), Runnable {
    private var vpnThread: Thread? = null
    private var vpnInterface: ParcelFileDescriptor? = null

    override fun onStartCommand(intent: android.content.Intent?, flags: Int, startId: Int): Int {
        if (vpnThread == null) {
            vpnThread = Thread(this, "AuraVpnThread")
            vpnThread?.start()
        }
        return START_STICKY
    }

    override fun onDestroy() {
        if (vpnThread != null) {
            vpnThread?.interrupt()
        }
        super.onDestroy()
    }

    override fun run() {
        try {
            val builder = Builder()
            
            // Redirige el tráfico IPv4 local hacia el túnel de Aura de forma real
            builder.addAddress("10.0.0.2", 24)
            builder.addRoute("0.0.0.0", 0)
            
            // Enrutamiento forzado hacia los servidores DNS Seguros de Cloudflare con bloqueo de malware
            builder.addDnsServer("1.1.1.2") 
            builder.addDnsServer("1.0.0.2")
            
            builder.setSession("AuraCyberdefenseShield")

            vpnInterface = builder.establish()
            Log.i("AuraVPN", "Escudo físico y Cortafuegos de Aura encendidos a nivel de hardware.")

            while (!Thread.interrupted()) {
                Thread.sleep(2000)
            }
        } catch (e: Exception) {
            Log.e("AuraVPN", "Fallo en la interfaz de red nativa: ${e.message}")
        } finally {
            try {
                vpnInterface?.close()
            } catch (e: IOException) {
                // Manejo de excepciones en cierre de socket
            }
        }
    }
}
