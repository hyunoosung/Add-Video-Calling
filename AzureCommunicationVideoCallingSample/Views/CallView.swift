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
        VStack(alignment: .center, spacing: 0) {
            if callingViewModel.remoteVideoStreamModels.count == 0 {
                VStack {
                    Text("Waiting for other participants...")
                    Button(action: { callingViewModel.endCall() }, label: {
                       HStack {
                           Spacer()
                           Text("Leave Group Call")
                           Spacer()
                       }
                   })

                }
            } else if callingViewModel.remoteVideoStreamModels.count == 1 {
                DirectCall()
                    .environmentObject(callingViewModel)
            } else {
                GroupCall()
                    .environmentObject(callingViewModel)
            }
        }
    }
}

struct CallView_Previews: PreviewProvider {
    static var previews: some View {
        CallView()
            .environmentObject(AuthenticationViewModel())
            .environmentObject(CallingViewModel())
    }
}
