//
//  VisionKitDemoApp.swift
//  VisionKitDemo
//
//  Created by Itsuki on 2024/07/26.
//

import SwiftUI

@available(iOS 18, *)
@main
struct VisionKitDemoApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .background(.gray.opacity(0.2))

        }
    }
}
