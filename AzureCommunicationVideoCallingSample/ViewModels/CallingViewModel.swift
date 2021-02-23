//
//  ACSViewModel.swift
//  AzureCommunicationVideoCallingSample
//
//  Created by Hyounwoo Sung on 2021/02/01.
//

import Combine
import PushKit
import CallKit
import AVFoundation
import AzureCommunicationCalling

class CallingViewModel: NSObject, ObservableObject {
    static let shared: CallingViewModel = CallingViewModel()
    private var callClient: CallClient = CallClient()
    private var callAgent: CallAgent?
    private var call: Call?
    private var deviceManager: DeviceManager?
    private var localVideoStream: LocalVideoStream?
    private var voipToken: Data?

    @Published var hasCallAgent: Bool = false
    @Published var callState: CallState = CallState.none
    @Published var localVideoStreamModel: LocalVideoStreamModel?
    @Published var remoteVideoStreamModels: [RemoteVideoStreamModel] = []
    @Published var isLocalVideoStreamEnabled:Bool = false
    @Published var isMicrophoneMuted:Bool = false
    @Published var incomingCallPushNotification: IncomingCallPushNotification?
    @Published var callee: String = Constants.callee
    @Published var groupId: String = "29228d3e-040e-4656-a70e-890ab4e173e5"

    override init() {
        super.init()
        ProviderDelegate.shared.acceptCall = { callId in
            print("callId: \(callId)")
        }
    }

    // MARK: - Initialize CallingViewModel.

    var hasIncomingCall: ((Bool) -> Void)?

    func setVoipToken(token: Data?) {
        if let token = token {
            voipToken = token
        }
    }

    func initCallAgent(communicationUserTokenModel: CommunicationUserTokenModel, displayName: String?, completion: @escaping (Bool) -> Void) {
        if let communicationUserId = communicationUserTokenModel.communicationUserId,
           let token = communicationUserTokenModel.token {
            do {
                let communicationTokenCredential = try CommunicationTokenCredential(token: token)
                let callAgentOptions = CallAgentOptions()
                callAgentOptions?.displayName = displayName ?? communicationUserId
                self.callClient.createCallAgent(userCredential: communicationTokenCredential, options: callAgentOptions) { (callAgent, error) in
                    print("CallAgent successfully created.\n")
                    if self.callAgent != nil {
                        print("\nsomething went wrhong with lifecycle.\n")
                        self.callAgent?.delegate = nil
                    }
                    self.callAgent = callAgent
                    self.callAgent?.delegate = self
                    self.hasCallAgent = true
                    
                    if let token = self.voipToken {
                        self.registerPushNotifications(voipToken: token)
                    }

                    ProviderDelegate.shared.acceptCall = { callId in
                        self.acceptCall(callId: callId)
                    }

                    ProviderDelegate.shared.endCall = { callId in
                        self.endCall(callId: callId)
                    }

                    ProviderDelegate.shared.muteCall = { callId in
                        self.muteCall(callId: callId)
                    }
                    completion(true)
                }
            } catch {
                print("Error: \(error.localizedDescription)")
                completion(false)
            }
        } else {
            print("Invalid communicationUserTokenModel.\n")
        }
    }

    func registerPushNotifications(voipToken: Data) {
        self.callAgent?.registerPushNotifications(deviceToken: voipToken, completionHandler: { (error) in
            if(error == nil) {
                print("Successfully registered to VoIP push notification.\n")
            } else {
                print("Failed to register VoIP push notification.\(String(describing: error))\n")
            }
        })
    }

    func unRegisterPushNotifications() {
        self.callAgent?.unRegisterPushNotifications(completionHandler: { (error) in
            if (error != nil) {
                print("Register of push notification failed, please try again.\n")
            } else {
                print("Unregister of push notification was successful.\n")
            }
        })
    }

    func handlePushNotification(incomingCallPushNotification: IncomingCallPushNotification) {
        if let callAgent = self.callAgent {
            print("CallAgent found.\n")
            callAgent.handlePush(notification: incomingCallPushNotification, completionHandler: { error in
                if let error = error {
                    print("Handle push notification failed: \(error.localizedDescription)\n")
                } else {
                    print("Handle push notification succeeded.\n")
                }
            })
        } else {
            print("CallAgent not found.\nConnecting to Communication Services...\n")
            let token = Constants.token
            let identifier = Constants.identifier
            let displayName = Constants.displayName

            if !token.isEmpty && !identifier.isEmpty {
                let communicationUserToken = CommunicationUserTokenModel(token: token, expiresOn: nil, communicationUserId: identifier)
                self.initCallAgent(communicationUserTokenModel: communicationUserToken, displayName: displayName) { (success) in
                    if success {
                        self.callAgent?.handlePush(notification: incomingCallPushNotification, completionHandler: { error in
                            if let error = error {
                                print("Handle push notification failed: \(error.localizedDescription)\n")
                            } else {
                                print("Handle push notification succeeded.\n")
                            }
                        })
                    } else {
                        print("initCallAgent failed.\n")
                    }
                }
            } else {
                // MARK: no token found, unregister push notification when signing out.
                print("No token found,\n")
            }

        }
    }

    func resetCallAgent() {
        if let callAgent = self.callAgent {
            unRegisterPushNotifications()
            callAgent.delegate = nil
            self.callAgent = nil
        } else {
            print("callAgent not found.\n")
        }
        self.hasCallAgent = false
    }

    // MARK: - Device management.

    func requestRecordPermission(completion: @escaping (Bool) -> Void) {
        let audioSession = AVAudioSession.sharedInstance()
        switch audioSession.recordPermission {
        case .undetermined:
            audioSession.requestRecordPermission { granted in
                if granted {
                    completion(true)
                } else {
                    print("User did not grant audio permission")
                    completion(false)
                }
            }
        case .denied:
            print("User did not grant audio permission, it should redirect to Settings")
            completion(false)
        case .granted:
            completion(true)
        @unknown default:
            print("Audio session record permission unknown case detected")
            completion(false)
        }
    }

    func requestVideoPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { authorized in
                if authorized {
                    completion(true)
                } else {
                    print("User did not grant video permission")
                    completion(false)
                }
            }
        case .restricted, .denied:
            print("User did not grant video permission, it should redirect to Settings")
            completion(false)
        case .authorized:
            completion(true)
        @unknown default:
            print("AVCaptureDevice authorizationStatus unknown case detected")
            completion(false)
        }
    }

    func getDeviceManager(completion: @escaping (Bool) -> Void) {
        requestVideoPermission { success in
            if success {
                self.callClient.getDeviceManager(completionHandler: { (deviceManager, error) in
                    if (error == nil) {
                        print("Got device manager instance")
                        self.deviceManager = deviceManager

                        if let videoDeviceInfo: VideoDeviceInfo = deviceManager?.getCameraList()?.first {
                            self.localVideoStream = LocalVideoStream(camera: videoDeviceInfo)
                            self.localVideoStreamModel = LocalVideoStreamModel(identifier: Constants.identifier, displayName: Constants.displayName)
                            print("LocalVideoStream instance initialized.")
                            completion(true)
                        } else {
                            print("LocalVideoStream instance initialize faile.")
                            completion(false)
                        }
                    } else {
                        print("Failed to get device manager instance: \(String(describing: error))")
                        completion(false)
                    }
                })
            } else {
                print("Permission denied.\n")
                completion(false)
            }
        }
    }

    func toggleCamera() {
        if let camera = self.deviceManager?.getCameraList(),
           let localVideoStreamSource = self.localVideoStream?.source {
            if camera.count > 1 {
                if localVideoStreamSource.cameraFacing == .front {
                    print("front")
                    self.stopVideo() { success in
                        if success {
                            // set second camera
                            self.localVideoStream = LocalVideoStream(camera: camera[1])
                            self.startVideo(call: self.call!, localVideoStream: self.localVideoStream!)
                        } else {
                            print("Something wrong.\n")
                        }
                    }

                } else {
                    print("back")
                    self.stopVideo() { success in
                        if success {
                            // set back to first camera
                            self.localVideoStream = LocalVideoStream(camera: camera[0])
                            self.startVideo(call: self.call!, localVideoStream: self.localVideoStream!)
                        } else {
                            print("Something wrong.\n")
                        }
                    }
                }
            } else {
                print("Device has only one camera.")
            }
        }
    }

    // MARK: - Call management.

    func getCurrentCallUUID() -> UUID? {
        if let call = self.call,
           let callId = UUID(uuidString: call.callId) {
            return callId
        } else {
            return nil
        }
    }

    func getCall(callId: UUID) -> Call? {
        if let call = self.call {
            if (call.callId == callId.uuidString.lowercased()) {
                return call
            } else {
                return nil
            }
        } else {
            return nil
        }
    }

    func joinGroup() {
        requestRecordPermission { success in
            guard success else {
                print("recordPermission not authorized.")
                return
            }

            if let callAgent = self.callAgent {
                let groupId = UUID(uuidString: self.groupId)!
                let groupCallLocator = GroupCallLocator(groupId: groupId)
                let joinCallOptions = JoinCallOptions()

                self.getDeviceManager { _ in
                    if let localVideoStream = self.localVideoStream {
                        let videoOptions = VideoOptions(localVideoStream: localVideoStream)
                        joinCallOptions?.videoOptions = videoOptions

                        self.call = callAgent.join(with: groupCallLocator, joinCallOptions: joinCallOptions)
                        self.call?.delegate = self
                        self.startVideo(call: self.call!, localVideoStream: localVideoStream)

                        CallController.shared.startCall(callId: groupId, handle: self.groupId, isVideo: true) { error in
                            if let error = error {
                                print("Outgoing call failed: \(error.localizedDescription)")
                            } else {
                                print("outgoing call started.")
                            }
                        }
                    } else {
                        self.call = callAgent.join(with: groupCallLocator, joinCallOptions: joinCallOptions)
                        self.call?.delegate = self

                        CallController.shared.startCall(callId: groupId, handle: self.groupId, isVideo: false) { error in
                            if let error = error {
                                print("Outgoing call failed: \(error.localizedDescription)")
                            } else {
                                print("outgoing call started.")
                            }
                        }
                    }
                }
            } else {
                print("callAgent not initialized.\n")
            }
        }
    }

    func startCall() {
        requestRecordPermission { success in
            guard success else {
                print("recordPermission not authorized.")
                return
            }

            if let callAgent = self.callAgent {
                let callees:[CommunicationUserIdentifier] = [CommunicationUserIdentifier(identifier: self.callee)]
                let startCallOptions = StartCallOptions()

                self.getDeviceManager { _ in
                    if let localVideoStream = self.localVideoStream {
                        let videoOptions = VideoOptions(localVideoStream: localVideoStream)
                        startCallOptions?.videoOptions = videoOptions

                        self.call = callAgent.call(participants: callees, options: startCallOptions)
                        self.call?.delegate = self
                        self.startVideo(call: self.call!, localVideoStream: localVideoStream)
                        let callId = UUID(uuidString: (self.call?.callId)!)
                        CallController.shared.startCall(callId: callId!, handle: Constants.displayName, isVideo: true) { error in
                            if let error = error {
                                print("Outgoing call failed: \(error.localizedDescription)")
                            } else {
                                print("outgoing call started.")
                            }
                        }
                    } else {
                        self.call = callAgent.call(participants: callees, options: startCallOptions)
                        self.call?.delegate = self
                        let callId = UUID(uuidString: (self.call?.callId)!)
                        CallController.shared.startCall(callId: callId!, handle: Constants.displayName, isVideo: true) { error in
                            if let error = error {
                                print("Outgoing call failed: \(error.localizedDescription)")
                            } else {
                                print("outgoing call started.")
                            }
                        }
                        print("outgoing call started.")
                    }
                }
            } else {
                print("callAgent not initialized.\n")
            }
        }
    }

    func endCall() {
        if let callUUID = getCurrentCallUUID() {
            CallController.shared.endCall(callId: callUUID) { error in
                if let error = error {
                    print("EndCall request failed: \(error.localizedDescription)\n")
                } else {
                    print("EndCall request succeeded.\n")
                }
            }
        }
    }

    func startVideo(call: Call, localVideoStream: LocalVideoStream) -> Void {
        requestVideoPermission { success in
            if success {
                if let localVideoStreamModel = self.localVideoStreamModel {
                    call.startVideo(stream: localVideoStream) { error in
                        if error != nil {
                            print("LocalVideo failed to start.\n")
                        } else {
                            print("LocalVideo started successfully.\n")
                            localVideoStreamModel.createView(localVideoStream: localVideoStream)
                            self.isLocalVideoStreamEnabled = true
                        }
                    }
                }
            } else {
                print("Permission denied.\n")
            }
        }
    }

    func stopVideo(completion: @escaping (Bool) -> Void) {
        if let call = self.call {
            call.stopVideo(stream: self.localVideoStream) { error in
                if let error = error {
                    print("LocalVideo failed to stop: \(error.localizedDescription)\n")
                    completion(false)
                } else {
                    print("LocalVideo stopped successfully.\n")
                    if let localVideoStreamModel = self.localVideoStreamModel {
                        self.isLocalVideoStreamEnabled = false
                        localVideoStreamModel.renderer?.dispose()
                        localVideoStreamModel.renderer = nil
                        localVideoStreamModel.videoStreamView = nil
                    }
                    completion(true)
                }
            }
        }
    }

    func toggleVideo() {
        if let call = self.call,
           let localVideoStream = self.localVideoStream {
            if isLocalVideoStreamEnabled {
                stopVideo() { _ in }
            } else {
                startVideo(call: call, localVideoStream: localVideoStream)
            }
        }
    }

    func setMutedCall() {
        if let callUUID = getCurrentCallUUID() {
            CallController.shared.setMutedCall(callId: callUUID, muted: !isMicrophoneMuted) { error in
                if let error = error {
                    print("Failed to setMutedCall: \(error.localizedDescription)\n")
                } else {
                    print("setMutedCall \(!self.isMicrophoneMuted) successfully.\n")
                }
            }
        }
    }

    // MARK: - Callback methods.

    private func acceptCall(callId: UUID) {
        print("AcceptCall requested from CallKit.\n")
        if let _ = self.callAgent,
           let call = self.getCall(callId: callId) {
            self.requestRecordPermission { authorized in
                if authorized {
                    let acceptCallOptions = AcceptCallOptions()
                    self.getDeviceManager { _ in
                        if let localVideoStream = self.localVideoStream {
                            let videoOptions = VideoOptions(localVideoStream: localVideoStream)
                            acceptCallOptions?.videoOptions = videoOptions
                            self.startVideo(call: call, localVideoStream: localVideoStream)
                        }

                        call.accept(options: acceptCallOptions) { error in
                            if let error = error {
                                print("Failed to accpet incoming call: \(error.localizedDescription)\n")
                            } else {
                                print("Incoming call accepted with acceptCallOptions.\n")
                            }
                        }
                    }
                } else {
                    print("recordPermission not authorized.")
                }
            }
        } else {
            print("Call not found when trying to accept.\n")
            self.hasIncomingCall = { hasIncomingCall in
                if hasIncomingCall == true {
                    self.acceptCall(callId: callId)
                    self.hasIncomingCall?(false)
                }
            }
        }
    }

    private func endCall(callId: UUID) {
        print("EndCall requested from CallKit.\n")
        if let call = self.getCall(callId: callId) {
            call.hangup(options: HangupOptions()) { error in
                if let error = error {
                    print("Hangup failed: \(error.localizedDescription).\n")
                } else {
                    print("Hangup succeeded.\n")
                }
            }
        } else {
            print("Call not found when trying to hangup.\n")
        }
    }

    private func muteCall(callId: UUID) {
        print("MuteCall requested from CallKit.\n")
        if let call = self.getCall(callId: callId) {
            if call.isMicrophoneMuted {
                call.unmute(completionHandler:{ (error) in
                    if let error = error {
                        print("Failed to unmute: \(error.localizedDescription)")
                    } else {
                        print("Successfully un-muted")
                        self.isMicrophoneMuted = false
                    }
                })
            } else {
                call.mute(completionHandler: { (error) in
                    if let error = error {
                        print("Failed to mute: \(error.localizedDescription)")
                    } else {
                        print("Successfully muted")
                        self.isMicrophoneMuted = true
                    }
                })
            }
        } else {
            print("Call not found when trying to set mute.\n")
        }
    }
}

// MARK: - InternalTokenProviderDelegate
extension CallingViewModel: InternalTokenProviderDelegate {
    func onTokenRequested(_ internalTokenProvider: InternalTokenProvider!, sender: InternalTokenProvider!) {
        print("\n----------------")
        print("onTokenRequested")
        print("----------------\n")
    }
}

// MARK: - CallAgentDelegate
extension CallingViewModel: CallAgentDelegate {
    func onCallsUpdated(_ callAgent: CallAgent!, args: CallsUpdatedEventArgs!) {
        print("\n---------------")
        print("onCallsUpdated")
        print("---------------\n")

        if let addedCall = args.addedCalls?.first(where: {$0.isIncoming }) {
            print("addedCalls: \(args.addedCalls.count)")
            self.call = addedCall
            self.call?.delegate = self
            self.callState = addedCall.state
            self.isMicrophoneMuted = addedCall.isMicrophoneMuted
            self.hasIncomingCall?(true)
        }

        if let removedCalls = args.removedCalls {
            print("removedCalls: \(args.removedCalls.count)\n")
            if let call = self.call,
               let removedCall = removedCalls.first(where: {$0.callId == call.callId}),
               let removedCallUUID = UUID(uuidString: removedCall.callId) {
                self.callState = removedCall.state
                self.call?.delegate = nil
                self.call = nil

                ProviderDelegate.shared.reportCallEnded(callId: removedCallUUID, reason: CXCallEndedReason.remoteEnded)
            } else {
                print("removedCall: \(String(describing: args.removedCalls))")
                if let incomingCallPushNotification = self.incomingCallPushNotification {
                    ProviderDelegate.shared.reportCallEnded(callId: incomingCallPushNotification.callId, reason: CXCallEndedReason.remoteEnded)
                }
            }
        }
    }
}

// MARK: - CallDelegate
extension CallingViewModel: CallDelegate {
    func onCallStateChanged(_ call: Call!, args: PropertyChangedEventArgs!) {
        print("\n----------------------------------")
        print("onCallStateChanged: \(String(reflecting: call.state.name))")
        print("----------------------------------\n")
        self.callState = call.state

        if call.state == .connected && !call.isIncoming {
            if let callUUID = UUID(uuidString: call.callId) {
                ProviderDelegate.shared.startedConnectingAt(callId: callUUID)
            }
        }
        if call.state == .connected && !call.isIncoming {
            if let callUUID = UUID(uuidString: call.callId) {
                ProviderDelegate.shared.connectedAt(callId: callUUID)
            }
        }

        if call.state == .disconnected || call.state == .none {
            self.stopVideo() { _ in }
            self.remoteVideoStreamModels.forEach({ (remoteVideoStreamModel) in
                remoteVideoStreamModel.renderer?.dispose()
                remoteVideoStreamModel.videoStreamView = nil
                remoteVideoStreamModel.remoteParticipant?.delegate = nil
            })
            self.remoteVideoStreamModels = []
        }
    }

    func onRemoteParticipantsUpdated(_ call: Call!, args: ParticipantsUpdatedEventArgs!) {
        print("\n---------------------------")
        print("onRemoteParticipantsUpdated")
        print("---------------------------\n")

        if let addedParticipants = args.addedParticipants {
            if addedParticipants.count > 0 {
                print("addedParticipants: \(String(describing: args.addedParticipants.count))")

                addedParticipants.forEach { (remoteParticipant) in
                    if remoteParticipant.identity is CommunicationUserIdentifier {
                        let communicationUserIdentifier = remoteParticipant.identity as! CommunicationUserIdentifier
                        print("addedParticipant identifier:  \(String(describing: communicationUserIdentifier))")
                        print("addedParticipant displayName \(String(describing: remoteParticipant.displayName))")
                        print("addedParticipant streams \(String(describing: remoteParticipant.videoStreams.count))")

                        let remoteVideoStreamModel = RemoteVideoStreamModel(identifier: communicationUserIdentifier.identifier, displayName: remoteParticipant.displayName, remoteParticipant: remoteParticipant)
                        remoteVideoStreamModels.append(remoteVideoStreamModel)
                    }
                }
            }
        }

        if let removedParticipants = args.removedParticipants {
            if removedParticipants.count > 0 {
                print("removedParticipants: \(String(describing: args.removedParticipants.count))")

                removedParticipants.forEach { (remoteParticipant) in
                    if remoteParticipant.identity is CommunicationUserIdentifier {
                        let communicationUserIdentifier = remoteParticipant.identity as! CommunicationUserIdentifier
                        print("removedParticipant identifier:  \(String(describing: communicationUserIdentifier))")
                        print("removedParticipant displayName \(String(describing: remoteParticipant.displayName))")

                        if let removedIndex = remoteVideoStreamModels.firstIndex(where: {$0.identifier == communicationUserIdentifier.identifier}) {
                            let remoteVideoStreamModel = remoteVideoStreamModels[removedIndex]
                            remoteVideoStreamModel.remoteParticipant?.delegate = nil
                            remoteVideoStreamModel.renderer?.dispose()
                            remoteVideoStreamModel.videoStreamView = nil
                            remoteVideoStreamModels.remove(at: removedIndex)
                        }
                    }
                }
            }
        }
    }

    func onLocalVideoStreamsChanged(_ call: Call!, args: LocalVideoStreamsUpdatedEventArgs!) {
        print("\n--------------------------")
        print("onLocalVideoStreamsChanged")
        print("--------------------------\n")

        if let addedStreams = args.addedStreams {
            print("addedStreams: \(addedStreams.count)")
        }

        if let removedStreams = args.removedStreams {
            print("removedStreams: \(removedStreams.count)")
        }
    }
}

// MARK: - DeviceManagerDelegate
extension CallingViewModel: DeviceManagerDelegate {
    func onAudioDevicesUpdated(_ deviceManager: DeviceManager!, args: AudioDevicesUpdatedEventArgs!) {
        print("\n---------------------")
        print("onAudioDevicesUpdated")
        print("-------------------\n")
    }

    func onVideoDevicesUpdated(_ deviceManager: DeviceManager!, args: VideoDevicesUpdatedEventArgs!) {
        print("\n---------------------")
        print("onVideoDevicesUpdated")
        print("---------------------")
    }
}
