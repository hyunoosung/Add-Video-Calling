//
//  CallKitManager.swift
//  AzureCommunicationVideoCallingSample
//
//  Created by Hyounwoo Sung on 2021/02/09.
//

import Foundation
import SwiftUI
import CallKit
import AzureCommunicationCalling
import AVFoundation

class CallKitManager: NSObject {
    private static var sharedInstance: CallKitManager?

    private let callController = CXCallController()
    private let provider: CXProvider


    static func shared() -> CallKitManager {
        if sharedInstance == nil {
            sharedInstance = CallKitManager()
        }
        return sharedInstance!
    }

    override init() {
        let configuration = CXProviderConfiguration()
        configuration.maximumCallGroups = 1
        configuration.maximumCallsPerCallGroup = 1
        configuration.supportsVideo = true
        configuration.iconTemplateImageData = UIImage(systemName: "video")?.pngData()
        provider = CXProvider(configuration: configuration)
        super.init()
        provider.setDelegate(self, queue: nil)
        print("callkitmanager init")
    }

    deinit {
        provider.invalidate()
    }

    // Start an outging call
    func startOutgoingCall(call: Call, callerDisplayName: String) {
        let callId = UUID(uuidString: call.callId)
        let handle = CXHandle(type: .generic, value: callerDisplayName)
        let startCallAction = CXStartCallAction(call: callId!, handle: handle)
        let transaction = CXTransaction(action: startCallAction)

        callController.request(transaction) { error in
            if let error = error {
                print("Error requesting CXStartCallAction transaction: \(error)")
            } else {
                print("Requested CXStartCallAction transaction successfully")
            }
        }

        provider.reportOutgoingCall(with: callId!, connectedAt: nil)
    }

    // End the call from the app. This is not needed when user end the call from the native CallKit UI
    func endCallFromLocal(callId: UUID, completion: @escaping (Bool) -> Void) {
        let endCallAction = CXEndCallAction(call: callId)
        let transaction = CXTransaction(action: endCallAction)

        callController.request(transaction, completion: { error in
            if let error = error {
                print("Error requesting CXEndCallAction transaction: \(error.localizedDescription)\n")
                completion(false)
            } else {
                print("Requested CXEndCallAction transaction successfully.\n")
                completion(true)
            }
        })
    }

    // This is normally called after receiving a VoIP Push Notification to handle incoming call
    func reportNewIncomingCall(incomingCallPushNotification: IncomingCallPushNotification, completion: @escaping (Bool) -> Void) {
        let callId = incomingCallPushNotification.callId
        let displayName = String(incomingCallPushNotification.fromDisplayName ?? "unknown")
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: "Incoming call from \(displayName)")

        self.provider.reportNewIncomingCall(with: callId, update: update) { (error) in
            if error == nil {
                completion(true)
            } else {
                completion(false)
            }
        }
    }

    func testReport(completion: @escaping (Bool) -> Void) {
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .emailAddress, value: "Test")
        self.provider.reportNewIncomingCall(with: UUID(), update: update) { (error) in
            if error == nil {
                completion(true)
            } else {
                completion(false)
            }
        }
    }

    // Mute or unmute from the app. This is to sync the CallKit UI with app UI
    func setMuted(for call: Call, isMuted: Bool) {
//        let setMutedAction = CXSetMutedCallAction(call: call.uuid, muted: isMuted)
//        let transaction = CXTransaction(action: setMutedAction)
//        callController.request(transaction, completion: { error in
//            if let error = error {
//                self.logger.error(msg: "Error requesting CXSetMutedCallAction transaction: \(error)")
//            } else {
//                self.logger.info(msg: "Requested CXSetMutedCallAction transaction successfully")
//            }
//        })
    }

    // This is to resume call from the app. When the interrupting call is ended from Remote,
    // provider::perform::CXSetMutedCallAction will not be called automatically
    func setHeld(with call: Call, isOnHold: Bool) {
//        let setHeldCallAction = CXSetHeldCallAction(call: call.uuid, onHold: isOnHold)
//        let transaction = CXTransaction(action: setHeldCallAction)
//        callController.request(transaction, completion: { error in
//            if let error = error {
//                self.logger.error(msg: "Error requesting CXSetHeldCallAction transaction: \(error)")
//            } else {
//                self.logger.info(msg: "Requested CXSetHeldCallAction \(isOnHold) transaction successfully")
//            }
//        })
    }

    // Use this to notify CallKit the call is disconnected
    func reportCallEndedFromRemote(callId: UUID, reason: CXCallEndedReason) {
        print("reportCallEndedFromRemote.\n")
        provider.reportCall(with: callId, endedAt: Date(), reason: reason)
    }
}

extension CallKitManager: CXProviderDelegate {
    func providerDidReset(_ provider: CXProvider) {
        print("providerDidReset")
    }

    func providerDidBegin(_: CXProvider) {}

    func provider(_: CXProvider, perform action: CXStartCallAction) {
//        let calees = [CommunicationUserIdentifier(identifier: CallingViewModel.shared().callee)]
//        CallingViewModel.shared().startCall(callees: calees) {
            action.fulfill()
//        }
    }

    func provider(_: CXProvider, perform action: CXAnswerCallAction) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1, execute: {
            CallingViewModel.shared().acceptCall(callId: action.callUUID) { success in
                if success {
                    print("CallKit answerCall success.\n")
                    action.fulfill()
                } else {
                    print("CallKit answerCall failed.\n")
                    action.fail()
                }
            }
        })
    }

    func provider(_: CXProvider, perform action: CXEndCallAction) {
        CallingViewModel.shared().endCall(callId: action.callUUID) { success in
            if success {
                print("CallKit endCall success.\n")
                action.fulfill()
            } else {
                print("CallKit endCall failed.\n")
                action.fail()
            }
        }
    }

    func provider(_: CXProvider, perform action: CXSetHeldCallAction) {
        action.fulfill()
    }

    func provider(_: CXProvider, perform action: CXSetMutedCallAction) {
//        if let call = CallingViewModel.shared().getCall() {
//            if UUID(uuidString: call.callId) == action.callUUID {
//                if action.isMuted {
//                    call.unmute { error in
//                        if error != nil {
//                            action.fail()
//                        } else {
//                            action.fulfill()
//                        }
//                    }
//                } else {
//                    call.mute { error in
//                        if error != nil {
//                            action.fail()
//                        } else {
//                            action.fulfill()
//                        }
//                    }
//                }
//            } else {
//                action.fail()
//            }
//        }
    }

    func provider(_: CXProvider, timedOutPerforming _: CXAction) {}

    func provider(_: CXProvider, didActivate _: AVAudioSession) {}

    func provider(_: CXProvider, didDeactivate _: AVAudioSession) {}
}
