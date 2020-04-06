//
//  SCNPointCloud.swift
//  3DPhotoService
//
//  Created by cc on 9/16/18.
//  Copyright © 2018 laan labs. All rights reserved.
//

import Foundation
import SceneKit

struct PointCloudVertex {
    var x: Float, y: Float, z: Float
    var r: Float, g: Float, b: Float
}


class SCNPointCloud: SCNNode {
    
    
    convenience init( points : [SCNVector3] ) {
        self.init()
        self.geometry = SCNPointCloud.buildGeom(points: points)
    }
    
    convenience init( points : [PointCloudVertex] ) {
        self.init()
        self.geometry = SCNPointCloud.buildGeom(points: points)
    }
    
    
    // No colors
    static func buildGeom( points: [SCNVector3]  ) -> SCNGeometry {
        
        let positionSource = SCNGeometrySource(vertices: points)
        
        let elements = SCNGeometryElement(
            data: nil,
            primitiveType: .point,
            primitiveCount: points.count,
            bytesPerIndex: MemoryLayout<Int>.size
        )
        
        elements.pointSize = 2.5
        elements.minimumPointScreenSpaceRadius = 0.5
        elements.maximumPointScreenSpaceRadius = 3.0
        
        
        let pointsGeometry = SCNGeometry(sources: [positionSource], elements: [elements])
        
        pointsGeometry.firstMaterial?.lightingModel = .constant
        
        return pointsGeometry
    }
    
    
    static func buildGeom( points: [PointCloudVertex] ) -> SCNGeometry {
        
        let vertexData = NSData(
            bytes: points,
            length: MemoryLayout<PointCloudVertex>.size * points.count
        )
        
        let positionSource = SCNGeometrySource(
            data: vertexData as Data,
            semantic: SCNGeometrySource.Semantic.vertex,
            vectorCount: points.count,
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<PointCloudVertex>.size
        )
        
        let colorSource = SCNGeometrySource(
            data: vertexData as Data,
            semantic: SCNGeometrySource.Semantic.color,
            vectorCount: points.count,
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: MemoryLayout<Float>.size * 3,
            dataStride: MemoryLayout<PointCloudVertex>.size
        )
        let elements = SCNGeometryElement(
            data: nil,
            primitiveType: .point,
            primitiveCount: points.count,
            bytesPerIndex: MemoryLayout<Int>.size
        )
        
        elements.pointSize = 2.0
        elements.minimumPointScreenSpaceRadius = 1.0
        elements.maximumPointScreenSpaceRadius = 5.0
        
        let pointsGeometry = SCNGeometry(sources: [positionSource, colorSource], elements: [elements])
        pointsGeometry.firstMaterial?.lightingModel = .constant
        
        return pointsGeometry
    }
    
    
    
}
