package com.example.signasphere

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.signasphere/navigation"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register the native sign language platform view
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "sign_language_view",
            SignLanguageViewFactory(flutterEngine.dartExecutor.binaryMessenger)
        )

        // Handle widget deep-link navigation
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialRoute" -> {
                    val route = intent?.getStringExtra("route")
                    result.success(route)
                }
                else -> result.notImplemented()
            }
        }
    }
}
