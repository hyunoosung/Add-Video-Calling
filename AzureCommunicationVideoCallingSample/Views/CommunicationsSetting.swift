//
//  CommunicationsSetting.swift
//  AzureCommunicationVideoCallingSample
//
//  Created by Hyounwoo Sung on 2021/02/08.
//

import SwiftUI

struct CommunicationsSetting: View {
    @EnvironmentObject var authenticationViewModel: AuthenticationViewModel
    @EnvironmentObject var callingViewModel: CallingViewModel
    @State private var isExpanded: Bool = false

    var body: some View {
        Group {
            Form {
                Section(header: Text("Identifier")) {
                    Text(authenticationViewModel.identifier)
                }

                Section(header: Text("CommunicationTokenCredential")) {
                    DisclosureGroup(isExpanded: $isExpanded.animation(),
                    content: {
                        VStack(alignment: .leading) {
                            Text(authenticationViewModel.token)
                                .frame(height: 100)
                        }
                    }, label: {
                        Text("Token")
                    })
                }

                Section(header: Text("DisplayName")) {
                    HStack(alignment: .top) {
                        TextField("DisplayName", text: $authenticationViewModel.displayName)
                            .autocapitalization(.none)

                        Button(action: {
                            authenticationViewModel.displayName = ""
                        }, label: {
                            Image(systemName: "delete.left")
                                .foregroundColor(Color(UIColor.opaqueSeparator))
                        })
                    }
                }

                Button(action: { initCallAgent() }, label: {
                    HStack {
                        Spacer()
                        Text("Update display name")
                        if authenticationViewModel.isAuthenticating {
                            ProgressView()
                        }
                        Spacer()
                    }
                })

                Section {
                    Button(action: { signOut() }, label: {
                        HStack {
                            Spacer()
                            Text("SignOut")
                            if authenticationViewModel.isAuthenticating {
                                ProgressView()
                            }
                            Spacer()
                        }
                    })
                }
            }
        }
    }

    func initCallAgent() {
        print("Init CallAgent")
        if let communicationUserToken = authenticationViewModel.getCommunicationUserToken() {
            callingViewModel.initCallAgent(communicationUserTokenModel: communicationUserToken, displayName: authenticationViewModel.displayName) { (success) in
                print("callAgent initialized")
//                callingViewModel.registerVoIP()
            }
        } else {
            print("callClient not intialized")
        }
    }

    func signOut() {
        print("Signing out...")
        callingViewModel.resetCallAgent()
        authenticationViewModel.currentTab = .home
    }
}

struct CommunicationsSetting_Previews: PreviewProvider {
    static var previews: some View {
        CommunicationsSetting()
            .environmentObject(AuthenticationViewModel())
            .environmentObject(CallingViewModel())
    }
}
