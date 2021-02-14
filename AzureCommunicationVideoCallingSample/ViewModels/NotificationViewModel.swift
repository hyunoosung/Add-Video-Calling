//
//  NotificationViewModel.swift
//  AzureCommunicationVideoCallingSample
//
//  Created by Hyounwoo Sung on 2021/02/07.
//

import Combine
import UserNotifications
import WindowsAzureMessaging

class NotificationViewModel: NSObject, ObservableObject, UNUserNotificationCenterDelegate, MSNotificationHubDelegate, MSInstallationLifecycleDelegate {
    private var notificationPresentationCompletionHandler: Any?
    private var notificationResponseCompletionHandler: Any?

    @Published var installationId: String = MSNotificationHub.getInstallationId()
    @Published var pushChannel: String = MSNotificationHub.getPushChannel()
    @Published var items = [MSNotificationHubMessage]()
    @Published var tags = MSNotificationHub.getTags()
    @Published var userId = MSNotificationHub.getUserId()

    let messageReceived = NotificationCenter.default
                .publisher(for: NSNotification.Name("MessageReceived"))

    let messageTapped = NotificationCenter.default
                .publisher(for: NSNotification.Name("MessageTapped"))

    func connectToHub() {
        let hubName = Constants.hubName
        let connectionString = Constants.connectionString

        if (!connectionString.isEmpty && !hubName.isEmpty)
        {
            UNUserNotificationCenter.current().delegate = self;
            MSNotificationHub.setLifecycleDelegate(self)
            MSNotificationHub.setDelegate(self)
            MSNotificationHub.start(connectionString: connectionString, hubName: hubName)

            print("connected to notification hub")
            addTags()
        }
    }

    func setUserId() {
        MSNotificationHub.setUserId(self.userId)
    }

    func addTags() {
        // Get language and country code for common tag values
        let language = Bundle.main.preferredLocalizations.first ?? "<undefined>"
        let countryCode = NSLocale.current.regionCode ?? "<undefined>"

        // Create tags with type_value format
        let languageTag = "language_" + language
        let countryCodeTag = "country_" + countryCode

        MSNotificationHub.addTags([languageTag, countryCodeTag])
    }

    func addTag(tag: String) {
        MSNotificationHub.addTag(tag)
    }

    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        self.notificationPresentationCompletionHandler = completionHandler;
    }

    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        self.notificationResponseCompletionHandler = completionHandler;
    }


    func notificationHub(_ notificationHub: MSNotificationHub, didSave installation: MSInstallation) {
        DispatchQueue.main.async {
            self.installationId = installation.installationId
            self.pushChannel = installation.pushChannel
            print("notificationHub installation was successful.")
            CallingViewModel.shared().initPushNotification()
        }
    }

    func notificationHub(_ notificationHub: MSNotificationHub!, didFailToSave installation: MSInstallation!, withError error: Error!) {
        CallingViewModel.shared().unRegisterVoIP()
        print("notificationHub installation failed.")
    }

    func notificationHub(_ notificationHub: MSNotificationHub, didReceivePushNotification message: MSNotificationHubMessage) {

        let userInfo = ["message": message]

        // Append receivedPushNotification message to self.items
        self.items.append(message)

        if (notificationResponseCompletionHandler != nil) {
            NSLog("Tapped Notification")
            NotificationCenter.default.post(name: NSNotification.Name("MessageTapped"), object: nil, userInfo: userInfo)
        } else {
            NSLog("Notification received in the foreground")
            NotificationCenter.default.post(name: NSNotification.Name("MessageReceived"), object: nil, userInfo: userInfo)
        }

        // Call notification completion handlers.
        if (notificationResponseCompletionHandler != nil) {
            (notificationResponseCompletionHandler as! () -> Void)()
            notificationResponseCompletionHandler = nil
        }
        if (notificationPresentationCompletionHandler != nil) {
            (notificationPresentationCompletionHandler as! (UNNotificationPresentationOptions) -> Void)([])
            notificationPresentationCompletionHandler = nil
        }
    }

}
