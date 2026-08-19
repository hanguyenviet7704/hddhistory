package com.eup.meup

import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine

// AudioServiceActivity (from the audio_service plugin) supplies the shared
// FlutterEngine that its background audio service also uses, which is
// required for lesson "Listen mode" background playback + OS media controls.
// It extends FlutterActivity, so all existing Flutter behavior is preserved.
class MainActivity: AudioServiceActivity() {
    private var liveActivityChannel: LiveActivityChannel? = null
    private var storyShareChannel: StoryShareChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register TikTok plugin
        TikTokPlugin(applicationContext).registerWith(flutterEngine)

        // Lesson Live Update (Android 16+ promoted ongoing notification) — the
        // Android counterpart to the iOS Live Activity. No-op on older versions.
        liveActivityChannel = LiveActivityChannel(this, flutterEngine.dartExecutor.binaryMessenger)

        // Instagram / Facebook story hand-off (see StoryShareChannel.swift for
        // the iOS half — same channel name, pasteboard instead of an intent).
        storyShareChannel = StoryShareChannel(this, flutterEngine.dartExecutor.binaryMessenger)
    }
}
