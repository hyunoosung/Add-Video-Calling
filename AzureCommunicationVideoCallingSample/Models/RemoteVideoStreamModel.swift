//
//  RemoteVideoStreamModel.swift
//  AzureCommunicationVideoCallingSample
//
//  Created by Hyounwoo Sung on 2021/02/04.
//

import SwiftUI
import AzureCommunicationCalling

class RemoteVideoStreamModel: VideoStreamModel, RemoteParticipantDelegate {
    @Published var isRemoteVideoStreamEnabled:Bool = false
    @Published var isMicrophoneMuted:Bool = false
    @Published var isSpeaking:Bool = false

    public var remoteParticipant: RemoteParticipant?

    public init(identifier: String, displayName: String, remoteParticipant: RemoteParticipant?) {
        self.remoteParticipant = remoteParticipant
        super.init(identifier: identifier, displayName: displayName)
        self.remoteParticipant!.delegate = self
        self.isMicrophoneMuted = false
        self.isSpeaking = false
    }

    func checkStream() {
        if let remoteParticipant = self.remoteParticipant,
           let videoStreams = remoteParticipant.videoStreams {
            if videoStreams.count > 0 && videoStreamView == nil {
                addStream(remoteVideoStream: videoStreams.first!)
            }
        }
    }

    private func addStream(remoteVideoStream: RemoteVideoStream) {
        do {
            let renderer = try Renderer(remoteVideoStream: remoteVideoStream)
            self.renderer = renderer
            self.videoStreamView = VideoStreamView(view: (try renderer.createView()))
            self.isRemoteVideoStreamEnabled = true
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
        self.isMicrophoneMuted = remoteParticipant.isMuted
        print("remoteParticipant.isMuted: \(remoteParticipant.isMuted)")
    }

    func onIsSpeakingChanged(_ remoteParticipant: RemoteParticipant!, args: PropertyChangedEventArgs!) {
        print("\n-------------------")
        print("onIsSpeakingChanged")
        print("-------------------\n")
        self.isSpeaking = remoteParticipant.isSpeaking
        print("remoteParticipant.isSpeaking: \(remoteParticipant.isSpeaking)")
    }

    func onDisplayNameChanged(_ remoteParticipant: RemoteParticipant!, args: PropertyChangedEventArgs!) {

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
                self.isRemoteVideoStreamEnabled = false
            }
        }
    }
}
