//
//  GroupCall.swift
//  AzureCommunicationVideoCallingSample
//
//  Created by Hyounwoo Sung on 2021/02/06.
//

import SwiftUI

struct GroupCall: View {
    @EnvironmentObject var authenticationViewModel: AuthenticationViewModel
    @EnvironmentObject var callingViewModel: CallingViewModel

    var body: some View {
        Group {
            Grid(callingViewModel.remoteVideoStreamModels) { stream in
//                Text(stream.displayName)
                StreamView(remoteVideoStreamModel: stream)
                    .padding()
            }
            HStack {
                Button(action: { callingViewModel.stopVideo() }, label: {
                    HStack {
                        Spacer()
                        Text("Camera")
                        Spacer()
                    }
                })
                Button(action: { callingViewModel.mute() }, label: {
                    HStack {
                        Spacer()
                        Text("Mute")
                        Spacer()
                    }
                })
                Button(action: { callingViewModel.endCall() }, label: {
                    HStack {
                        Spacer()
                        Text("End Call")
                        Spacer()
                    }
                })
            }
        }
    }
}

struct GroupCall_Previews: PreviewProvider {
    static var previews: some View {
        GroupCall()
            .environmentObject(AuthenticationViewModel())
            .environmentObject(CallingViewModel())
    }
}
