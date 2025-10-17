package com.example.feelin_pay

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "yape_notifications"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    // Inicializar el plugin de notificaciones
                    YapeNotificationPlugin().onAttachedToEngine(flutterEngine.plugins)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}