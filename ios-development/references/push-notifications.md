# Push Notifications

## APNs設定

### 1. Xcodeプロジェクト設定

1. **Signing & Capabilities** → **+ Capability**
2. **Push Notifications** を追加
3. **Background Modes** → **Remote notifications** をチェック

### 2. App Delegate / App設定

```swift
import SwiftUI
import UserNotifications

@main
struct MyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        registerForPushNotifications()
        return true
    }
    
    func registerForPushNotifications() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                guard granted else { return }
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device Token: \(token)")
        // サーバーにトークンを送信
        Task { await sendTokenToServer(token) }
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register: \(error)")
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    // フォアグラウンドで通知受信
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .badge, .sound]
    }
    
    // 通知タップ時の処理
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        handleNotification(userInfo)
    }
    
    func handleNotification(_ userInfo: [AnyHashable: Any]) {
        if let type = userInfo["type"] as? String {
            switch type {
            case "message":
                // メッセージ画面に遷移
                break
            case "order":
                // 注文画面に遷移
                break
            default:
                break
            }
        }
    }
}
```

---

## ローカル通知

```swift
struct NotificationManager {
    static func scheduleLocal(
        title: String,
        body: String,
        delay: TimeInterval = 5
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: delay,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // 日時指定
    static func scheduleAt(
        title: String,
        body: String,
        date: DateComponents
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: date,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}
```

---

## Firebase Cloud Messaging (FCM)

### セットアップ

```swift
// Package.swift or SPM
.package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0")
```

### AppDelegate拡張

```swift
import FirebaseCore
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        // ... 既存のコード
        return true
    }
    
    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        guard let token = fcmToken else { return }
        print("FCM Token: \(token)")
        // サーバーにFCMトークンを送信
        Task { await sendFCMTokenToServer(token) }
    }
}
```

---

## Rich Notifications（画像・アクション付き）

### Notification Content Extension

1. **File** → **New** → **Target** → **Notification Content Extension**

```swift
// NotificationViewController.swift
import UIKit
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    func didReceive(_ notification: UNNotification) {
        let content = notification.request.content
        titleLabel.text = content.title
        
        if let attachment = content.attachments.first,
           attachment.url.startAccessingSecurityScopedResource() {
            defer { attachment.url.stopAccessingSecurityScopedResource() }
            if let data = try? Data(contentsOf: attachment.url) {
                imageView.image = UIImage(data: data)
            }
        }
    }
}
```

### アクションボタン

```swift
func registerNotificationCategories() {
    let replyAction = UNNotificationAction(
        identifier: "REPLY",
        title: "Reply",
        options: .foreground
    )
    
    let dismissAction = UNNotificationAction(
        identifier: "DISMISS",
        title: "Dismiss",
        options: .destructive
    )
    
    let category = UNNotificationCategory(
        identifier: "MESSAGE",
        actions: [replyAction, dismissAction],
        intentIdentifiers: [],
        options: []
    )
    
    UNUserNotificationCenter.current().setNotificationCategories([category])
}
```

---

## サーバー側（APNs送信例）

```bash
# curl例
curl -v \
  -H "authorization: bearer $JWT_TOKEN" \
  -H "apns-topic: com.example.app" \
  -H "apns-push-type: alert" \
  --http2 \
  -d '{"aps":{"alert":{"title":"Hello","body":"World"}}}' \
  https://api.push.apple.com/3/device/$DEVICE_TOKEN
```
