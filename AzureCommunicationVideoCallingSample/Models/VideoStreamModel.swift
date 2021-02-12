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
    public var displayName: String?
    public var renderer: Renderer?
    @Published var videoStreamView: VideoStreamView?

    public init(id: String?, identity: CommunicationUserIdentifier?, displayName: String?) {
        self.id = id
        self.identity = identity
        self.displayName = displayName
    }

//    public func setVideoStreamView() {
//        do {
//            if let renderer = self.renderer {
//                self.videoStreamView = VideoStreamView(view: (try renderer.createView()))
//                print("VideoStreamView created for \(String(describing: displayName))")
//            }
//        } catch {
//            print("Failed starting VideoStreamView for \(String(describing: displayName)) : \(error.localizedDescription)")
//        }
//    }
}
