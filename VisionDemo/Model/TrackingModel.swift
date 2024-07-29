//
//  TrackingModel.swift
//  VisionDemo
//
//  Created by Itsuki on 2024/07/28.
//


import SwiftUI
import Vision

struct TrackableObject: Identifiable {
    var id: Int
    var label: String? = nil
    var rect: CGRect
    var firstDetect = Date()
}

class TrackingModel: ObservableObject {
    
    @Published var trackedObjects: [TrackableObject] = []

    let tracker = CentroidTracker(maxDisappearedFrameCount: 20, maxNormalizedDistance: 0.2)

    @Published var isTracking: Bool = false {
        didSet {
            trackedObjects = []
        }
    }

    private var isProcessing: Bool = false
    private let thresholdConfidence: Float = 0.6
    
    
    @MainActor
    func tracking(_ data: Data, size: CGSize) async {
        if isProcessing || !isTracking {return}
        isProcessing = true
        defer {
            isProcessing = false
        }
        
        print("processing")
        var request = DetectTextRectanglesRequest()
        request.regionOfInterest = .fullImage
        
        do {
            let results = try await request.perform(on: data)
            let rects = results.filter({$0.confidence > thresholdConfidence}).map({$0.boundingBox})
            tracker.update(rects: rects)
            let updatedTrackedObjects = tracker.objects
            let objectsInFrame = tracker.objectsInFrame
            print("objectsInFrame: \(updatedTrackedObjects)")

            trackedObjects.removeAll(where: {!updatedTrackedObjects.keys.contains($0.id)})

            
            for object in updatedTrackedObjects {
                
                let firstTrackedIndex = trackedObjects.firstIndex(where: {$0.id == object.key})
               
                if !objectsInFrame.contains(where: {$0.key == object.key}) {
                    print("temporarily not in frame: \(object.key)")
                    if let firstTrackedIndex = firstTrackedIndex {
                        self.trackedObjects[firstTrackedIndex].rect = .zero
                    }
                    continue
                }

                // convert normalized rect to imageCoordinate
                let convertedRect = object.value.toImageCoordinates(size, origin: .upperLeft)

                
                if firstTrackedIndex == nil {
                    print("not tracked: adding \(object.key)")
                    self.trackedObjects.append(TrackableObject(id: object.key, rect: convertedRect))
                    
                    // getting label after added to trackedObjects
                    getLabel(data, targetRect: object.value, objectId: object.key)

                } else {
                    print("tracked: updating \(object.key)")
                    self.trackedObjects[firstTrackedIndex!].rect = convertedRect
                }
            }
        
        } catch(let error) {
            print("error recognizing text: \(error.localizedDescription)")
        }

    }
    
    
    
    private func getLabel(_ data: Data, targetRect: NormalizedRect, objectId: Int) {
        guard let firstIndex = trackedObjects.firstIndex(where: {$0.id == objectId}) else {return}
        var request = RecognizeTextRequest()
        request.recognitionLanguages = [Locale.Language.init(identifier: "en-US")]
        request.automaticallyDetectsLanguage = false
        request.regionOfInterest = targetRect
        request.usesLanguageCorrection = true
        
        Task { [request, firstIndex] in
            
            let results = try? await request.perform(on: data)
            
            let label = results?.filter({$0.confidence > self.thresholdConfidence}).first?.topCandidates(1).first?.string
            
            DispatchQueue.main.async {
                self.trackedObjects[firstIndex].label = label
            }
        }
    }
}
