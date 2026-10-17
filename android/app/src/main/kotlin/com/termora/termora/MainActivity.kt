package com.termora.termora

import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private val intercepted = mutableSetOf<Int>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "termora/hardware_keys")
        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "setInterceptedKeys" -> {
                    intercepted.clear()
                    call.argument<List<Int>>("keyCodes")?.let { intercepted.addAll(it) }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (event.keyCode in intercepted) {
            val action = if (event.action == KeyEvent.ACTION_DOWN) "down" else "up"
            channel?.invokeMethod(
                "keyEvent",
                mapOf(
                    "keyCode" to event.keyCode,
                    "action" to action,
                    "repeatCount" to event.repeatCount,
                ),
            )
            // Consume the event so the system volume UI does not also react.
            return true
        }
        return super.dispatchKeyEvent(event)
    }
}
