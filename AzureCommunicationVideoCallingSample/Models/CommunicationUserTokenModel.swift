//
//  CommunicationUserTokenModel.swift
//  AzureCommunicationVideoCallingSample
//
//  Created by Hyounwoo Sung on 2021/02/09.
//

import Foundation

public struct CommunicationUserTokenModel: Codable {

    public var token: String?
    public var expiresOn: Date?
    public var communicationUserId: String?

    public init(token: String? = nil, expiresOn: Date? = nil, communicationUserId: String? = nil) {
        self.token = token
        self.expiresOn = expiresOn
        self.communicationUserId = communicationUserId
    }

}
