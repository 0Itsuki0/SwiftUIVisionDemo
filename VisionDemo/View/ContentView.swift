//
//  ContentView.swift
//  VisionKitDemo
//
//  Created by Itsuki on 2024/07/27.
//


import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack (spacing: 50) {
            NavigationLink {
                StillDetection()
            } label: {
                Text("Still Image Detection")
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 16).fill(.black))
            }
            
            
            NavigationLink {
                LiveDetection()
            } label: {
                Text("Live Capture Detection")
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 16).fill(.black))
            }
            
            NavigationLink {
                ObjectTracking()
            } label: {
                Text("Object Tracking")
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 16).fill(.black))
            }

        }
        .foregroundStyle(.white)
        .font(.system(size: 24))
        .fixedSize(horizontal: true, vertical: false)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

#Preview {
    return NavigationStack {
        ContentView()

    }
}
