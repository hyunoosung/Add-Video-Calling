//
//  LocalRendererView.swift
//  AzureCommunicationVideoCallingSample
//
//  Created by Hyounwoo Sung on 2021/02/03.
//

import SwiftUI
import AzureCommunicationCalling

struct VideoStreamView: UIViewRepresentable {

    // This should be passed when you instantiate this class.
    // You should use value of `self.localRendererView` variable in your case.
    let view: RendererView

    func makeUIView(context: Context) -> UIView {
        return view // Fix#2: do NOT create a new view but rather use value returned from `renderer.createView()`
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
