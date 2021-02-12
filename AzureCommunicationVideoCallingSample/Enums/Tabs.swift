//
//  Tabs.swift
//  AzureCommunicationVideoCallingSample
//
//  Created by Hyounwoo Sung on 2021/02/01.
//

import SwiftUI

enum Tab: Int, Identifiable, CaseIterable {
    case home
    case profile

    var id: Int {
        return rawValue
    }

    var name: String {
        switch self {
        case .home:
            return "Home"
        case .profile:
            return "Profile"
        }
    }

    private var imageName: String {
        switch self {
        case .home:
            return "list.bullet"
        case .profile:
            return "person"
        }
    }

    var tabItem: some View {
        Group {
            Text(name)
            Image(systemName: imageName)
        }
    }

    var presentingView: some View {
        switch self {
        case .home:
            return AnyView(HomeView())
        case .profile:
            return AnyView(ProfileView())
        }
    }
}

