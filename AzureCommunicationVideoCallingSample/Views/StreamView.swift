//
//  StreamView.swift
//  AzureCommunicationVideoCallingSample
//
//  Created by Hyounwoo Sung on 2021/02/06.
//

import SwiftUI
import Combine
import AzureCommunicationCalling

struct StreamView: View {
    @StateObject var remoteVideoStreamModel: RemoteVideoStreamModel
    @State var isMicrophoneMuted:Bool = false
    @State var isSpeaking:Bool = false

    var body: some View {
        ZStack {
            if remoteVideoStreamModel.videoStreamView != nil {
                remoteVideoStreamModel.videoStreamView!
                    .padding(0)
            }
            VStack(alignment: .center) {
                HStack {
                    Spacer()
                    Text(remoteVideoStreamModel.displayName)
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                    Image(systemName: self.isMicrophoneMuted ? "speaker.slash" : "speaker.wave.2")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                        .padding()
                    Spacer()
                }
                Spacer()
            }
        }
        .onReceive(remoteVideoStreamModel.$isMicrophoneMuted, perform: { isMicrophoneMuted in
            self.isMicrophoneMuted = isMicrophoneMuted
            print("isMicrophoneMuted: \(isMicrophoneMuted)")
        })
        .onReceive(remoteVideoStreamModel.$isSpeaking, perform: { isSpeaking in
            self.isSpeaking = isSpeaking
            print("isSpeaking: \(isSpeaking)")
        })
        .onAppear {
            remoteVideoStreamModel.checkStream()
        }
    }
}
