//
//  LiveDetection.swift
//  VisionKitDemo
//
//  Created by Itsuki on 2024/07/26.
//

import SwiftUI

struct LiveDetection: View {
    
    @StateObject private var detectionModel = DetectionModel(mode: .live)
    @State private var sliderValue: Double = .zero
    @State private var imageSize: CGSize = .zero

    var body: some View {
        
        VStack(spacing: 16) {
            detectionModel.previewImage?.image?
                .resizable()
                .scaledToFit()
                .overlay(content: {
                    GeometryReader { geometry in
                        DispatchQueue.main.async {
                            self.imageSize = geometry.size
                        }
                        return Color.clear
                    }
                })
                .overlay(content: {
                    ForEach(0..<detectionModel.observations.count, id: \.self) { index in

                        let observation = detectionModel.observations[index]

                        let (text, confidence, boxSize, boxPosition) = detectionModel.vision.processObservation(observation, for: imageSize)

                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.black, style: .init(lineWidth: 4.0))
                            .overlay(alignment: .topLeading, content: {
                                Text("\(text): \(confidence)")
                                    .background(.white)
                                    .offset(y: -28)
                            })
                            .frame(width: boxSize.width, height: boxSize.height)
                            .position(boxPosition)
                    }
                })
            
            Button(action: {
                detectionModel.isDetecting.toggle()
            }, label: {
                Text("\(detectionModel.isDetecting ? "Stop" : "Start") Detection")
                    .foregroundStyle(.black)
                    .padding(.all)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.black, lineWidth: 2.0))
            })
            
            Slider(
                value: $sliderValue,
                in: 0...Double(detectionModel.maxFramePerSecond),
                step: 1,
                onEditingChanged: {changing in
                    guard !changing else {return}
                    detectionModel.framePerSecond = Int(sliderValue)
                }
            )
            Text("Vision Processing FPS: \(Int(sliderValue))")
            Text("When FPS is 0, processing continuously.")
                .foregroundStyle(.red)

        }
        .task {
            await detectionModel.camera.start()
        }
        .onDisappear {
            detectionModel.isDetecting = false
            detectionModel.camera.stop()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.all, 32)
    }
}


#Preview {
    LiveDetection()
}
