//
//  ProfileCategory.swift
//  AzureCommunicationVideoCallingSample
//
//  Created by Hyounwoo Sung on 2021/02/08.
//

enum ProfileCategory: Int, Identifiable, CaseIterable {
    case coummunications
    case notifications

    var id: Int {
        return rawValue
    }
}
