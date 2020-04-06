//
//  AxisGrid.swift
//  ARMeasure
//
//  Created by cc on 8/23/17.
//  Copyright © 2017 Laan Labs. All rights reserved.
//

import Foundation
import SceneKit

class AxisGrid : SCNNode {
    
    
    init(radius : CGFloat = 0.002, height : CGFloat = 0.3) {
        super.init()
        
        let x = SCNCapsule(capRadius: radius, height: height)
        x.firstMaterial?.lightingModel = .constant
        x.firstMaterial?.diffuse.contents = UIColor.red
        let xn = SCNNode(geometry:x)
        xn.position = SCNVector3(height/2.0, 0.0, 0.0)
        xn.eulerAngles.z = 90.0 * Float.pi / 180.0
        self.addChildNode(xn)
        
        let y = SCNCapsule(capRadius: radius, height: height)
        y.firstMaterial?.lightingModel = .constant
        y.firstMaterial?.diffuse.contents = UIColor.green
        let yn = SCNNode(geometry:y)
        yn.position = SCNVector3(0.0, height/2.0, 0.0)
        self.addChildNode(yn)
        
        
        let z = SCNCapsule(capRadius: radius, height: height)
        z.firstMaterial?.lightingModel = .constant
        z.firstMaterial?.diffuse.contents = UIColor.blue
        let zn = SCNNode(geometry:z)
        zn.position = SCNVector3(0.0, 0.0, height/2.0)
        zn.eulerAngles.x = 90.0 * Float.pi / 180.0
        self.addChildNode(zn)
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
