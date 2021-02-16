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

//            VStack {
//                Spacer()
//                HStack {
//                    Button(action: { }, label: {
//                        HStack {
//                            Spacer()
//                            Text("Camera")
//                            Spacer()
//                        }
//                    })
//                    Button(action: { callingViewModel.mute() }, label: {
//                        HStack {
//                            Spacer()
//                            Text("Mute")
//                            Spacer()
//                        }
//                    })
//                    Button(action: { callingViewModel.endCall() }, label: {
//                        HStack {
//                            Spacer()
//                            Text("End Call")
//                            Spacer()
//                        }
//                    })
//                }
//            }
//            .zIndex(2)
        }
    }
}

struct DirectCall_Previews: PreviewProvider {
    static var previews: some View {
        DirectCall()
            .environmentObject(AuthenticationViewModel())
            .environmentObject(CallingViewModel())
    }
}
