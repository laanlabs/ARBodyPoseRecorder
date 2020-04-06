//
//  ARPointCloudSimple.swift
//  FritzImageSegmentationDemo
//
//  Created by cc on 5/18/19.
//  Copyright © 2019 Fritz. All rights reserved.
//

import Foundation
import SceneKit
import ARKit



class ARPointCloudSimple {
    
    var points : [SCNVector3] = []
    var updateFrequencyMs : Double = 200.0
    
    
    private var pointCounts : [UInt64 : UInt64] = [:]
    private var pointIndices : [UInt64 : Int] = [:]
    
    private let pointLock = NSLock()
    
    private var lastUpdate = Date.distantPast
    
    
    
    
    func lock() {
        self.pointLock.lock()
    }
    func unlock() {
        self.pointLock.unlock()
    }
    
    func update( _ frame : ARFrame ) {
        
        if lastUpdate.millisecondsAgo < updateFrequencyMs { return; }
        
        self.lock()
        
        lastUpdate = Date()
        
        if let pts = frame.rawFeaturePoints {
            
            for idx in 0..<pts.points.count {
                
                let id = pts.identifiers[idx]
                let pt = SCNVector3(pts.points[idx])
                
                var count = pointCounts[id] ?? 0
                count += 1
                
                pointCounts[id] = count
                
                if count == 3 {
                    
                    // Add it
                    pointIndices[id] = points.count
                    points.append(pt)
                    
                } else if count > 3 {
                    
                    // Update it
                    if let pidx = pointIndices[id] {
                        points[pidx] = pt
                    }
                    
                }
                
            }
            
            
        } // end if let pts
        
        self.unlock()
        
    }
    
    
    
}
