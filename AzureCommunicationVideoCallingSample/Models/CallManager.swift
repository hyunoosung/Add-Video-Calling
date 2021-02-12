////
////  CallManager.swift
////  AzureCommunicationVideoCallingSample
////
////  Created by Hyounwoo Sung on 2021/02/10.
////
//
//import Foundation
//import AVFoundation
//import AzureCommunicationCalling
//
//class CallManager2 {
//    private static var sharedInstance: CallManager?
//    private(set) var callClient: CallClient?
//    private(set) var callAgent: CallAgent?
//    private(set) var call: Call?
//    private(set) var deviceManager: DeviceManager?
//    private(set) var localVideoStream: LocalVideoStream?
//
//    static func shared() -> CallManager {
//        if sharedInstance == nil {
//            sharedInstance = CallManager()
//
//            // This is to initialize CallKit properly before requesting first outgoing/incoming call
//            _ = CallKitManager.shared()
//        }
//        return sharedInstance!
//    }
//
//    init() {
//        callClient = CallClient()
//    }
//
//    func getDeviceManager() -> Void {
//        callClient?.getDeviceManager(completionHandler: { (deviceManager, error) in
//            if (error == nil) {
//                print("Got device manager instance")
//                self.deviceManager = deviceManager
//
//                let videoDeviceInfo: VideoDeviceInfo? = deviceManager?.getCameraList()![0]
//                self.localVideoStream = LocalVideoStream(camera: videoDeviceInfo)
//                print("LocalVideoStream instance initialized.")
//            } else {
//                print("Failed to get device manager instance: \(String(describing: error))")
//            }
//        })
//    }
//
//    func setCallAgent(callAgent: CallAgent?) {
//        CallingViewModel().shared().callAgent = callAgent
//    }
//
//    func setCall(call: Call?) {
//        CallingViewModel.shared().call = call
//    }
//
//    func startCall(callees: [CommunicationUserIdentifier], completion: @escaping (Call?) -> Void) {
//        requestRecordPermission { success in
//            guard success else {
//                completion(nil)
//                return
//            }
//
//            let startCallOptions = StartCallOptions()
//            if let localVideoStream = self.localVideoStream {
//                let videoOptions = VideoOptions(localVideoStream: localVideoStream)
//                startCallOptions?.videoOptions = videoOptions
//            }
//
//            if let callAgent = CallingViewModel().shared().callAgent {
//                CallingViewModel.shared().call = callAgent.call(participants: callees, options: startCallOptions)
//                self.startVideo()
//                completion(CallingViewModel.shared().call)
//            } else {
//                completion(nil)
//            }
//        }
//    }
//
//    func startVideo() -> Void {
//        requestVideoPermission { success in
//            if success {
//                CallingViewModel.shared().call?.startVideo(stream: self.localVideoStream) { error in
//                    if error != nil {
//                        print("LocalVideo failed to start.\n")
//                    } else {
//                        print("LocalVideo started successfully.\n")
//                    }
//                }
//            } else {
//                print("Permission denied.\n")
//            }
//        }
//    }
//
//    func stopVideo(competion: @escaping (Bool) -> Void) {
//        if let call = CallingViewModel.shared().call {
//            call.stopVideo(stream: localVideoStream) { error in
//                if error != nil {
//                    print("LocalVideo failed to stop.\n")
//                    competion(false)
//                } else {
//                    print("LocalVideo stopped successfully.\n")
//                    competion(true)
//                }
//            }
//        }
//    }
//
//    func acceptCall() -> Void {
//        if let call = CallingViewModel.shared().call {
//            let acceptCallOptions = AcceptCallOptions()
//            if let localVideoStream = self.localVideoStream {
//                let videoOptions = VideoOptions(localVideoStream: localVideoStream)
//                acceptCallOptions?.videoOptions = videoOptions
//                self.startVideo()
//            }
//
//            call.accept(options: acceptCallOptions) { error in
//                if error != nil {
//                    print("Failed to accpet incoming call.\n")
//                } else {
//                    print("Incoming call accepted with acceptCallOptions.\n")
//                }
//            }
//
//        } else {
//            print("No incoming call found.\n")
//        }
//    }
//
//    func endCall() -> Void {
//        if let call = CallingViewModel.shared().call {
//            call.hangup(options: HangupOptions()) { error in
//                if error != nil {
//                    print("ERROR: It was not possible to hangup the call.\n")
//                } else {
//                    print("Call ended.\n")
//                }
//            }
//        } else {
//            print("Call not found.\n")
//        }
//    }
//
//    // MARK: Request RecordPermission
//    func requestRecordPermission(completion: @escaping (Bool) -> Void) {
//        let audioSession = AVAudioSession.sharedInstance()
//        switch audioSession.recordPermission {
//        case .undetermined:
//            audioSession.requestRecordPermission { granted in
//                if granted {
//                    completion(true)
//                } else {
//                    print("User did not grant audio permission")
//                    completion(false)
//                }
//            }
//        case .denied:
//            print("User did not grant audio permission, it should redirect to Settings")
//            completion(false)
//        case .granted:
//            completion(true)
//        @unknown default:
//            print("Audio session record permission unknown case detected")
//            completion(false)
//        }
//    }
//
//    // MARK: Request VideoPermission
//    func requestVideoPermission(completion: @escaping (Bool) -> Void) {
//        switch AVCaptureDevice.authorizationStatus(for: .video) {
//        case .notDetermined:
//            AVCaptureDevice.requestAccess(for: .video) { authorized in
//                if authorized {
//                    completion(true)
//                } else {
//                    print("User did not grant video permission")
//                    completion(false)
//                }
//            }
//        case .restricted, .denied:
//            print("User did not grant video permission, it should redirect to Settings")
//            completion(false)
//        case .authorized:
//            completion(true)
//        @unknown default:
//            print("AVCaptureDevice authorizationStatus unknown case detected")
//            completion(false)
//        }
//    }
//
//    // MARK: Configure AudioSession
//    func configureAudioSession() {
//        let audioSession = AVAudioSession.sharedInstance()
//        do {
//            if audioSession.category != .playAndRecord {
//                try audioSession.setCategory(AVAudioSession.Category.playAndRecord,
//                                             options: AVAudioSession.CategoryOptions.allowBluetooth)
//                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
//            }
//            if audioSession.mode != .voiceChat {
//                try audioSession.setMode(.voiceChat)
//            }
//        } catch {
//            print("Error configuring AVAudioSession: \(error.localizedDescription)")
//        }
//    }
//
//    func registerPushNotifications() {
////        let deviceToken: Data = pushRegistry?.pushToken(for: PKPushType.voIP)
////        CallingViewModel().shared().callAgent?.registerPushNotifications(deviceToken: deviceToken,
////                        completionHandler: { (error) in
////            if(error == nil) {
////                print("Successfully registered to push notification.")
////            } else {
////                print("Failed to register push notification.")
////            }
////        })
//    }
//
//    func handlePushNotifications() {
////        let dictionaryPayload = pushPayload?.dictionaryPayload
////        callAgent.handlePushNotification(payload: dictionaryPayload, completionHandler: { (error) in
////            if (error != nil) {
////                print("Handling of push notification failed")
////            } else {
////                print("Handling of push notification was successful")
////            }
////        })
//    }
//
//    func unRegisterPushNotifications() {
////        CallingViewModel().shared().callAgent?.unRegisterPushNotifications(completionHandler: { (error) in
////            if (error != nil) {
////                print("Unregister of push notification failed, please try again")
////            } else {
////                print("Unregister of push notification was successful")
////            }
////        })
//    }
//}
