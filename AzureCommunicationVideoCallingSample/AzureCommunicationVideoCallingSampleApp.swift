//
//  AzureCommunicationVideoCallingSampleApp.swift
//  AzureCommunicationVideoCallingSample
//
//  Created by Hyounwoo Sung on 2021/02/01.
//

import SwiftUI

@main
struct AzureCommunicationVideoCallingSampleApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var authenticationViewModel = AuthenticationViewModel()
    @StateObject private var notificationViewModel = NotificationViewModel()
    @StateObject private var callingViewModel = CallingViewModel.shared()

    init() {
        // Fill in DevSettings.plist for AzureNotificationHubs hubName and connectionString.
        Constants.hubName = getPlistInfo(resourceName: "DevSettings", key: "HUB_NAME")
        Constants.connectionString = getPlistInfo(resourceName: "DevSettings", key: "CONNECTION_STRING")

        // Fill in FirstUser.plist with displayName, identifier, token and receiver identifier to test call feature.
        // Change resouceName to "FirstUser" or "SecondUser" to deploy different credentials.
        let resourceName = "FirstUser"
        Constants.displayName = getPlistInfo(resourceName: resourceName, key: "DISPLAYNAME")
        Constants.identifier = getPlistInfo(resourceName: resourceName, key: "IDENTIFIER")
        Constants.token = getPlistInfo(resourceName: resourceName, key: "TOKEN")
        Constants.callee = getPlistInfo(resourceName: resourceName, key: "CALLEE")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authenticationViewModel)
                .environmentObject(notificationViewModel)
                .environmentObject(callingViewModel)
        }
        .onChange(of: scenePhase) { (newScenePhase) in
            switch newScenePhase {
            case .active:
                print("scene is now active!")
            case .inactive:
                print("scene is now inactive!")
            case .background:
                print("scene is now in the background!")
            @unknown default:
                print("Apple must have added something new!")
            }
        }
    }
}
