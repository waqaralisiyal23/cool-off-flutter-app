package com.codysseylabs.cooloff

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Receives text shared into Cool Off from other apps (Android share sheet →
 * "Cool Off"), and hands it to Dart, which puts it in the draft.
 *
 * `cooloff/share` method `takeInitialText`: the text that launched the app,
 * once. `cooloff/share/events`: text shared while the app is running.
 * Nothing is read from other apps: only what the user explicitly shares.
 */
class MainActivity : FlutterActivity() {
    private var pendingText: String? = null
    private var events: EventChannel.EventSink? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // A recreated activity (rotation, process restore) gets its old
        // intent back; only a fresh launch carries a new share.
        if (savedInstanceState == null) {
            pendingText = sharedText(intent)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val text = sharedText(intent) ?: return
        val sink = events
        if (sink != null) sink.success(text) else pendingText = text
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, "cooloff/share").setMethodCallHandler { call, result ->
            when (call.method) {
                "takeInitialText" -> {
                    result.success(pendingText)
                    pendingText = null
                }
                else -> result.notImplemented()
            }
        }
        EventChannel(messenger, "cooloff/share/events").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                    events = sink
                }

                override fun onCancel(arguments: Any?) {
                    events = null
                }
            },
        )
    }

    private fun sharedText(intent: Intent?): String? {
        if (intent?.action != Intent.ACTION_SEND) return null
        if (intent.type?.startsWith("text/") != true) return null
        return intent.getStringExtra(Intent.EXTRA_TEXT)?.takeIf { it.isNotBlank() }
    }
}
