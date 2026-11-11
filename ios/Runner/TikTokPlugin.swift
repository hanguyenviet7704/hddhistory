// TiktokPlugin.swift
import Foundation
import Flutter
import UIKit
import TikTokBusinessSDK

@objc public class TikTokPlugin: NSObject {
    private weak var controller: FlutterViewController?
    private let channelName: String = "com.hddhistory.app/tiktok"
    private let appId: String = "6755175330"
    private let tiktokAppId: String = "7616621825847132161"
    private let accessToken: String = "TTKsC83KcYdgZKrcohNfRlHq6wsdVmdK"
    
    public init(controller: FlutterViewController) {
        self.controller = controller
        super.init()
        setupMethodChannel()
    }
    
    // MARK: - Flutter ↔ Native bridge
    private func setupMethodChannel() {
        guard let controller = controller else {
            NSLog("[TikTokPlugin] ⚠️ FlutterViewController not available")
            return
        }
        let channel = FlutterMethodChannel(
          name: channelName,
          binaryMessenger: controller.binaryMessenger
        )
        
        channel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else { return }
            NSLog("[TikTokPlugin] 📲 Method called: \(call.method)")
            NSLog("[TikTokPlugin] 📥 Arguments: \(call.arguments ?? [:])")
            
            switch call.method {
            case "initialize":
                NSLog("[TikTokPlugin] ▶️ initialize")
                self.setupTikTokSDK()
                result(true)
            case "trackEvent":
                NSLog("[TikTokPlugin] ▶️ trackEvent")
                guard let args = call.arguments as? [String: Any],
                      let eventName = args["eventName"] as? String else {
                    NSLog("[TikTokPlugin] ⚠️ trackEvent missing eventName")
                    return result(FlutterError(
                      code:    "INVALID_ARGUMENTS",
                      message: "Event name is required",
                      details: nil
                    ))
                }
                let props = args["properties"] as? [String: Any]
                self.trackTikTokEvent(eventName: eventName, properties: props, result: result)
            default:
                NSLog("[TikTokPlugin] ⚠️ Method not implemented: \(call.method)")
                result(FlutterMethodNotImplemented)
            }
        }
    }

    // MARK: - TikTok SDK bootstrap
    private func setupTikTokSDK() {
        NSLog("[TikTokPlugin] 🔧 setupTikTokSDK() called")
        let config = TikTokConfig(
          accessToken: accessToken,
          appId: appId,
          tiktokAppId: tiktokAppId
        )
        
        NSLog("[TikTokPlugin] ⏳ Initializing TikTok SDK…")
        TikTokBusiness.initializeSdk(config) { success, error in
          if success {
            NSLog("[TikTokPlugin] ✅ TikTok SDK initialized successfully")
          } else {
            NSLog("[TikTokPlugin] ❌ TikTok SDK initialization failed: \(String(describing: error))")
          }
        }
    }
        
    // MARK: - Event tracking
    private func trackTikTokEvent(
      eventName: String,
      properties: [String: Any]?,
      result: @escaping FlutterResult
    ) {
        guard TikTokBusiness.isInitialized() else {
            NSLog("[TikTokPlugin] ❌ SDK_NOT_INITIALIZED")
            return result(FlutterError(
              code:    "SDK_NOT_INITIALIZED",
              message: "TikTok SDK is not initialized",
              details: nil
            ))
        }

        let uuid = UUID().uuidString
        let ttEvent = TikTokBaseEvent(eventName: eventName, eventId: uuid)
        
        // Add properties to the event if they exist
        if let props = properties {
            NSLog("[TikTokPlugin] 📊 Tracking event '\(eventName)' with properties: \(props)")
            
            // Add each property to the ttEvent
            for (key, value) in props {
                // Handle different value types
                switch value {
                case let stringValue as String:
                    ttEvent.addProperty(withKey: key, value: stringValue)
                case let intValue as Int:
                    ttEvent.addProperty(withKey: key, value: intValue)
                case let doubleValue as Double:
                    ttEvent.addProperty(withKey: key, value: doubleValue)
                case let boolValue as Bool:
                    ttEvent.addProperty(withKey: key, value: boolValue)
                default:
                    // Convert other types to string
                    ttEvent.addProperty(withKey: key, value: "\(value)")
                }
            }
        } else {
            NSLog("[TikTokPlugin] 📊 Tracking event '\(eventName)' without properties")
        }
        
        // Track the event
        TikTokBusiness.trackTTEvent(ttEvent)
        
        NSLog("[TikTokPlugin] ✅ Event tracked: \(eventName)")
        result(true)
    }
}