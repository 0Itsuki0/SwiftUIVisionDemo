//
//  ObjectTracking.swift
//  VisionDemo
//
//  Created by Itsuki on 2024/07/27.
//

import SwiftUI

struct ObjectTracking: View {
    
    @StateObject private var trackingModel = TrackingModel()
    @State private var imageSize: CGSize = .zero

    private let boundingBoxPadding: CGFloat = 4.0
    private let asset = NSDataAsset(name: "enjoyAnimated")
    
    @State private var gifImage: Image?

    
    var body: some View {
        
        VStack(spacing: 16) {
            gifImage?
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
                    ForEach(trackingModel.trackedObjects) { object in
                        let rect = object.rect
                        if rect != .zero, let label = object.label {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.black, style: .init(lineWidth: 4.0))
                                .overlay(alignment: .topLeading, content: {
                                    Text("\(label)")
                                        .background(.white)
                                        .offset(y: -28)
                                })
                                .frame(width: rect.width + boundingBoxPadding*2, height: rect.height + boundingBoxPadding*2)
                                .position(CGPoint(x: rect.midX, y: rect.midY))
                            
                        }
                    }
                })
            
            Button(action: {
                trackingModel.isTracking.toggle()
            }, label: {
                Text("\(trackingModel.isTracking ? "Stop" : "Start") Tracking")
                    .foregroundStyle(.black)
                    .padding(.all)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.black, lineWidth: 2.0))
            })
            
            
            VStack(spacing: 16) {
                Text("Tracked Object")
                
                Divider()
                    .background(.black)

                ForEach(trackingModel.trackedObjects) { object in
                    Text("\(object.id) \(object.label ?? "Not available"): \(-Int(object.firstDetect.timeIntervalSinceNow)) sec")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.black, lineWidth: 2.0)
            )

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.all, 32)
        .onAppear {
            if let asset {
                let gifData = asset.data as CFData
                CGAnimateImageDataWithBlock(gifData, nil) { index, cgImage, stop in
                    self.gifImage = Image(uiImage: .init(cgImage: cgImage))
                    
                    if trackingModel.isTracking {
                        guard let imageData = UIImage(cgImage: cgImage).pngData() else { return }
                        Task {
                            await trackingModel.tracking(imageData, size: CGSize(width: imageSize.width, height: imageSize.height))
                        }
                    }
                }
            }
        }
        .onDisappear {
            trackingModel.isTracking = false
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }
    
}



//
//struct ObjectTracking: View {
////    private let phases: [CGFloat] = [-3, -2, -1, 0, 1, 2, 3, 2, 1, 0, -1, -2]
//    
//    private let phases: [CGFloat] = [0, 1, 2, 3]
//
//    
////    private let phases: [(CGFloat, CGFloat)] = [(0, 0), (0, 1), (1, 1), (1, 0)]
//
//    var body: some View {
//        let offset = (UIScreen.main.bounds.width + 150)/2
//        VStack {
//            PhaseAnimator(phases, content: {phase in
//                let offsetX: CGFloat = switch phase {
//                case 0:
//                    -offset
//                case 1:
//                    offset
//                case 2:
//                    offset
//                case 3:
//                    -offset
//                default:
//                    0
//                }
//                
//                let offsetY: CGFloat = switch phase {
//                case 0:
//                    -offset
//                case 1:
//                    -offset
//                case 2:
//                    offset
//                case 3:
//                    offset
//                default:
//                    0
//                }
//
//                
//                Text("Enjoy")
//                    .font(.system(size: 48, weight: .bold))
//                    .offset(x: offsetX, y: 0)
//                
//                Text("Life!")
//                    .font(.system(size: 48, weight: .bold))
//                    .offset(x: -offsetX, y: 50)
//
//            }, animation: {phase in
//                    .linear(duration: 4)
//            })
//
//
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .background(.yellow.opacity(0.2))
//
//    }
//}


#Preview {
    ObjectTracking()
}
