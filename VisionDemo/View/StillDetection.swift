//
//  ContentView.swift
//  VisionKitDemo
//
//  Created by Itsuki on 2024/07/26.
//

import SwiftUI
import Vision

private enum DetectionMode: CaseIterable {
    case text
    case barcode
}

struct StillDetection: View {
    
    @StateObject private var detectionModel = DetectionModel(mode: .still)
    private let modes = DetectionMode.allCases
    @State private var selectedModes: [DetectionMode] = [.text]
    
    @State private var imageSize: CGSize = .zero

    var body: some View {
        let (imageName, buttonText, action): (String, String, (Data)->Void) = switch selectedModes {
        case [.barcode]:
            ("enjoyQR", "Detect Barcode", {data in
                Task {
                    await detectionModel.vision.detectBarcode(data)
                }
            })
        case [.text]:
            ("enjoyText", "Detect Text", {data in
                Task {
                    await detectionModel.vision.detectText(data)
                }
            })
        case [.barcode, .text], [.text, .barcode]:
            ("enjoyMerge", "Detect Text & Barcode", {data in
                Task {
                    await detectionModel.vision.detectBarcodeAndText(data)
                }
            })
        default:
            ("", "", {_ in})
        }
       
        
        VStack(spacing: 16) {
            
            HStack(spacing: 16) {
                ForEach(modes, id: \.self) { mode in
                    let isChecked = selectedModes.contains(mode)
                    Button(action: {
                        detectionModel.observations = []
                        if isChecked {
                            selectedModes.removeAll(where: {$0 == mode})
                        } else {
                            selectedModes.append(mode)
                        }
                    }, label: {
                        HStack(spacing: 8) {
                            
                            Image(systemName: "square")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16)
                                .foregroundStyle(.blue)
                                .overlay {
                                    Image(systemName: "checkmark")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 8)
                                        .foregroundStyle(.white)
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 4).fill(isChecked ? .blue: .white))

                            Text("\(mode)")
                                .foregroundStyle(.black)
                        }
                    })
                    .padding(.vertical, 8)
                    .padding(.horizontal, 0)
                    .frame(height: 48)
                }
                
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            if !imageName.isEmpty {
                           
                Image(imageName)
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
                    guard let imageData = UIImage(named: imageName)?.pngData() else { return }
                    action(imageData)
                }, label: {
                    Text(buttonText)
                        .foregroundStyle(.black)
                        .padding(.all)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.black, lineWidth: 2.0))
                })
 
                
            }
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.all, 32)
    }
    
}


#Preview {
    StillDetection()
}
