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
        ZStack {
            Grid(callingViewModel.remoteVideoStreamModels) { stream in
                StreamView(remoteVideoStreamModel: stream)
                    .padding()
            }

            VStack(alignment: .center) {
                Spacer()
                HStack {
                    Button(action: { callingViewModel.toggleVideo() }, label: {
                        HStack {
                            Spacer()
                            if callingViewModel.isLocalVideoStreamEnabled {
                                Image(systemName: "video")
                                    .padding()
                            } else {
                                Image(systemName: "video.slash")
                                    .padding()
                            }
                            Spacer()
                        }
                    })
                    Button(action: { callingViewModel.mute() }, label: {
                        HStack {
                            Spacer()
                            if callingViewModel.isMicrophoneMuted {
                                Image(systemName: "speaker.slash")
                                    .padding()
                            } else {
                                Image(systemName: "speaker.wave.2")
                                    .padding()
                            }
                            Spacer()
                        }
                    })
                    Button(action: { callingViewModel.endCall() }, label: {
                        HStack {
                            Spacer()
                            Image(systemName: "phone.down")
                                .foregroundColor(.red)
                                .padding()
                            Spacer()
                        }
                    })
                }
                .font(.largeTitle)
                .padding(.bottom, 5)
            }
            .zIndex(1)

        }
        .ignoresSafeArea(edges: .all)
    }
}

struct GroupCall_Previews: PreviewProvider {
    static var previews: some View {
        GroupCall()
            .environmentObject(AuthenticationViewModel())
            .environmentObject(CallingViewModel())
    }
}
