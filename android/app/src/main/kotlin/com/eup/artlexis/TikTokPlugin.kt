package com.eup.meup

import android.content.Context
import android.util.Log
import com.tiktok.TikTokBusinessSdk
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.json.JSONObject

class TikTokPlugin(private val context: Context) : MethodCallHandler {
    private val flutterChannel: String = "com.eup.meup/tiktok"
    private val tikTokAppId: String = "7616621808527228944"
    private val accessToken: String = "TTX8C4DdJdoMsO0FRBaUTNcnZr7HnGjC"
    private val packageName: String = "com.eup.meup"

    fun registerWith(flutterEngine: FlutterEngine) {
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, flutterChannel)
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> initializeTikTokSDK(result)
            "trackEvent" -> {
                val eventName = call.argument<String>("eventName")
                val properties = call.argument<Map<String, Any>>("properties")
                
                if (eventName == null) {
                    result.error("INVALID_ARGUMENTS", "Event name is required", null)
                    return@onMethodCall
                }
                
                trackEvent(eventName, properties, result)
            }
            else -> result.notImplemented()
        }
    }

    private fun initializeTikTokSDK(result: Result) {
        try {
            // Initialize TikTok SDK
            val ttConfig = TikTokBusinessSdk.TTConfig(context, accessToken)
                .setAppId(packageName) // Android package name
                .setTTAppId(tikTokAppId) // TikTok App ID from EM
                .setLogLevel(TikTokBusinessSdk.LogLevel.DEBUG) // prints debug log
            
            TikTokBusinessSdk.initializeSdk(ttConfig)
            TikTokBusinessSdk.startTrack()

            Log.d("TikTokPlugin", "TikTok SDK initialized")
            
            result.success(true)
        } catch (e: Exception) {
            result.error("INIT_FAILED", "Failed to initialize TikTok SDK: ${e.message}", null)
        }
    }

    private fun trackEvent(eventName: String, properties: Map<String, Any>?, result: Result) {
        try {
            if (!TikTokBusinessSdk.isInitialized()) {
                result.error("SDK_NOT_INITIALIZED", "TikTok SDK is not initialized", null)
                return
            }
            
            // Track custom event
            if (properties != null) {
                val jsonObject = JSONObject(properties)
                TikTokBusinessSdk.trackEvent(eventName, jsonObject)
                Log.d("TikTokPlugin", "Event tracked: $eventName with properties: $properties")
            } else {
                TikTokBusinessSdk.trackEvent(eventName)
                Log.d("TikTokPlugin", "Event tracked: $eventName")
            }

            result.success(true)
        } catch (e: Exception) {
            result.error("TRACK_FAILED", "Failed to track event: ${e.message}", null)
        }
    }
}
