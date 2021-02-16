//
//  CallView.swift
//  AzureCommunicationVideoCallingSample
//
//  Created by Hyounwoo Sung on 2021/02/02.
//

import SwiftUI

struct CallView: View {
    @EnvironmentObject var authenticationViewModel: AuthenticationViewModel
    @EnvironmentObject var callingViewModel: CallingViewModel

    var body: some View {
        VStack {
            if callingViewModel.remoteVideoStreamModels.count == 1 {
                DirectCall()
            } else {
                GroupCall()
            }
            Spacer()
            HStack {
                Button(action: { }, label: {
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
        .environmentObject(authenticationViewModel)
        .environmentObject(callingViewModel)
    }
}

struct CallView_Previews: PreviewProvider {
    static var previews: some View {
        CallView()
            .environmentObject(AuthenticationViewModel())
            .environmentObject(CallingViewModel())
    }
}
