import UIKit
import Flutter
import FirebaseCore
import GoogleMaps // مكتبة الخرائط الأساسية لـ iOS

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // تهيئة فايربيس
    FirebaseApp.configure()
    
    // تفعيل مفتاح Google Maps API للـ iOS
    GMSServices.provideAPIKey("AIzaSyCZxHqv9-jxB5JUSUQ-BeUoraOfdjWieds")
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}