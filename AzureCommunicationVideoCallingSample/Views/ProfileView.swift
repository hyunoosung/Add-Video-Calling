//
//  ProfileView.swift
//  AzureCommunicationVideoCallingSample
//
//  Created by Hyounwoo Sung on 2021/02/01.
//

import SwiftUI


struct ProfileView: View {
    @EnvironmentObject var authenticationViewModel: AuthenticationViewModel
    @EnvironmentObject var notificationViewModel: NotificationViewModel
    @EnvironmentObject var callingViewModel: CallingViewModel

    @State var selectedCategory = ProfileCategory.coummunications

    var body: some View {
        VStack {
            if callingViewModel.hasCallAgent {
                Picker("Profile", selection: $selectedCategory) {
                    Text("Communications").tag(ProfileCategory.coummunications)
                    Text("Notifications").tag(ProfileCategory.notifications)
                }
                .pickerStyle(SegmentedPickerStyle())

                if selectedCategory == ProfileCategory.coummunications {
                    CommunicationsSetting()
                        .animation(.easeOut)
                        .transition(.move(edge: .trailing))
                }

                if selectedCategory == ProfileCategory.notifications {
                    NotificationsSetting()
                        .animation(.easeOut)
                        .transition(.move(edge: .leading))
                }
            } else {
                Text("Sign In required")
            }
        }
        .onReceive(authenticationViewModel.$currentTab, perform: { currentTab in
            if (currentTab == .profile && !callingViewModel.hasCallAgent) {
                print("set signInRequired to true in Profile view.\n")
                authenticationViewModel.signInRequired = true
            }
        })
        .onAppear(perform: {
            print("onAppear: Profile view")
        })
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        TabView {
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
                .environmentObject(AuthenticationViewModel())
                .environmentObject(NotificationViewModel())
                .environmentObject(CallingViewModel())
        }
    }
}
