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
    var body: some View {
        VStack {
            if remoteVideoStreamModel.videoStreamView != nil {
                remoteVideoStreamModel.videoStreamView!
            }
            TextField("DisplayName", text: $remoteVideoStreamModel.displayName)
        }
        .onAppear {
            remoteVideoStreamModel.checkStream()
        }
    }
}
