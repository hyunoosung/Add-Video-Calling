//
//  SheetType.swift
//  AzureCommunicationVideoCallingSample
//
//  Created by Hyounwoo Sung on 2021/02/01.
//

enum SheetType: Int, Identifiable, CaseIterable {
    case signInRequired
    case displayNotification
    case callView

    var id: Int {
        return rawValue
    }
}
