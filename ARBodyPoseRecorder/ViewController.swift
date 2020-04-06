//
//  ViewController.swift
//  ARPoseRecord
//
//  Created by cc on 9/6/19.
//  Copyright © 2019 Laan Labs. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, RecorderDelegate {
    
    func recorder(didEndRecording path: URL, with noError: Bool) {
        print("recorder(didEndRecording")
    }
    
    func recorder(didFailRecording error: Error?, and status: String) {
        print("recorder(didFailRecording")
        self.alert("Recording had an error")
    }
    

    @IBOutlet var sceneView: ARSCNView!
    
    var isRecording : Bool = false
    
    
    var recorder : VideoRecorder?
    
    //let recorderQueue = DispatchQueue(label:"com.labs.recorder_queue")
    let recorderQueue = DispatchQueue(label: "com.labs.recorder_queue", qos: .userInitiated)
    
    var currentVideoURL: URL?
    var currentProjectURL: URL?
    
    let recordButton = UIButton()
    
    var currentFrameIndex : Int = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false
        
        sceneView.autoenablesDefaultLighting = true
        
        // Create a new scene
        //let scene = SCNScene(named: "art.scnassets/ship.scn")!
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        sceneView.preferredFramesPerSecond = 30
        
        recordButton.frame = .init(x: 0, y: 0, width: 80, height: 80)
        recordButton.layer.cornerRadius = 40
        recordButton.backgroundColor = UIColor.white
        
        self.sceneView.addSubview(recordButton)
        recordButton.addTarget(self, action: #selector(recordButtonTapped), for: .touchUpInside)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        //let configuration = ARWorldTrackingConfiguration()

        
        
        let configuration = ARBodyTrackingConfiguration()
        
        configuration.environmentTexturing = .none
        
        configuration.isAutoFocusEnabled = true

        guard ARBodyTrackingConfiguration.isSupported else {
            fatalError("This feature is only supported on devices with an A12 chip")
        }
        
        
    
        // Run the view's session
        sceneView.session.run(configuration)
        sceneView.session.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func viewDidLayoutSubviews() {
        self.recordButton.center = .init(x: self.view.bounds.width * 0.5, y: self.view.bounds.height - 90 )
    }
    
    @objc func recordButtonTapped() {
        
       
        self.recorderQueue.async {
            
            if self.isRecording {
                
                self.isRecording = false
                self.stopRecord()
                
                Haptics.threeWeakBooms()
                
            } else {
                
                Haptics.strongBoom()
                
                
                if let frame = self.sceneView.session.currentFrame,
                    let projectUrl = self.getNewProjectUrl() {
                    
                    let buffer = frame.capturedImage
                    
                    let w = CVPixelBufferGetWidth(buffer)
                    let h = CVPixelBufferGetHeight(buffer)
                    
                    //let videoUrl = self.getNewTempVideoUrl()
                    
                    self.currentProjectURL = projectUrl
                    
                    let videoUrl = projectUrl.appendingPathComponent("video.mp4")
                    
                    self.currentVideoURL = videoUrl
                    self.currentFrameIndex = 0
                    
                    self.recorder = VideoRecorder(output: videoUrl, width: w, height: h,
                                                  adjustForSharing: false, queue: self.recorderQueue)
                    
                    self.isRecording = true
                    
                    DispatchQueue.main.async {
                        self.recordButton.backgroundColor = UIColor.red
                    }
                    
                    
                }
                
            }
            
        }
        
    }
    
    func stopRecord() {
        
        self.isRecording = false
        self.currentFrameIndex = 0
        self.recorder?.end {
            self.recorder = nil
            
            DispatchQueue.main.async {
                self.recordButton.backgroundColor = UIColor.white
            }
            
        }
            
    }
    
    
    func getNewProjectUrl() -> URL? {
                
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .full
        formatter.dateFormat = "yyyy_MM_dd_HH_mm_ss"
        
        let projectName = formatter.string(from: Date() )
        //let projectName = UUID().uuidString
        
        let projectUrl = URL.documentsDirectory().appendingPathComponent(projectName)
        
        
        if !FileManager.default.fileExists(atPath: projectUrl.path) {
            do {
                try FileManager.default.createDirectory(atPath: projectUrl.path, withIntermediateDirectories: false, attributes: nil)
            } catch {
                self.alert("Could not create project folder")
                return nil
            }
        }
        
        return projectUrl
        
    }
    
    
    // MARK: - ARSCNViewDelegate
    
    func saveMetadata( frame : ARFrame, time : CFTimeInterval, frameIndex : Int ) {
        
        var jsonDict : [String: Any] = [:]
        
        let pose_sk = self.sceneView.pointOfView!.transform
        
        let cam_k = frame.camera.intrinsics
        let proj = frame.camera.projectionMatrix
        let pose_frame = frame.camera.transform
        
        //let tracking = frame.camera.trackingState // how do we turn into string?
        
        jsonDict["frame_index"] = frameIndex
        jsonDict["time"] = time
        jsonDict["cameraPoseScenekit"] = pose_sk.rowMajorArray
        jsonDict["cameraPoseARFrame"] = pose_frame.rowMajorArray
        jsonDict["intrinsics"] = cam_k.rowMajorArray
        jsonDict["projectionMatrix"] = proj.rowMajorArray
        
        //jsonDict["isARKitTrackingNormal"] = (tracking == ARCamera.TrackingState.normal)
        
        
        var joints : [String : Any] = [:]
        
        if let frame = self.sceneView.session.currentFrame,
            let bodyAnchor = frame.anchors.filter({ $0 is ARBodyAnchor }).first as? ARBodyAnchor {
            
            joints["bodyAnchor"] = bodyAnchor.transform.rowMajorArray
            
            joints["estimatedScaleFactor"] = bodyAnchor.estimatedScaleFactor
            joints["isTracked"] = bodyAnchor.isTracked
            
            for joint in ARBodyUtils.allJoints {
                if let transform = bodyAnchor.skeleton.modelTransform(for: joint) {
                    joints[joint.rawValue] = transform.rowMajorArray
                }
            }
            
        }
        
        jsonDict["bodyData"] = joints
        
        //let fileUrl = URL.documentsDirectory().appendingPathComponent("frame_%05d.json".format(frameIndex))
        
        if let projectURL = self.currentProjectURL {
            let fileUrl = projectURL.appendingPathComponent("frame_%05d.json".format(frameIndex))
            saveJsonFile(fileUrl: fileUrl, jsonDict: jsonDict)
        }
        
        
    }
    
    // TODO: error handle
    func saveJsonFile( fileUrl : URL , jsonDict : [String : Any] ) {
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: jsonDict, options: [.prettyPrinted] )
        {
            try! jsonData.write(to: fileUrl )
        } else {
            print("err saving")
        }

        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        if self.isRecording {
            
            self.recorderQueue.async {
                
                if let recorder = self.recorder,
                    let frame = self.sceneView.session.currentFrame {
                    let buffer = frame.capturedImage
                    
                    var time2: CFTimeInterval { return CACurrentMediaTime()}
                    
                    let addedFrame = recorder.insert(pixel: buffer, with: time2)
                    
                    if addedFrame {
                        self.saveMetadata(frame: frame, time: time2, frameIndex: self.currentFrameIndex)
                        self.currentFrameIndex += 1
                    }
                    
                    guard let isWriting = recorder.isWritingWithoutError else { return }
                    
                    if !isWriting {
                        self.isRecording = false
                        self.stopRecord()
                    }
                    
                }
                
            }
            
        }
        
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    
    // MARK: - ARBodyAnchor
    
    
    let parentNode = SCNNode()
    var sphereNodes:[SCNNode] = []
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {

        for anchor in anchors {
            
            guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }
             
            //let bodyPosition = simd_make_float3(bodyAnchor.transform.columns.3)
            
            parentNode.transform = SCNMatrix4.init(bodyAnchor.transform)
            
            let joints = ARBodyUtils.selectedJointNames
            //let joints = ARBodyUtils.allJoints
            
            if sphereNodes.count == 0 {
                
                // create joints
                 self.sceneView.scene.rootNode.addChildNode(parentNode)
                 
                 for  i in 0..<joints.count {
                     
//                    let boxSize : CGFloat = 0.05
//                    let sphereNode = SCNNode(geometry:
//                        SCNBox(width: boxSize*2.4, height: boxSize, length: boxSize, chamferRadius: 0) )
//
//                    sphereNode.geometry?.firstMaterial?.diffuse.contents =
//                        ARBodyUtils.colorForJointName(joints[i].rawValue)
                    
                    let sphereNode = SCNNode()
                    sphereNode.showAxes(radius: 0.0085, height: 0.13)
                    
                     parentNode.addChildNode(sphereNode)
                     sphereNodes.append(sphereNode)
                     
                 }
                
            }
            
            for  i in 0..<joints.count {
                
                if let transform = bodyAnchor.skeleton.modelTransform(for: joints[i]) {
                    
                    //let position = bodyPosition + simd_make_float3(transform.columns.3)
                    //sphereNodes[i].position = SCNVector3(position.x, position.y, position.z)
                    
                    sphereNodes[i].transform = SCNMatrix4.init(transform)
                    
                }
            }
            
        }
        
    }
    
    
    // MARK: - Alert
    
    func alert(_ msg : String) {
        let alert = UIAlertController(title: "Alert", message: msg, preferredStyle: .alert)
        self.present(alert, animated: true)
        
    }
    
}
