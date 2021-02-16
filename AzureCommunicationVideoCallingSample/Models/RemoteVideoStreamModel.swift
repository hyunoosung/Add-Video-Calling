//
//  RemoteVideoStreamModel.swift
//  AzureCommunicationVideoCallingSample
//
//  Created by Hyounwoo Sung on 2021/02/04.
//

import SwiftUI
import AzureCommunicationCalling

class RemoteVideoStreamModel: VideoStreamModel, RemoteParticipantDelegate, Identifiable {
    public var remoteParticipant: RemoteParticipant?
//    public var remoteVideoStream: RemoteVideoStream?

    public init?(id: String?, identity: CommunicationUserIdentifier?, displayName: String, remoteParticipant: RemoteParticipant?) {
        if identity != nil {
            self.remoteParticipant = remoteParticipant
            super.init(id: id, identity: identity, displayName: displayName)
            self.remoteParticipant!.delegate = self
        } else {
            return nil
        }
    }

    public func createView(remoteVideoStream: RemoteVideoStream?) {
        do {
            if let remoteVideoStream = remoteVideoStream {
                let renderer = try Renderer(remoteVideoStream: remoteVideoStream)
                self.renderer = renderer
                self.videoStreamView = VideoStreamView(view: (try renderer.createView(with: RenderingOptions(scalingMode: ScalingMode.fit))))
            }
        } catch {
            print("Failed starting VideoStreamView for \(String(describing: displayName)) : \(error.localizedDescription)")
        }
    }

    func onVideoStreamsUpdated(_ remoteParticipant: RemoteParticipant!, args: RemoteVideoStreamsEventArgs!) {
            print("\n---------------------")
            print("onVideoStreamsUpdated")
            print("---------------------\n")

            if remoteParticipant.identity is CommunicationUserIdentifier {
                let remoteParticipantIdentity = remoteParticipant.identity as! CommunicationUserIdentifier
                print("RemoteParticipant identifier:  \(String(describing: remoteParticipantIdentity.identifier))")
                print("RemoteParticipant displayName \(String(describing: remoteParticipant.displayName))")

                if let addedStreams = args.addedRemoteVideoStreams {
                    print("AddedStreams: \(addedStreams.count)")
                    addedStreams.forEach { (remoteVideoStream) in
//                        self.createView(remoteVideoStream: remoteVideoStream)
                    }
                }

                if let removedStreams = args.removedRemoteVideoStreams {
                    print("RemovedStreams: \(removedStreams.count)")
                    removedStreams.forEach { (remoteVideoStream) in
                        print("remoteVideoStream.id: \(remoteVideoStream.id)")
                        self.renderer?.dispose()
                        self.videoStreamView = nil
                    }
                }
            }
        }
}
