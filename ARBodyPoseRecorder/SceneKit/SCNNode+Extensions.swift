//
//  SCNNode+Extensions.swift
//  ARMeasure
//
//  Created by William Perkins on 8/14/17.
//  Copyright © 2017 Laan Labs. All rights reserved.
//

import SceneKit

extension SCNBoundingVolume {
    // Returns a point at a specified normalized location within the bounds of the volume, where 0 is min and 1 is max.
    func pointInBounds(at normalizedLocation: SCNVector3) -> SCNVector3 {
        let boundsSize = boundingBox.max - boundingBox.min
        let locationInPoints = boundsSize * normalizedLocation
        return locationInPoints + boundingBox.min
    }
}

// recursive set categoryBitMask to 2
@available(iOS 11.0, *)
extension SCNNode {
    
    func setHighlighted(_ highlighted : Bool = true) {
        var node = self
        node.categoryBitMask = highlighted ? 2 : 1
        for child in node.childNodes {
            child.setHighlighted(highlighted)
        }
    }
    
    func showAxes(radius : CGFloat = 0.002, height : CGFloat = 0.3) {
        self.addChildNode(AxisGrid(radius:radius, height:height))
    }
    
    func setAxesTransform( newX : SCNVector3 ,
                           newY : SCNVector3 ,
                           newZ : SCNVector3 ,
                           position : SCNVector3 = .zero ) {
        
        let transform = SCNMatrix4.init(m11: newX.x, m12: newX.y, m13: newX.z, m14: 0,
                                        m21: newY.x, m22: newY.y, m23: newY.z, m24: 0,
                                        m31: newZ.x, m32: newZ.y, m33: newZ.z, m34: 0,
                                        m41: position.x, m42: position.y, m43: position.z, m44: 1.0)
        self.transform = transform
        
    }
    
}
