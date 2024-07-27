//
//  VisionManager.swift
//  VisionKitDemo
//
//  Created by Itsuki on 2024/07/26.
//

import SwiftUI
import Vision


class VisionManager {

    private var requests: [any VisionRequest] = []
    private var isProcessing: Bool = false
    
    private var addToObservationStream: (([any VisionObservation]) -> Void)?
    
    lazy var observationStream: AsyncStream<[any VisionObservation]> = {
        AsyncStream { continuation in
            addToObservationStream = { observations in
                continuation.yield(observations)
            }
        }
    }()
    
    
    init() {
        var request = RecognizeTextRequest()
        request.recognitionLanguages = [Locale.Language.init(identifier: "en-US"), Locale.Language.init(identifier: "ja-JP")]
        self.requests = [request]
    }
    
    
    // MARK: For Still Image Processing
    func detectText(_ data: Data) async {
        var request = RecognizeTextRequest()
        request.recognitionLanguages = Locale.Language.systemLanguages
        
        do {
            let results = try await request.perform(on: data)
            addToObservationStream?(results)
            
        } catch(let error) {
            print("error recognizing text: \(error.localizedDescription)")
        }
    }
    
    
    func detectBarcode(_ data: Data) async {
        var request = DetectBarcodesRequest()
        request.symbologies = [.qr]

        do {
            let results = try await request.perform(on: data)
            addToObservationStream?(results)
        } catch(let error) {
            print("error recognizing barcode: \(error.localizedDescription)")
        }
    }
    
    
    func detectBarcodeAndText(_ data: Data) async {
        var textRequest = RecognizeTextRequest()
        textRequest.recognitionLanguages = [Locale.Language.init(identifier: "en-US")]

        var barcodeRequest = DetectBarcodesRequest()
        barcodeRequest.symbologies = [.qr]
        
        let requests: [any VisionRequest] = [textRequest, barcodeRequest]
        
        let imageRequestHandler = ImageRequestHandler(data)
        let results = imageRequestHandler.performAll(requests)
        
        await handleVisionResults(results: results)
    }
    
    
    // MARK: For Live Capture Processing
    func processLiveDetection(_ ciImage: CIImage) {
        if isProcessing { return }
        isProcessing = true

        Task {
            let imageRequestHandler = ImageRequestHandler(ciImage)
            let results = imageRequestHandler.performAll(self.requests)

            await handleVisionResults(results: results)
            isProcessing = false
        }
    }

    
    // MARK: Process Results
    private func handleVisionResults(results: some AsyncSequence<VisionResult, Never>) async  {
        var newObservations: [any VisionObservation] = []
        
        for await result in results {
            switch result {
            case .recognizeText(_, let observations):
                print("text")
                newObservations.append(contentsOf: observations)
            case .detectBarcodes(_, let observations):
                print("barcode")
                newObservations.append(contentsOf: observations)
            default:
                return
            }
        }
        addToObservationStream?(newObservations)
    }

    
    // MARK: Process Observations
    func processObservation(_ observation: any VisionObservation, for imageSize: CGSize) -> (text: String, confidence: Float, size: CGSize, position: CGPoint) {
        switch observation {
        case is RecognizedTextObservation:
            return processTextObservation(observation as! RecognizedTextObservation, for: imageSize)
        case is BarcodeObservation:
            return processBarcodeObservation(observation as! BarcodeObservation, for: imageSize)
        default:
            return ("", .zero, .zero, .zero)
        }
    }

    private func processTextObservation(_ observation: RecognizedTextObservation, for imageSize: CGSize) -> (text: String, confidence: Float, size: CGSize, position: CGPoint) {
        let recognizedText = observation.topCandidates(1).first?.string ?? ""
        let confidence = observation.topCandidates(1).first?.confidence ?? 0.0
       
        let boundingBox = observation.boundingBox
        let converted = boundingBox.toImageCoordinates(imageSize, origin: .upperLeft)

        let position = CGPoint(x: converted.midX, y: converted.midY)

        return (recognizedText, confidence, converted.size, position)
    }
    
    
    private func processBarcodeObservation(_ observation: BarcodeObservation, for imageSize: CGSize) -> (text: String, confidence: Float, size: CGSize, position: CGPoint) {
        let recognizedText = observation.payloadString ?? "Payload String not available"
        let confidence = observation.confidence
       
        let boundingBox = observation.boundingBox
        let converted = boundingBox.toImageCoordinates(imageSize, origin: .upperLeft)
        
        let position = CGPoint(x: converted.midX, y: converted.midY)
        
        return (recognizedText, confidence, converted.size, position)
        
    }
    
}
