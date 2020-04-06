//
//  ARBodyUtils.swift
//  ARBodyPoseRecorder
//
//  Created by cc on 4/6/20.
//  Copyright © 2020 Laan Labs. All rights reserved.
//

import Foundation
import ARKit


class ARBodyUtils {
    
    

    static var selectedJointNames:[ARSkeleton.JointName] = [.head,
                                                     
                                                     .leftFoot,
                                                     .rightFoot,
                                                     
                                                     .rightHand,
                                                     .leftHand,
                                                     .leftShoulder,
                                                     .rightShoulder,
                                                     
                                                     .init(rawValue: "left_forearm_joint"),
                                                     .init(rawValue: "right_forearm_joint"),
                                                     
                                                     .init(rawValue: "left_leg_joint"),
                                                     .init(rawValue: "right_leg_joint"),
                                                     
                                                     .init(rawValue: "left_upLeg_joint"),
                                                     .init(rawValue: "right_upLeg_joint"),
                                                     
                                                     .init(rawValue: "left_toes_joint"),
                                                     .init(rawValue: "right_toes_joint"),
                                                     
                                                     
                                                     
                                                     //ARSkeleton.JointName(rawValue: "left_eyeball_joint"),
                                                     //ARSkeleton.JointName(rawValue: "right_eyeball_joint"),
                                                     
    ]
    
    static func colorForJointName( _ name : String ) -> UIColor {
        if name.contains("left") {
            return UIColor.green
        } else {
            return UIColor.blue
        }
        
    }
    
    
    static var allJoints : [ARSkeleton.JointName] = {
        
        print(" -__________ get joints ________ ")
        
        var joints : [ARSkeleton.JointName] = []
        
        for jointName in ARSkeletonDefinition.defaultBody3D.jointNames {
            joints.append(.init(rawValue: jointName))
        }
        
        return joints
        
    }()

    static var colors : [UIColor] = [.cyan, .orange, .orange, .magenta, .magenta,
                                      .blue, .blue, .yellow, .yellow, .green, .green, .red, .red, .gray, .gray]

    static func getJointPositionsDict( body : ARBodyAnchor ) -> [String: SCNMatrix4] {
        
        return ["Fart" : SCNMatrix4Identity ]
        
    }
    
    
    
}

