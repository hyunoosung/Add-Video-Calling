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
    private static var sharedInstance: CallingViewModel?
    private(set) var callClient: CallClient?
    private(set) var callAgent: CallAgent?
    private(set) var call: Call?
    private(set) var deviceManager: DeviceManager?
    private(set) var localVideoStream: LocalVideoStream?
    private var pushRegistry: PKPushRegistry
    private var voIPToken: Data?

    @Published var hasCallAgent: Bool = false
    @Published var callState: CallState = CallState.none
    @Published var localVideoStreamModel: LocalVideoStreamModel?
    @Published var remoteVideoStreamModels: [RemoteVideoStreamModel] = []

    @Published var incomingCallPushNotification: IncomingCallPushNotification?
    @Published var callee: String = Constants.callee
    @Published var groupId: String = "29228d3e-040e-4656-a70e-890ab4e173e5"

    static func shared() -> CallingViewModel {
        if sharedInstance == nil {
            sharedInstance = CallingViewModel()

            // This is to initialize CallKit properly before requesting first outgoing/incoming call
            _ = CallKitManager.shared()
        }
        return sharedInstance!
    }

    override init() {
        callClient = CallClient()
        pushRegistry = PKPushRegistry(queue: DispatchQueue.main)
        super.init()
        pushRegistry.delegate = self
        pushRegistry.desiredPushTypes = [PKPushType.voIP]
    }

    func initCallAgent(communicationUserTokenModel: CommunicationUserTokenModel, displayName: String?, completion: @escaping (Bool) -> Void) {
        if let communicationUserId = communicationUserTokenModel.communicationUserId,
           let token = communicationUserTokenModel.token {
            do {
                let communicationTokenCredential = try CommunicationTokenCredential(token: token)
                let callAgentOptions = CallAgentOptions()
                callAgentOptions?.displayName = displayName ?? communicationUserId
                self.callClient?.createCallAgent(userCredential: communicationTokenCredential, options: callAgentOptions) { (callAgent, error) in
                    if self.callAgent != nil {
                        self.callAgent?.delegate = nil
                    }
                    self.callAgent = callAgent
                    self.callAgent?.delegate = self
                    self.hasCallAgent = true

                    print("CallAgent successfully created.\n")
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

    func initPushNotification() {
        self.callAgent?.registerPushNotifications(deviceToken: self.voIPToken, completionHandler: { (error) in
            if(error == nil) {
                print("Successfully registered to VoIP push notification.\n")
            } else {
                print("Failed to register VoIP push notification.\(String(describing: error))\n")
            }
        })
    }

    func getCall(callId: UUID) -> Call? {
        if let call = self.call {
            print("incoming callId: \(call.callId.uppercased())")
            print("push callId: \(callId)")

            if let currentCallId = UUID(uuidString: call.callId) {
                if currentCallId == callId {
                    return call
                } else {
                    return nil
                }
            } else {
                print("Error parsing callId from currentCall.\n")
            }
        } else {
            print("call not exist in CallingViewModel!!!.\n")
        }
        return nil
    }

    func resetCallAgent() {
        if let callAgent = self.callAgent {
            unRegisterVoIP()
            callAgent.delegate = nil
            self.callAgent = nil
        } else {
            print("callAgent not found.\n")
        }
        self.hasCallAgent = false
    }

    func getDeviceManager(completion: @escaping (Bool) -> Void) {
        requestVideoPermission { success in
            if success {
                self.callClient?.getDeviceManager(completionHandler: { (deviceManager, error) in
                    if (error == nil) {
                        print("Got device manager instance")
                        self.deviceManager = deviceManager

                        if let videoDeviceInfo: VideoDeviceInfo = deviceManager?.getCameraList()?.first {
                            self.localVideoStream = LocalVideoStream(camera: videoDeviceInfo)
                            self.localVideoStreamModel = LocalVideoStreamModel(id: Constants.identifier, identity: nil, displayName: Constants.displayName)
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

    // MARK: Request RecordPermission
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

    // MARK: Request VideoPermission
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

    // MARK: Configure AudioSession
    func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            if audioSession.category != .playAndRecord {
                try audioSession.setCategory(AVAudioSession.Category.playAndRecord,
                                             options: AVAudioSession.CategoryOptions.allowBluetooth)
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            }
            if audioSession.mode != .voiceChat {
                try audioSession.setMode(.voiceChat)
            }
        } catch {
            print("Error configuring AVAudioSession: \(error.localizedDescription)")
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
                        }
                    }
                }
            } else {
                print("Permission denied.\n")
            }
        }
    }

    func stopVideo(competion: @escaping (Bool) -> Void) {
        if let call = self.call {
            call.stopVideo(stream: self.localVideoStream) { error in
                if error != nil {
                    print("LocalVideo failed to stop.\n")
                    competion(false)
                } else {
                    print("LocalVideo stopped successfully.\n")
                    competion(true)
                }
            }
        }
    }

    func stopVideo() {
        self.stopVideo { success in
            if success {
                self.localVideoStreamModel?.renderer?.dispose()
                self.localVideoStreamModel?.renderer = nil
                self.localVideoStreamModel?.videoStreamView = nil
            }
        }
    }

    func joinGroup() {
        requestRecordPermission { success in
            guard success else {
                print("recordPermission not authorized.")
                return
            }

            if let callAgent = self.callAgent {
                let groupCallLocator = GroupCallLocator(groupId: UUID(uuidString: self.groupId))
                let joinCallOptions = JoinCallOptions()

                self.getDeviceManager { _ in
                    if let localVideoStream = self.localVideoStream {
                        let videoOptions = VideoOptions(localVideoStream: localVideoStream)
                        
                        joinCallOptions?.videoOptions = videoOptions

                        self.call = callAgent.join(with: groupCallLocator, joinCallOptions: joinCallOptions)

                        self.call?.delegate = self
                        self.startVideo(call: self.call!, localVideoStream: localVideoStream)
                        CallKitManager.shared().startOutgoingCall(call: self.call!, callerDisplayName: Constants.displayName)
                        print("outgoing call started.")
                    } else {
                        self.call = self.callAgent?.join(with: groupCallLocator, joinCallOptions: joinCallOptions)
                        CallKitManager.shared().startOutgoingCall(call: self.call!, callerDisplayName: Constants.displayName)
                        self.call?.delegate = self
                        print("outgoing call started.")
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
                        CallKitManager.shared().startOutgoingCall(call: self.call!, callerDisplayName: Constants.displayName)
                        print("outgoing call started.")
                    } else {
                        self.call = callAgent.call(participants: callees, options: startCallOptions)
                        CallKitManager.shared().startOutgoingCall(call: self.call!, callerDisplayName: Constants.displayName)
                        self.call?.delegate = self
                        print("outgoing call started.")
                    }
                }
            } else {
                print("callAgent not initialized.\n")
            }
        }
    }

    // Accept incoming call
    func acceptCall(callId: UUID, completion: @escaping (Bool) -> Void) {
        if self.incomingCallPushNotification == nil {
            self.requestRecordPermission { authorized in
                if authorized {
                    if let call = self.getCall(callId: callId) {
                        let acceptCallOptions = AcceptCallOptions()

                        self.getDeviceManager { _ in
                            if let localVideoStream = self.localVideoStream {
                                let videoOptions = VideoOptions(localVideoStream: localVideoStream)
                                acceptCallOptions?.videoOptions = videoOptions
                                // MARK: startVideo when connection has made
                                self.startVideo(call: call, localVideoStream: localVideoStream)
                            }

                            call.accept(options: acceptCallOptions) { error in
                                if let error = error {
                                    print("Failed to accpet incoming call: \(error.localizedDescription)\n")
                                    completion(false)
                                } else {
                                    print("Incoming call accepted with acceptCallOptions.\n")
                                    completion(true)
                                }
                            }
                        }
                    } else {
                        print("Call not found when trying to accept.\n")
                        completion(false)
                    }
                } else {
                    print("recordPermission not authorized.")
                }
            }
        } else {
            print("incomingCallPushNotification not processed yet")
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                self.incomingCallPushNotification = nil
                self.acceptCall(callId: callId) { _ in }
            }
        }
    }

    func endCall() -> Void {
        print("endCall requested from App.\n")
        if let call = self.call {
            call.hangup(options: HangupOptions()) { error in
                if let error = error {
                    print("hangup failed: \(error.localizedDescription).\n")
                } else {
                    print("hangup succeed.\n")
                }
            }
        } else {
            print("Call not found.\n")
        }
    }

    func endCall(callId: UUID, completion: @escaping (Bool) -> Void) {
        print("endCall requested from CallKit.\n")
        if let call = self.getCall(callId: callId) {
            call.hangup(options: HangupOptions()) { error in
                if let error = error {
                    print("hangup failed: \(error.localizedDescription).\n")
                    completion(false)
                } else {
                    print("hangup succeed.\n")
                    completion(true)
                }
            }
        } else {
            print("Call not found when trying to hangup.\n")
            completion(false)
        }
    }

    func mute() {
        if let call = self.call {
            if call.isMicrophoneMuted {
                call.unmute(completionHandler:{ (error) in
                    if error == nil {
                        print("Successfully un-muted")
                    } else {
                        print("Failed to unmute")
                    }
                })
            } else {
                call.mute(completionHandler: { (error) in
                    if error == nil {
                        print("Successfully muted")
                    } else {
                        print("Failed to mute")
                    }
                })
            }
        }
    }
}

extension CallingViewModel: PKPushRegistryDelegate {
    func unRegisterVoIP() {
        self.callAgent?.unRegisterPushNotifications(completionHandler: { (error) in
            if (error != nil) {
                print("Register of push notification failed, please try again.\n")
            } else {
                print("Unregister of push notification was successful.\n")
            }
        })
    }

    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        let deviceToken = pushCredentials.token.map { String(format: "%02x", $0) }.joined()
                print("pushRegistry -> deviceToken :\(deviceToken)")

        self.voIPToken = pushCredentials.token
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        print("pusRegistry invalidated.")
    }

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        let dictionaryPayload = payload.dictionaryPayload
        print("dictionaryPayload: \(dictionaryPayload)")

//        let update = CXCallUpdate()
//        update.remoteHandle = CXHandle(type: .emailAddress, value: "test@email.com")

//        CallKitManager.shared().testReport { success in
//            completion()
//        }


        if type == .voIP {
            if let incomingCallPushNotification = IncomingCallPushNotification.fromDictionary(payload.dictionaryPayload) {
                self.configureAudioSession()
                CallKitManager.shared().reportNewIncomingCall(incomingCallPushNotification: incomingCallPushNotification) { success in
                    if success {
                        print("Handling of report incoming call was succesful.\n")
                        completion()
                    } else {
                        print("Handling of report incoming call failed.\n")
                        completion()
                    }
                }

                if self.callAgent == nil {
                    self.incomingCallPushNotification = incomingCallPushNotification

                    print("CallAgent not found.\nConnecting to Communication Services...\n")
                    // MARK: generate communicationUserToken from stored data.
                    let token = Constants.token
                    let identifier = Constants.identifier
                    let displayName = Constants.displayName

                    if !token.isEmpty && !identifier.isEmpty {
                        let communicationUserToken = CommunicationUserTokenModel(token: token, expiresOn: nil, communicationUserId: identifier)
                        self.initCallAgent(communicationUserTokenModel: communicationUserToken, displayName: displayName) { (success) in
                            if success {
                                self.initPushNotification()

                                self.callAgent?.handlePush(notification: incomingCallPushNotification, completionHandler: { error in
                                    if (error != nil) {
                                        print("Handling of push notification to call failed: \(error.debugDescription)\n")
                                    } else {
                                        print("Handling of push notification to call was successful.\n")
                                        self.incomingCallPushNotification = nil
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
        } else {
            print("Pushnotification is not type of voIP.\n")
        }
    }
}

extension CallingViewModel: InternalTokenProviderDelegate {
    func onTokenRequested(_ internalTokenProvider: InternalTokenProvider!, sender: InternalTokenProvider!) {
        print("\n----------------")
        print("onTokenRequested")
        print("----------------\n")
    }
}

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
        }

        if let removedCall = args.removedCalls?.first {
            print("removedCalls: \(args.removedCalls.count)\n")
            let removedCallUUID = UUID(uuidString: removedCall.callId)
            // MARK: report CallKitManager for endCall.
            CallKitManager.shared().reportCallEndedFromRemote(callId: removedCallUUID!, reason: CXCallEndedReason.remoteEnded)

            if let call = self.call {
                print("call removed.\n")
                if call.callId == removedCall.callId {
                    self.callState = removedCall.state
                    self.call?.delegate = nil
                    self.call = nil
                }
            } else {
                print("\ncall removed before initizliaztion.\n")
            }
        } else {
            print("removedCall: \(String(describing: args.removedCalls))")
            if let incomingCallPushNotification = self.incomingCallPushNotification {
                CallKitManager.shared().reportCallEndedFromRemote(callId: incomingCallPushNotification.callId, reason: CXCallEndedReason.remoteEnded)
            }
        }
    }
}

extension CallingViewModel: CallDelegate {
    func onCallStateChanged(_ call: Call!, args: PropertyChangedEventArgs!) {
        print("\n----------------------------------")
        print("onCallStateChanged: \(String(reflecting: call.state.name))")
        print("----------------------------------\n")
        self.callState = call.state

        if call.state == .connected {
//            if let localVideoStream = self.localVideoStream {
//                self.startVideo(call: call, localVideoStream: localVideoStream)
//            }
        }

        if call.state == .disconnected || call.state == .none {
            self.stopVideo()
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

        var callerIdentifier: String?

        if call.callerId is CommunicationUserIdentifier {
            let callerUserIdentifier = call.callerId as! CommunicationUserIdentifier
            callerIdentifier = callerUserIdentifier.identifier
            print("Caller identifier:  \(String(describing: callerIdentifier))")
        }

        if let addedParticipants = args.addedParticipants {
            if addedParticipants.count > 0 {
                print("addedParticipants: \(String(describing: args.addedParticipants.count))")

                addedParticipants.forEach { (remoteParticipant) in
                    if remoteParticipant.identity is CommunicationUserIdentifier {
                        let remoteParticipantIdentity = remoteParticipant.identity as! CommunicationUserIdentifier
                        let remoteParticipantIdentifier = remoteParticipantIdentity.identifier
                        print("RemoteParticipant identifier:  \(String(describing: remoteParticipantIdentifier))")
                        print("RemoteParticipant displayName \(String(describing: remoteParticipant.displayName))")

                        let remoteVideoStreamModel = RemoteVideoStreamModel(id: remoteParticipantIdentity.identifier, identity: remoteParticipantIdentity, displayName: remoteParticipant.displayName, remoteParticipant: remoteParticipant)
                        remoteVideoStreamModels.append(remoteVideoStreamModel!)

                        print("\nRemoteVideoStream count for \(String(describing: remoteParticipant.displayName)):  \(remoteParticipant.videoStreams.count)")

                        if remoteParticipant.videoStreams.count > 0 {
                            print("\nBinding remoteVideoStream for \(String(describing: remoteParticipant.displayName))")
                            remoteParticipant.videoStreams.forEach { (remoteVideoStream) in
                                if self.remoteVideoStreamModels.first(where: {$0.id == remoteParticipantIdentifier }) == nil {
                                    print("\nBinding remoteVideoStream for \(String(describing: remoteVideoStream.id))")

//                                    remoteVideoStreamModel!.createView(remoteVideoStream: remoteVideoStream)
                                }
                            }
                        } else {
                            print("RemoteVideoStream for \(String(describing: remoteParticipant.displayName)) not found.")
                        }

//                        if callerIdentifier != nil {
//                            print("callerIdentifier: \(String(describing: callerIdentifier))")
//                            if callerIdentifier == remoteParticipantIdentifier {
//                                callerDisplayName = remoteParticipant.displayName ?? "No displayName"
//                                print("Incoming callerDisplayName: \(String(describing: callerDisplayName))")
//                            }
//                        }
                    }
                }
            }
        }

        if let removedParticipants = args.removedParticipants {
            if !removedParticipants.isEmpty {
                print("removedParticipants: \(String(describing: args.removedParticipants.count))")

                if callerIdentifier != nil {
                    print("callerIdentifier: \(String(describing: callerIdentifier))")
                    if let callerRemoteParticipant = args.removedParticipants.first(where: {($0.identity as! CommunicationUserIdentifier).identifier == callerIdentifier}) {
                        let callerDisplayName = callerRemoteParticipant.displayName ?? "No displayName"
                        print("Removed callerDisplayName: \(String(describing: callerDisplayName))")
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
