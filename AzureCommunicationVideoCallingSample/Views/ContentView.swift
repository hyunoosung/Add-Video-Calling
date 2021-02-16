//
//  ContentView.swift
//  AzureCommunicationVideoCallingSample
//
//  Created by Hyounwoo Sung on 2021/02/01.
//

import SwiftUI
import WindowsAzureMessaging
import AzureCommunicationCalling

struct ContentView: View {
    @EnvironmentObject var authenticationViewModel: AuthenticationViewModel
    @EnvironmentObject var notificationViewModel: NotificationViewModel
    @EnvironmentObject var callingViewModel: CallingViewModel
    @State private var sheetType: SheetType?
    @State private var showingAlert = false
    @State var notification: MSNotificationHubMessage = MSNotificationHubMessage()
    
    var body: some View {
        NavigationView {
            TabView(selection: $authenticationViewModel.currentTab) {
                ForEach(Tab.allCases) { tab in
                    tab.presentingView
                        .tabItem { tab.tabItem }
                        .tag(tab)
                }
            }
            .navigationBarTitle(authenticationViewModel.currentTab.name, displayMode: .inline)
        }
        .onReceive(authenticationViewModel.$signInRequired, perform: { signInRequired in
            print("signInRequired state changed to \(signInRequired)\n")
            if signInRequired {
                sheetType = .signInRequired
            }
        })
        .onReceive(callingViewModel.$callState, perform: { callState in
            if callState == .connected {
                self.sheetType = .callView
            } else {
                self.sheetType = .none
            }
        })
        .onReceive(self.notificationViewModel.messageReceived) { (notification) in
            self.didReceivePushNotification(notification: notification, messageTapped: false)
        }
        .onReceive(self.notificationViewModel.messageTapped) { (notification) in
            self.didReceivePushNotification(notification: notification, messageTapped: true)
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text(self.notification.title ?? "Important message"), message: Text(self.notification.body ?? "Wear sunscreen"), dismissButton: .default(Text("Got it!")))
        }
        .fullScreenCover(item: $sheetType) { item in
            switch item {
            case .signInRequired:
                SignInView()
                    .environmentObject(authenticationViewModel)
                    .environmentObject(notificationViewModel)
                    .environmentObject(callingViewModel)
            case .callView:
                CallView()
                    .environmentObject(authenticationViewModel)
                    .environmentObject(callingViewModel)
            default:
                Text("Not specified yet!")
            }
        }
        .onAppear(
            perform: checkToken
        )
        .environmentObject(authenticationViewModel)
        .environmentObject(notificationViewModel)
        .environmentObject(callingViewModel)
    }

    func checkToken() {
        if !callingViewModel.hasCallAgent {
            if let communicationUserTokenModel = authenticationViewModel.getCommunicationUserToken() {
                callingViewModel.initCallAgent(communicationUserTokenModel: communicationUserTokenModel, displayName: authenticationViewModel.displayName) { (success) in
                    if success {
                        notificationViewModel.connectToHub()
                    } else {
                        print("callAgent not intialized.\n")
                    }
                }
            } else {
                print("no token found stay at Home.")
            }
        } else {
            notificationViewModel.connectToHub()
        }
    }

    func didReceivePushNotification(notification: Notification, messageTapped: Bool) {
        let message = notification.userInfo!["message"] as! MSNotificationHubMessage
        NSLog("Received notification: %@; %@", message.title ?? "<nil>", message.body)

        // Assign the latest notification to self.notification.
        self.notification = message

        // Display Alert if message is tapped from background.
        if messageTapped {
            self.showingAlert = true
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthenticationViewModel())
            .environmentObject(NotificationViewModel())
            .environmentObject(CallingViewModel())
    }
}
