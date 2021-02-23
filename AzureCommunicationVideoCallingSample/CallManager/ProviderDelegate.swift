//
//  ProviderDelegate.swift
//  AzureCommunicationVideoCallingSample
//
//  Created by Hyounwoo Sung on 2021/02/22.
//

import SwiftUI
import CallKit
import AVFoundation

class ProviderDelegate: NSObject {
    static let shared: ProviderDelegate = ProviderDelegate()
    private(set) var provider: CXProvider?

    public func configureProvider() {
        let configuration = CXProviderConfiguration()
        configuration.maximumCallGroups = 1
        configuration.maximumCallsPerCallGroup = 1
        configuration.supportsVideo = true
        configuration.iconTemplateImageData = UIImage(systemName: "video")?.pngData()
        provider = CXProvider(configuration: configuration)
        provider?.setDelegate(self, queue: DispatchQueue.main)
    }

    deinit {
        provider?.invalidate()
    }

    // MARK: - Configure AudioSession

    func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            if audioSession.category != .playAndRecord {
                try audioSession.setCategory(AVAudioSession.Category.playAndRecord, options: [AVAudioSession.CategoryOptions.allowBluetooth, AVAudioSession.CategoryOptions.duckOthers])
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            }
            if audioSession.mode != .voiceChat {
                try audioSession.setMode(.voiceChat)
            }
        } catch {
            print("Error configuring AVAudioSession: \(error.localizedDescription)")
        }
    }

    // MARK: - Callback events

    var hasIncomingCall: ((UUID, String, Bool) -> Void)?

    var acceptCall: ((UUID) -> Void)?

    var endCall: ((UUID) -> Void)?

    var muteCall: ((UUID) -> Void)?

    // MARK: - Handle incoming call

    /// Reports a new incoming call with the specified unique identifier to the provider.
    /// - Parameters:
    ///   - callId: The unique identifier of the call.
    ///   - handle: The handle for the caller.
    ///   - hasVideo: If `true`, the call can include video.
    ///   - completion: A closure that is executed once the call is allowed or disallowed by the system.
    func reportNewIncomingCall(callId: UUID, handle: String, hasVideo: Bool = false, completion: @escaping ((Error?) -> Void)) {
        // Construct a CXCallUpdate describing the incoming call, including the caller.
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: "Incoming call from \(handle)")
        update.hasVideo = hasVideo

        // Report the incoming call to the system.
        provider?.reportNewIncomingCall(with: callId, update: update) { error in
            if let error = error {
                completion(error)
            } else {
                self.configureAudioSession()
                completion(nil)
            }
        }
    }

    // MARK: - Handle outgoing call

    /// Reports to the provider that an outgoing call with the specified unique identifier started connecting at a particular time.
    /// - Parameter callId: The unique identifier of the call.
    func startedConnectingAt(callId: UUID) {
        self.configureAudioSession()
        provider?.reportOutgoingCall(with: callId, startedConnectingAt: Date())
    }

    /// Reports to the provider that an outgoing call with the specified unique identifier finished connecting at a particular time.
    /// - Parameter callId: The unique identifier of the call.
    func connectedAt(callId: UUID) {
        provider?.reportOutgoingCall(with: callId, connectedAt: Date())
    }

    // MARK: - Handle ended calls

    /// Reports to the provider that a call with the specified identifier ended at a given date for a particular reason.
    /// - Parameter callId: The unique identifier of the call.
    func reportCallEnded(callId: UUID, reason: CXCallEndedReason) {
        provider?.reportCall(with: callId, endedAt: Date(), reason: reason)
    }
}

extension ProviderDelegate: CXProviderDelegate {

    // MARK: - Handle CallKitUI actions

    /// Called when the provider begins.
    func providerDidBegin(_: CXProvider) {
        print("providerDidBegin")
    }

    /// Called when the provider is reset.
    func providerDidReset(_: CXProvider) {
        print("providerDidReset")
    }

    /// Called when the provider performs the specified start call action.
    func provider(_: CXProvider, perform action: CXStartCallAction) {
        print("CXProvider tried to start a call from system.")
        action.fulfill()
    }

    /// Called when the provider performs the specified answer call action.
    func provider(_: CXProvider, perform action: CXAnswerCallAction) {
        acceptCall?(action.callUUID)
        action.fulfill()
    }

    /// Called when the provider performs the specified end call action.
    func provider(_: CXProvider, perform action: CXEndCallAction) {
        endCall?(action.callUUID)
        action.fulfill()
    }

    /// Called when the provider performs the specified set held call action.
    func provider(_: CXProvider, perform action: CXSetHeldCallAction) {
        action.fulfill()
    }

    /// Called when the provider performs the specified set muted call action.
    func provider(_: CXProvider, perform action: CXSetMutedCallAction) {
        muteCall?(action.callUUID)
        action.fulfill()
    }

    /// Called when the provider performs the specified set group call action.
    func provider(_ provider: CXProvider, perform action: CXSetGroupCallAction) {
        action.fulfill()
    }

    /// Called when the provider performs the specified action times out.
    func provider(_: CXProvider, timedOutPerforming _: CXAction) {}
}
