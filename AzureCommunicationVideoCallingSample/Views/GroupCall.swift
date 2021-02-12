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
            if callingViewModel.remoteVideoStreamModels.count == 1 {
                callingViewModel.remoteVideoStreamModels[0].videoStreamView
            } else {
                Rectangle()
                    .fill(Color.gray)
                    .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
            }

            VStack(alignment: .center) {
                HStack {
                    ZStack {
                        if callingViewModel.localVideoStreamModel != nil {
                        callingViewModel.localVideoStreamModel?.videoStreamView
                            .frame(width: 120, height: 192)
                            .cornerRadius(16)
                            .zIndex(1)
                        } else {
                            Rectangle()
                                .fill(Color.secondary)
                                .frame(width: 120, height: 192)
                                .cornerRadius(16)
                        }

                        VStack {
                            Spacer()
                            Text("status")
                                .foregroundColor(.white)
                                .font(.subheadline)
                                .padding(.bottom, 5)
                        }
                        .zIndex(1)
                    }
                    .frame(width: 120, height: 192)
                    Spacer()
                }
                .padding()
                .padding(.top, 50)
                Spacer()
            }
            .zIndex(1)

            VStack {
                Spacer()
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
            .zIndex(2)
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
