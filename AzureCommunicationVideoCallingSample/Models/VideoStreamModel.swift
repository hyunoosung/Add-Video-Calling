//
//  VideoStreamView.swift
//  AzureCommunicationVideoCallingSample
//
//  Created by Hyounwoo Sung on 2021/02/04.
//

import SwiftUI
import AzureCommunicationCalling

class VideoStreamModel: NSObject, ObservableObject {
    public var id: String?
    public var identity: CommunicationUserIdentifier?
    public var renderer: Renderer?
    @Published var displayName: String
    @Published var videoStreamView: VideoStreamView?

    public init(id: String?, identity: CommunicationUserIdentifier?, displayName: String) {
        self.id = id
        self.identity = identity
        self.displayName = displayName
    }
}
