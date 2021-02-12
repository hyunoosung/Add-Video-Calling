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
                remoteVideoStreamModel.videoStreamView
            }
        }
    }
}

struct StreamView_Previews: PreviewProvider {
    static var previews: some View {
        StreamView(remoteVideoStreamModel: RemoteVideoStreamModel(id: nil, identity: nil, displayName: nil, remoteParticipant: nil)!)
    }
}
