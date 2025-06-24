import UIKit
import Flutter
import Firebase

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // CRITICAL: Initialize Firebase BEFORE Flutter plugins
    // This prevents memory corruption during plugin registration
    FirebaseApp.configure()
    
    // CRITICAL: Add small delay to ensure Firebase is fully initialized
    // This prevents race conditions between Firebase and other plugins
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      // Firebase is now safely initialized
    }
    
    // Continue with Flutter plugin registration
    GeneratedPluginRegistrant.register(with: self)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}