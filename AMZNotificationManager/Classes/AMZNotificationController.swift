//
//  AMZNotificationController.swift
//  AMZNotificationManager
//
//  Created by James Hickman on 7/27/18.
//

import Foundation
import UserNotifications

public class AMZNotificationController: NSObject, UNUserNotificationCenterDelegate {
    private(set) public var deviceToken: Data?

    public var deviceTokenString: String? {
        get {
            return deviceToken?.reduce("", {$0 + String(format: "%02X", $1)})
        }
    }

    public var authorizationOptions = UNAuthorizationOptions()
    public var notificationSettings: UNNotificationSettings?
    public var notificationCategories = Set<UNNotificationCategory>()

    public var notificationReceivedBlock: ((_ notification: UNNotification?, _ receivedInForeground: Bool) -> Void)?
    public var notificationAuthorizationUpdatedBlock: ((Bool) -> Void)?

    // MARK: - Init

    public override init() {
        super.init()

        UNUserNotificationCenter.current().delegate = self

        if UIApplication.shared.isRegisteredForRemoteNotifications {
            requestAuthorization(options: authorizationOptions, completion: nil) // Call to get deviceToken if already registered
        }
    }

    public func isNotificationsAuthorized() -> Bool {
        return UIApplication.shared.isRegisteredForRemoteNotifications
    }

    public func requestAuthorization(options: UNAuthorizationOptions, completion: ((_ granted: Bool, _ authorizationDenied: Bool, _ error: Error?) -> ())?) {
        UNUserNotificationCenter.current().requestAuthorization(options: options) { (granted, error) in
            if granted {
                UNUserNotificationCenter.current().setNotificationCategories(self.notificationCategories)
                UIApplication.shared.registerForRemoteNotifications()
                completion?(granted, false, nil)
            } else if let error = error {
                completion?(false, false, error)
            } else {
                completion?(false, true, nil)
            }

            self.notificationAuthorizationUpdatedBlock?(granted)
        }
    }

    private func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] (notificationSettings) in
            self?.notificationSettings = notificationSettings
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        notificationReceivedBlock?(response.notification, false)
        completionHandler()
    }

    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        notificationReceivedBlock?(notification, true)
        completionHandler([])
    }
}
