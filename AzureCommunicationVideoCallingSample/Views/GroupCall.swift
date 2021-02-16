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
            Grid(callingViewModel.remoteVideoStreamModels) { stream in
                StreamView(remoteVideoStreamModel: stream)
                    .padding()
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
