//
//  SignInView.swift
//  AzureCommunicationVideoCallingSample
//
//  Created by Hyounwoo Sung on 2021/02/01.
//

import SwiftUI
import Combine

struct SignInView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject var authenticationViewModel: AuthenticationViewModel
    @EnvironmentObject var notificationViewModel: NotificationViewModel
    @EnvironmentObject var callingViewModel: CallingViewModel


    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Sign in with email")) {
                    TextField("Email", text: $authenticationViewModel.email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .cornerRadius(5.0)

                    TextField("Password", text: $authenticationViewModel.password)
                        .textContentType(.password)
                        .autocapitalization(.none)
                        .cornerRadius(5.0)

                    Button(action: { signInWithEmail()}, label: {
                        HStack {
                            Spacer()
                            Text("Sign in with email")
                            Spacer()
                        }
                    })
                }

                Section(header: Text("Sign in with token")) {
                    HStack(alignment: .top) {
                        TextEditor(text: $authenticationViewModel.token)
                            .frame(height: 100, alignment: .leading)

                        Button(action: {
                            authenticationViewModel.token = ""
                        }, label: {
                            Image(systemName: "delete.left")
                                .foregroundColor(Color(UIColor.opaqueSeparator))
                        })
                        .padding(.top, 8)
                    }

                    Button(action: { self.signInWithTokken() }, label: {
                        HStack {
                            Spacer()
                            Text("Sign in with token")
                            Spacer()
                        }
                    })
                }

                Button(action: { self.cancel() }, label: {
                    HStack {
                        Spacer()
                        Text("Cancel")
                        Spacer()
                    }
                })
            }
            .navigationBarTitle("Sign In", displayMode: .inline)
        }
        .onReceive(callingViewModel.$hasCallAgent, perform: { hasCallAgent in
            if hasCallAgent {
                presentationMode.wrappedValue.dismiss()
            }
        })
    }

    func signInWithEmail() {
        print("Sign in with email")
        print("Sign in to your auth server and get ACS token from the api.")
        print("Initialize CommunicationTokenCredential with retrieved token from the auth server.")
    }

    func signInWithTokken() {
        print("Sign in with token")
        if let communicationUserTokenModel = authenticationViewModel.getCommunicationUserToken() {
            callingViewModel.initCallAgent(communicationUserTokenModel: communicationUserTokenModel, displayName: authenticationViewModel.displayName) { success in
                if success {
                    notificationViewModel.connectToHub()
                    print("successfully signed in.\n")
                } else {
                    print("callAgent not intialized.\n")
                }
            }
        }
    }

    func cancel() {
        print("Cancel sign in")
        self.authenticationViewModel.currentTab = .home
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
            .environmentObject(AuthenticationViewModel())
            .environmentObject(NotificationViewModel())
            .environmentObject(CallingViewModel())
    }
}
