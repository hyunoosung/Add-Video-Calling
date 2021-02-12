//
//  CallStateExtension.swift
//  AzureCommunicationVideoCallingSample
//
//  Created by Hyounwoo Sung on 2021/02/03.
//

import AzureCommunicationCalling

extension CallState {
    var name: String {
        switch self {
        case .none: return "None" // 0
        case .earlyMedia: return "EarlyMedia" // 1
        case .incoming: return "Incoming" // 2
        case .connecting: return "Connecting" // 3
        case .ringing: return "Ringing" // 4
        case .connected: return "Connected" // 5
        case .hold: return "Hold" // 6
        case .disconnecting: return "Disconnecting" // 7
        case .disconnected: return "Disconnected" // 8
        default: return "Unknown"
        }
    }
}
