//
//  PushRegistryDelegate.swift
//  AzureCommunicationVideoCallingSample
//
//  Created by Hyounwoo Sung on 2021/02/22.
//

import PushKit
import AzureCommunicationCalling

class PushRegistryDelegate: NSObject {
    static let shared: PushRegistryDelegate = PushRegistryDelegate()
    private let pushRegistry = PKPushRegistry(queue: DispatchQueue.main)

    private override init() {
        super.init()
        ProviderDelegate.shared.configureProvider()
        pushRegistry.delegate = self
        pushRegistry.desiredPushTypes = [.voIP]
    }
}

extension PushRegistryDelegate: PKPushRegistryDelegate {
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        CallingViewModel.shared.setVoipToken(token: pushCredentials.token)
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        print("pushRegistry invalidated: \(type)\n")
    }

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        let dictionaryPayload = payload.dictionaryPayload
        print("dictionaryPayload: \(dictionaryPayload)\n")

        if type == .voIP {
            if let incomingCallPushNotification = IncomingCallPushNotification.fromDictionary(payload.dictionaryPayload) {
                let callId = incomingCallPushNotification.callId
                let handle = incomingCallPushNotification.fromDisplayName
                let hasVideo = incomingCallPushNotification.hasIncomingVideo

                ProviderDelegate.shared.reportNewIncomingCall(callId: callId, handle: handle ?? "Unknown", hasVideo: hasVideo) { error in
                    if let error = error {
                        print("reportNewIncomingCall failed: \(error.localizedDescription)\n")
                    } else {
                        print("reportNewIncomingCall was succesful.\n")
                    }
                    completion()

                    CallingViewModel.shared.handlePushNotification(incomingCallPushNotification: incomingCallPushNotification)
                }
            } else {
                print("No incomingCallPushNotification found.\n")
            }
        }
    }
}
