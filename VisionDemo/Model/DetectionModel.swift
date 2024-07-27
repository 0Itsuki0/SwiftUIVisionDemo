//
//  DetectionModel.swift
//  VisionKitDemo
//
//  Created by Itsuki on 2024/07/27.
//
import SwiftUI
import Vision


class DetectionModel: ObservableObject {
    
    let camera = CameraManager()
    let vision = VisionManager()
    
    @Published var observations: [any VisionObservation] = []
    @Published var previewImage: CIImage?
    @Published var isDetecting: Bool = false {
        didSet {
            if isDetecting {
                print("start")
                if framePerSecond > 0 {
                    self.timer = Timer.scheduledTimer(timeInterval: 1.0/Double(framePerSecond), target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
                }
            } else {
                print("stop")
                self.observations = []
                timer?.invalidate()
            }
        }
    }
    
    var framePerSecond = 0 {
        willSet {
            if newValue < 0 {
                self.framePerSecond = 0
            } else {
                self.framePerSecond = min(newValue, maxFramePerSecond)
            }
        }
    }
    
    let maxFramePerSecond = 30
    
    enum Mode {
        case still
        case live
    }
    private let mode: Mode
    

    private var timer: Timer? = nil
    
    init(mode: Mode) {
        self.mode = mode
        Task {
            await handleCameraPreviews()
        }
        
        Task {
            await handleVisionObservations()
        }
    }
    
    
    private func handleCameraPreviews() async {
        for await ciImage in camera.previewStream {
            Task { @MainActor in
                previewImage = ciImage
                
                // Continuous processing
                if isDetecting, framePerSecond <= 0 {
                    vision.processLiveDetection(ciImage)
                }
            }
        }
    }
    
    
    private func handleVisionObservations() async {
        for await observations in vision.observationStream {
            Task { @MainActor in
                if isDetecting || mode == .still{
                    self.observations = observations
                }
            }
        }
    }

    
    // Processing based on FPS specified
    @objc private func timerFired() {
        guard isDetecting, let ciImage = previewImage else {
            return
        }
        vision.processLiveDetection(ciImage)
    }
    
}


