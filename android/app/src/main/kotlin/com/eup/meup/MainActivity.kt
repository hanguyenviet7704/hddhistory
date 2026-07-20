package com.eup.meup

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    private var liveActivityChannel: LiveActivityChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register TikTok plugin
        TikTokPlugin(applicationContext).registerWith(flutterEngine)

        // Lesson Live Update (Android 16+ promoted ongoing notification) — the
        // Android counterpart to the iOS Live Activity. No-op on older versions.
        liveActivityChannel = LiveActivityChannel(this, flutterEngine.dartExecutor.binaryMessenger)
    }
}
