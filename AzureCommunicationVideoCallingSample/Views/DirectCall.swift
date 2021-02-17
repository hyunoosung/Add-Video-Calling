//
//  DirectCall.swift
//  AzureCommunicationVideoCallingSample
//
//  Created by Hyounwoo Sung on 2021/02/04.
//

import SwiftUI

struct DirectCall: View {
    @EnvironmentObject var authenticationViewModel: AuthenticationViewModel
    @EnvironmentObject var callingViewModel: CallingViewModel

    var body: some View {
        ZStack {
            ForEach(callingViewModel.remoteVideoStreamModels, id: \.self) { remoteVideoStreamModel in
                StreamView(remoteVideoStreamModel: remoteVideoStreamModel)
            }

            VStack(alignment: .center) {
                HStack {
                    ZStack {
                        if CallingViewModel.shared().localVideoStreamModel != nil {
                            CallingViewModel.shared().localVideoStreamModel?.videoStreamView
                            .frame(width: 120, height: 192)
                            .cornerRadius(16)
                            .zIndex(1)
                        } else {
                            Rectangle()
                                .fill(Color.secondary)
                                .frame(width: 120, height: 192)
                                .cornerRadius(16)
                        }
                    }
                    .frame(width: 120, height: 192)
                    Spacer()
                }
                .padding()
                .padding(.top, 50)

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

struct DirectCall_Previews: PreviewProvider {
    static var previews: some View {
        DirectCall()
            .environmentObject(AuthenticationViewModel())
            .environmentObject(CallingViewModel())
    }
}
