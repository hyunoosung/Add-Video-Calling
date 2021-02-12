//
//  AuthenticationViewModel.swift
//  AzureCommunicationVideoCallingSample
//
//  Created by Hyounwoo Sung on 2021/02/01.
//

import Combine
import AzureCommunicationCalling

class AuthenticationViewModel: ObservableObject {
    @Published var currentTab: Tab = .home
    @Published var isAuthenticating = false
    @Published var signInRequired = false
    @Published var error: String?

    @Published var email = ""
    @Published var password = ""
    @Published var identifier = Constants.identifier
    @Published var token = Constants.token
    @Published var displayName = Constants.displayName

    func getCommunicationUserToken() -> CommunicationUserTokenModel? {
        isAuthenticating = true
        // MARK: modify below to get token from auth server.
        if !Constants.token.isEmpty && !Constants.identifier.isEmpty {
            let communicationUserTokenModel = CommunicationUserTokenModel(token: Constants.token, expiresOn: nil, communicationUserId: Constants.identifier)
            isAuthenticating = false
            return communicationUserTokenModel
        }

        isAuthenticating = false
        return nil
    }

    func signInToCommunicationServices(withToken token: String) -> CommunicationTokenCredential? {
        do {
            isAuthenticating = true
            let communicationTokenCredential = try CommunicationTokenCredential(token: token)
            isAuthenticating = false

            return communicationTokenCredential
        } catch {
            print("Error: \(error.localizedDescription)")
            self.error = error.localizedDescription
            self.isAuthenticating = false
            return nil
        }
    }
}
