//
//  HomeView.swift
//  AzureCommunicationVideoCallingSample
//
//  Created by Hyounwoo Sung on 2021/02/01.
//

import SwiftUI
import AzureCommunicationCalling
import AVFoundation

struct HomeView: View {
    @EnvironmentObject var authenticationViewModel: AuthenticationViewModel
    @EnvironmentObject var callingViewModel: CallingViewModel

    var body: some View {
        VStack(spacing: 16) {
            if callingViewModel.hasCallAgent {
                VStack {
                    Form {
                        Section {
                            HStack(alignment: .top) {
                                TextField("GroupId", text: $callingViewModel.groupId)

                                Button(action: {
                                    callingViewModel.callee = ""
                                }, label: {
                                    Image(systemName: "delete.left")
                                        .foregroundColor(Color(UIColor.opaqueSeparator))
                                })
                            }

                            Button(action: joinGroup) {
                                Text("Join Group")
                            }
                        }

                        Section {
                            HStack(alignment: .top) {
                                TextField("Who would you like to call?", text: $callingViewModel.callee)

                                Button(action: {
                                    callingViewModel.callee = ""
                                }, label: {
                                    Image(systemName: "delete.left")
                                        .foregroundColor(Color(UIColor.opaqueSeparator))
                                })
                            }

                            Button(action: startCall) {
                                Text("Start Call")
                            }

                            Button(action: endCall) {
                                Text("End Call")
                            }
                            Text("Call State: \(callingViewModel.callState.name)")
                        }
                    }
                }
            } else {
                Text("Please sign in and update your display name.")
                Button(action: { authenticationViewModel.currentTab = .profile }, label: {
                    HStack {
                        Spacer()
                        Text("Navigate to signIn page")
                        Spacer()
                    }
                })
            }
        }
        .onReceive(self.authenticationViewModel.$currentTab, perform: { currentTab in
            if (currentTab == .home) {
                print("set signInRequired to false in Home view.\n")
                self.authenticationViewModel.signInRequired = false
            }
        })
    }

    func joinGroup() {
        callingViewModel.joinGroup()
    }

    func startCall() {
        callingViewModel.startCall()
    }

    func endCall() {
        callingViewModel.endCall()
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AuthenticationViewModel())
            .environmentObject(CallingViewModel())
    }
}
