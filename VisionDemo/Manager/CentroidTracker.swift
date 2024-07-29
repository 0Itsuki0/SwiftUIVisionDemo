//
//  TrackingManager.swift
//  VisionDemo
//
//  Created by Itsuki on 2024/07/28.
//

import SwiftUI
import Vision


class CentroidTracker {
    static let maxDisappearedFrameCount: Int = 20
    static let maxNormalizedDistance: CGFloat = 0.2

    // if an object is disappear for frame count greater this, will be deleted
    private var maxDisappearedFrameCount: Int = CentroidTracker.maxDisappearedFrameCount
    // max normalized distance(in an image coordinate space) for an rectangle to be considered a different object
    private var maxNormalizedDistance: CGFloat = CentroidTracker.maxNormalizedDistance
    
    private var nextObjectId: Int = 0

    // currently tracked object
    var objects: [Int: NormalizedRect] = [:]
    
    // temporarily disappeared objects
    // [objectId: frameCountDisappeared]
    var tempDisappearedObjects: [Int: Int] = [:]
    
    // objects in frame
    var objectsInFrame: [Int: NormalizedRect] {
        return objects.filter({!tempDisappearedObjects.filter({$0.value > 0}).keys.contains($0.key)})
    }
    
    
    init(maxDisappearedFrameCount: Int = CentroidTracker.maxDisappearedFrameCount, maxNormalizedDistance: CGFloat = CentroidTracker.maxNormalizedDistance) {
        self.maxDisappearedFrameCount = maxDisappearedFrameCount
        self.maxNormalizedDistance = maxNormalizedDistance
    }
    
    // register a rect as tracked object
    func registerObject(at rect: NormalizedRect) {
        print("registerObject: \(nextObjectId)")
        self.objects[self.nextObjectId] = rect
        self.tempDisappearedObjects[self.nextObjectId] = 0
        self.nextObjectId += 1
    }
    
    // delete an object
    func deRegisterObject(_ objectID: Int) {
        print("deRegisterObject: \(objectID)")
        self.objects.removeValue(forKey: objectID)
        self.tempDisappearedObjects.removeValue(forKey: objectID)
    }
    
    
    // update the current tracked objects with newly observed rects
    func update(rects: [NormalizedRect]) {
        // check to see if the list of input bounding box rectangles is empty
        
        // nothing detected
        // loop over any existing tracked objects and mark them as temporarily disappeared
        if rects.isEmpty {
            print("empty new observations")
            for objectId in self.tempDisappearedObjects.keys {
                if let currentDisappearCount = self.tempDisappearedObjects[objectId] {
                    self.tempDisappearedObjects[objectId] = currentDisappearCount + 1
                    // maximum number of consecutive frames reached where a given object has been marked as disappeared
                    // deregister object
                    if currentDisappearCount + 1 > self.maxDisappearedFrameCount {
                        deRegisterObject(objectId)
                    }
                }
            }
            
            return
        }
        
        
        // currently not tracking any objects
        // register all the inputting rects
        if self.objects.isEmpty {
            print("currently not tracking any objects")
            for rect in rects {
                self.registerObject(at: rect)
            }
            return
        }
        

        // currently tracking objects
        // match the input rect to existing objects
        print("currently tracking")

        let objectIDs: [Int] = Array(self.objects.keys)
        // centroids of the current tracked objects
        let objectCentroids: [CGPoint] = Array(self.objects.values).map({CGPoint(x: $0.cgRect.midX, y: $0.cgRect.midY)})
        
        let rowCount = objectCentroids.count
        let colCount = rects.count
    
        var distanceMatrix: [[CGFloat]] = [[CGFloat]](repeating: [CGFloat](repeating: 0, count: colCount), count: rowCount)
        
        // calculate the distance between each input centroid and tracked centroid
        // for currently tracked i and input j, distance will be computed and stored in distanceMatrix[i][j]
        for i in 0..<rowCount {
            let pointA = objectCentroids[i]
            for j in 0..<colCount {
                let pointB = CGPoint(x: rects[j].cgRect.midX, y: rects[j].cgRect.midY)
                distanceMatrix[i][j] = hypot(pointA.x - pointB.x, pointA.y - pointB.y)
                
            }
        }
        
        // each row represents the distance between a stored object centroid and all inputs
        // minimum value in each row: the nearest input centroid to a store object
        let rowMins: [CGFloat] = distanceMatrix.map({
            $0.min() ?? .greatestFiniteMagnitude
        })
        // Indices that will sort the array above
        // example:
        // for [ 1, -1,  5, -4], sortedIndices will be [3, 1, 0, 2]
        // representing element at index 3 -> (-4) goes first, and then the element at index 1 -> (-1), and so on
        let sortedRowIndices = rowMins.sortedIndices()


        // col index for the min value of each row
        let colIndicesOptionals: [Int?] = distanceMatrix.map({
            if let min = $0.min() {
                $0.firstIndex(of: min)
            } else {
                nil
            }
        })
        if colIndicesOptionals.contains(where: {$0 == nil}) { return }
        let colIndices = colIndicesOptionals.map({$0!})
        
        // sorted col index using sortedRowIndices above
        // ex:
        // sorting [0, 0, 1, 1] with [3, 1, 0, 2] will result in [1, 0, 0, 1]
        guard let sortedColIndices = colIndices.sortBy(by: sortedRowIndices) else {return }
        
        
        // as a result, each (sortedRowIndices, sortedColIndices) pair will represents the smallest possible distance between a tracked object and an input

        
        // usedRows and usedCols to keep track of the rows and column indexes examined
        // we cannot match more than 1 existing object to one input nor vice versa
        var usedRows: [Int] = []
        var usedCols: [Int] = []

        // loop and examine each (sortedRowIndices, sortedColIndices) pair
        for (row, col) in Array(zip(sortedRowIndices, sortedColIndices)) {

            // we have already examined either the row or column before
            // ignore it
            if usedRows.contains(row) || usedCols.contains(col) {
                continue
            }
         
            // the distance between centroids is greater than the maximum allowed distance
            // the input rect and tracked object are not the same object
            if distanceMatrix[row][col] > self.maxNormalizedDistance {
                continue
            }
            
            // object[row] and input[col] are considered to be same object
            // update with the new rect and reset the disappearedFrame counter
            let objectId = objectIDs[row]
            self.objects[objectId] = rects[col]
            self.tempDisappearedObjects[objectId] = 0
            
            // add row and column indexes to examined List
            usedRows.append(row)
            usedCols.append(col)
            
        
        }

        //  row and column index we have NOT yet examined
        let unusedRows = usedRows.difference(Array(0..<rowCount))
        let unusedCols = usedCols.difference(Array(0..<colCount))

        print("used: \(usedRows), \(usedCols)")
        print("leftOvers: \(unusedRows), \(unusedCols)")

        

        // number of tracked object >= number of input rects
        // check if some of the tracked objects have potentially disappeared
        if rowCount >= colCount {
            // increment the disappearedFrame counter for unused rows (currently tracked objects)
            for unusedRow in unusedRows {
                
                let objectId = objectIDs[unusedRow]
                if let currentDisappearCount = self.tempDisappearedObjects[objectId] {
                    self.tempDisappearedObjects[objectId] = currentDisappearCount + 1
                    // maximum number of consecutive frames reached where a given object has been marked as disappeared
                    // deregister object
                    if currentDisappearCount + 1 > self.maxDisappearedFrameCount {
                        deRegisterObject(objectId)
                    }
                }
            }
        } 
        
        // number of input rect > the number of existing object
        else {
            // register each new input rect as an tracked object
            for unusedCol in unusedCols {
                self.registerObject(at: rects[unusedCol])
            }
            
        }
        return
    }
}



extension Collection where Element: Comparable {
    func sortedIndices() -> [Int] {
        return enumerated()
            .sorted{ $0.element < $1.element }
            .map{ $0.offset }
    }
    
}

extension Array where Element: Hashable  {
    func sortBy(by sortOrder: [Int]) -> [Element]?{
        if self.count != sortOrder.count {
            return nil
        }
        var returningElements: [Element?] = [Element?](repeating: nil, count: self.count)
        for index in 0..<sortOrder.count {
            let sort = sortOrder[index]
            returningElements[index] = self[sort]
        }
        if returningElements.contains(where: {$0 == nil}) {
            return nil
        }
        return returningElements.map({$0!})
    }
    
    func difference(_ target: [Element]) -> [Element] {
        let thisSet = Set(self)
        let otherSet = Set(target)
        return Array(thisSet.symmetricDifference(otherSet))
    }

}

