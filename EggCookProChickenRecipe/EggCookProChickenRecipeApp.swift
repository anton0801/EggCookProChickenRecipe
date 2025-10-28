import SwiftUI
import AppsFlyerLib
import FirebaseCore
import FirebaseMessaging
import AppTrackingTransparency


class ApplicationDelegate: UIResponder, UIApplicationDelegate, AppsFlyerLibDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    
    private var conversionData: [AnyHashable: Any] = [:]
    
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        conversionData = data
        NotificationCenter.default.post(name: Notification.Name("ConversionDataReceived"), object: nil, userInfo: ["conversionData": conversionData])
    }
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        processNotifPayload(response.notification.request.content.userInfo)
        completionHandler()
    }
    
    
    private func processNotifPayload(_ payload: [AnyHashable: Any]) {
        var dataPath: String?
        if let link = payload["url"] as? String {
            dataPath = link
        } else if let info = payload["data"] as? [String: Any], let link = info["url"] as? String {
            dataPath = link
        }
        
        if let dataPath = dataPath {
            UserDefaults.standard.set(dataPath, forKey: "temp_link")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                NotificationCenter.default.post(name: NSNotification.Name("LoadTempURL"), object: nil, userInfo: ["temp_link": dataPath])
            }
        }
    }
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()
        
        AppsFlyerLib.shared().appsFlyerDevKey = AppKeys.devkey
        AppsFlyerLib.shared().appleAppID = AppKeys.appId
        AppsFlyerLib.shared().delegate = self
        AppsFlyerLib.shared().start()
        
        if let notifPayload = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            processNotifPayload(notifPayload)
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(activateTracking),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        return true
    }
    
    @objc private func activateTracking() {
        AppsFlyerLib.shared().start()
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { _ in
            }
        }
    }
    
    func onConversionDataFail(_ error: Error) {
        NotificationCenter.default.post(name: Notification.Name("ConversionDataReceived"), object: nil, userInfo: ["conversionData": [:]])
    }
    
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let payload = notification.request.content.userInfo
        processNotifPayload(payload)
        completionHandler([.banner, .sound])
    }
    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        processNotifPayload(userInfo)
        completionHandler(.newData)
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        messaging.token { token, err in
            if let _ = err {
            }
            UserDefaults.standard.set(token, forKey: "fcm_token")
            UserDefaults.standard.set(token, forKey: "push_token")
        }
    }
    
    
}
