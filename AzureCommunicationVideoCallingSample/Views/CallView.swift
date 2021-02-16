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
        Group {
            if callingViewModel.remoteVideoStreamModels.count == 1 {
                DirectCall()
            } else if callingViewModel.remoteVideoStreamModels.count > 1{
                GroupCall()
            } else {
                Text("Initializing streams")
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
