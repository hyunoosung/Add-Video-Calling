//
//  RemoteVideoStreamModel.swift
//  AzureCommunicationVideoCallingSample
//
//  Created by Hyounwoo Sung on 2021/02/04.
//

import SwiftUI
import AzureCommunicationCalling

class RemoteVideoStreamModel: VideoStreamModel, RemoteParticipantDelegate {
    public var remoteParticipant: RemoteParticipant?

    public init(identifier: String, displayName: String, remoteParticipant: RemoteParticipant?) {
        self.remoteParticipant = remoteParticipant
        super.init(identifier: identifier, displayName: displayName)
        self.remoteParticipant!.delegate = self

        if let streams = remoteParticipant?.videoStreams {
            if let stream = streams.first {
                self.addStream(remoteVideoStream: stream)
            }
        }
    }

    private func addStream(remoteVideoStream: RemoteVideoStream) {
        do {
            let renderer = try Renderer(remoteVideoStream: remoteVideoStream)
            self.renderer = renderer
            self.videoStreamView = VideoStreamView(view: (try renderer.createView()))
            print("Remote VideoStreamView started!")
        } catch {
            print("Failed starting VideoStreamView for \(String(describing: displayName)) : \(error.localizedDescription)")
        }
    }

    private func removeStream(stream: RemoteVideoStream?) {
        if stream != nil {
            self.renderer?.dispose()
            self.videoStreamView = nil
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
                    print("addedStreams: \(addedStreams.count)")
                    if let stream = addedStreams.first {
                        self.addStream(remoteVideoStream: stream)
                    }
                }

                if let removedStreams = args.removedRemoteVideoStreams {
                    print("RemovedStreams: \(removedStreams.count)")
                    self.removeStream(stream: removedStreams.first)
                }
            }
        }

    func onParticipantStateChanged(_ remoteParticipant: RemoteParticipant!, args: PropertyChangedEventArgs!) {
        print("\n-------------------------")
        print("onParticipantStateChanged")
        print("-------------------------\n")

        if remoteParticipant.identity is CommunicationUserIdentifier {
            let remoteParticipantIdentity = remoteParticipant.identity as! CommunicationUserIdentifier
            print("RemoteParticipant identifier:  \(String(describing: remoteParticipantIdentity.identifier))")
            print("RemoteParticipant displayName \(String(describing: remoteParticipant.displayName))")
        } else {
            print("remoteParticipant.identity: UnknownIdentifier")
        }
    }

    func onIsMutedChanged(_ remoteParticipant: RemoteParticipant!, args: PropertyChangedEventArgs!) {
        print("\n----------------")
        print("onIsMutedChanged")
        print("----------------\n")
    }

    func onIsSpeakingChanged(_ remoteParticipant: RemoteParticipant!, args: PropertyChangedEventArgs!) {

    }

    func onDisplayNameChanged(_ remoteParticipant: RemoteParticipant!, args: PropertyChangedEventArgs!) {

    }
}
