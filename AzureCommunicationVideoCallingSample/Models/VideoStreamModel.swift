//
//  VideoStreamView.swift
//  AzureCommunicationVideoCallingSample
//
//  Created by Hyounwoo Sung on 2021/02/04.
//

import SwiftUI
import AzureCommunicationCalling

class VideoStreamModel: NSObject, ObservableObject, Identifiable {
    public var identifier: String
    public var renderer: Renderer?
    @Published var displayName: String
    @Published var videoStreamView: VideoStreamView?

    public init(identifier: String, displayName: String) {
        self.identifier = identifier
        self.displayName = displayName
    }
}
