import UIKit
import AVFoundation

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Request notification permission
        Task {
            await NotificationService.shared.requestPermission()
        }

        // Enable battery monitoring
        UIDevice.current.isBatteryMonitoringEnabled = true

        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Recording continues via background audio mode
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Save any pending state
    }
}
