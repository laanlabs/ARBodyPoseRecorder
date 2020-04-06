//
//  SKLine.swift
//  ARMeasure
//
//  Created by cc on 8/7/17.
//  Copyright © 2017 Laan Labs. All rights reserved.
//

import Foundation
import SceneKit

/*
 A stupid subclass.
 */
@available(iOS 11.0, *)
class SKLine : SCNNode {
    
    private var _startPos = SCNVector3Zero
    private var _endPos = SCNVector3Zero
    
    var capsule : SCNCapsule! = nil
    var capsuleNode : SCNNode! = nil
    private var _color = UIColor.white
    
    init(radius : Float = 0.01, color: UIColor = .white) {
        super.init()
        
        self.capsule = SCNCapsule(capRadius: CGFloat(radius), height: 1.0)
        
        capsule.capSegmentCount = 10 // default 24
        capsule.radialSegmentCount = 10 // default 48
        capsule.heightSegmentCount = 1 // default = 1
        
        capsuleNode = SCNNode(geometry: self.capsule)
        capsuleNode.eulerAngles.x = Float.pi * 0.5
        capsule.firstMaterial?.lightingModel = .constant
        
        self.addChildNode(capsuleNode)
        self.color = color

    }
    
    var endArrowNode : SCNNode! = nil
    var hasEndArrow : Bool = false {
        didSet {
            if hasEndArrow {
                if endArrowNode == nil {
                    let cone = SCNCone(topRadius: 0, bottomRadius: 1.0, height: 1.0)
                    cone.firstMaterial?.diffuse.contents = self.color
                    let coneParent = SCNNode(geometry: cone)
                    endArrowNode = SCNNode()
                    endArrowNode.addChildNode(coneParent)
                    coneParent.eulerAngles.x = -Float.pi * 0.5
                }
                self.addChildNode(endArrowNode)
                self.update()
            } else {
                self.endArrowNode?.removeFromParentNode()
            }
            
        }
    }

    convenience init(radius: Float = 0.01, color: UIColor = .white, start: SCNVector3, end: SCNVector3) {
        self.init(radius: radius, color: color)
        startPos = start
        endPos = end
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var color: UIColor {
        get {
            return _color
        }
        set {
            _color = newValue
            capsuleNode.geometry?.firstMaterial?.diffuse.contents = _color
        }
    }
    
    var startPos: SCNVector3 {
        get {
            return _startPos
        }
        set {
            _startPos = newValue
            self.update()
        }
    }
    
    var endPos: SCNVector3 {
        get {
            return _endPos
        }
        set {
            _endPos = newValue
            self.update()
        }
    }

    var length: Float {
        return _endPos.distance(startPos)
    }

    private func update() {

        let p1 = self.startPos
        let p2 = self.endPos
    
        let origin = (p1 + p2 ) / 2.0
        let len = (p1 - p2).length()
        
        capsule.height = CGFloat(len)
        //self.position = origin
        self.worldPosition = origin
        
        self.look(at: p2)
        
        // start arrow would be z + len*0.5
        //self.endArrowNode?.position = SCNVector3(0.0, 0.0, -len * 0.5)
        // TODO: arrow backwards on z axis ...
        self.endArrowNode?.worldPosition = p2
        self.endArrowNode?.scale = .one * Float(self.capsule.capRadius) * 5.0
        //self.endArrowNode?.look(at: origin)
        
    }



}

