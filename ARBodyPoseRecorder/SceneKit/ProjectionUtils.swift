//
//  ProjectionUtils.swift
//  ScannerPro
//
//  Created by cc on 8/15/18.
//  Copyright © 2018 Laan Labs. All rights reserved.
//

import Foundation
import simd
import SceneKit
import ARKit


struct HitTestRay {
    let origin: SCNVector3
    let direction: SCNVector3
}


struct CameraView {
    
    let projectionMatrix : GLKMatrix4
    let modelViewMatrix : GLKMatrix4
    let imageWidth : Int
    let imageHeight : Int
    let cameraDirection : SCNVector3
    let cameraPosition : SCNVector3
    
    let inverseProjViewMat : matrix_float4x4
    
    let cameraPose : SCNMatrix4
    
    init(projectionMatrix : GLKMatrix4,
         modelViewMatrix : GLKMatrix4,
         cameraDirection: SCNVector3,
         cameraPosition: SCNVector3,
         cameraPose : SCNMatrix4,
         imageWidth : Int,
         imageHeight : Int) {
        
        self.projectionMatrix = projectionMatrix
        self.modelViewMatrix = modelViewMatrix
        
        self.cameraPose = cameraPose
        
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        
        self.cameraDirection = cameraDirection
        self.cameraPosition = cameraPosition
        
        let projMat : matrix_float4x4 = matrix_float4x4.init( SCNMatrix4FromGLKMatrix4(projectionMatrix))
        let viewMat : matrix_float4x4 = matrix_float4x4.init( SCNMatrix4FromGLKMatrix4(modelViewMatrix))
        
        self.inverseProjViewMat = (projMat * viewMat).inverse
        
//        let cam = SCNMatrix4FromGLKMatrix4(modelViewMatrix)
//
//        self.cameraDirection = SCNVector3(1.0 * cam.m31,
//                                          1.0 * cam.m32,
//                                          -1.0 * cam.m33)
        
        
    }
    
    }




extension ARSCNView {
    
    

    
    func hitTestRayFromScreenPos(_ point: CGPoint) -> HitTestRay? {
        
        guard let frame = self.session.currentFrame else {
            return nil
        }
        
        let cameraPos = frame.camera.transform.position
        
        // Note: z: 1.0 will unproject() the screen position to the far clipping plane.
        let positionVec = SCNVector3(x: Float(point.x), y: Float(point.y), z: 1.0)
        let screenPosOnFarClippingPlane = self.unprojectPoint(positionVec)
        
        var rayDirection = screenPosOnFarClippingPlane - cameraPos
        rayDirection.normalize()
        
        return HitTestRay(origin: cameraPos, direction: rayDirection)
    }
    

    func projectToCGPoint( _ p3d : SCNVector3 ,
                           withinFrame : CGRect? = nil ,
                           tolerance : CGFloat = 1.0 ) -> CGPoint? {
        
        let p3d = self.projectPoint(p3d)
        
        if p3d.z > 1.01 || p3d.z < -0.01  {
            return nil
        }
        
        let p1 = CGPoint.init(x: CGFloat(p3d.x), y: CGFloat(p3d.y))
        
        guard let frame = withinFrame else { return p1 }
        
        let b1 : CGFloat = -tolerance
        let vw = frame.width + tolerance
        let vh = frame.height + tolerance
        
        if p1.x < b1 || p1.y < b1 || p1.x > vw || p1.y > vh  {
            return nil
        }
        
        return p1
        
    }

    func viewToImage(point: CGPoint,
                     orientation : UIInterfaceOrientation = .portrait ) -> CGPoint? {
        
        var outPoint : CGPoint
        
        let sceneFrame = self.bounds
        
        // normalize
        let t = CGAffineTransform(scaleX: 1.0 / sceneFrame.size.width, y: 1.0 / sceneFrame.size.height)
        outPoint = point.applying(t)
        
        // Transfrom the rect from view space to image space
        guard let fromViewToCameraImageTransform = self.session.currentFrame?.displayTransform(for: orientation, viewportSize: sceneFrame.size).inverted() else {
            return nil
        }
        
        outPoint = outPoint.applying(fromViewToCameraImageTransform)
        
        //outPoint.y = 1 - outPoint.y   // Image space uses bottom left as origin while view space uses top left
        
        guard let frame = self.session.currentFrame?.capturedImage else { return nil }
        
        
        let bufferW = CVPixelBufferGetWidth(frame)
        let bufferH = CVPixelBufferGetHeight(frame)
        
        let t2 = CGAffineTransform(scaleX: CGFloat(bufferW), y: CGFloat(bufferH))
        outPoint = outPoint.applying(t2)
        
        
        return outPoint
        
        
    }
    
    func viewToImage(rect: CGRect) -> CGRect? {
        
        var outRect : CGRect
        let sceneFrame = self.bounds
        
        // normalize
        let t = CGAffineTransform(scaleX: 1.0 / sceneFrame.size.width, y: 1.0 / sceneFrame.size.height)
        outRect = rect.applying(t)
        
        // Transfrom the rect from view space to image space
        guard let fromViewToCameraImageTransform = self.session.currentFrame?.displayTransform(for: UIInterfaceOrientation.portrait, viewportSize: sceneFrame.size).inverted() else {
            return nil
        }
        
        outRect = outRect.applying(fromViewToCameraImageTransform)
        
        //outPoint.y = 1 - outPoint.y   // Image space uses bottom left as origin while view space uses top left
        
        guard let frame = self.session.currentFrame?.capturedImage else { return nil }
        
        
        let bufferW = CVPixelBufferGetWidth(frame)
        let bufferH = CVPixelBufferGetHeight(frame)
        
        let t2 = CGAffineTransform(scaleX: CGFloat(bufferW), y: CGFloat(bufferH))
        outRect = outRect.applying(t2)
        
        
        return outRect
        
        
    }
    
    
    func imageToView(point: CGPoint,
                     _sceneSize : CGSize? = nil,
                     orientation : UIInterfaceOrientation = .portrait) -> CGPoint? {
        
        var outPoint : CGPoint = point
        
        var sceneSize : CGSize = _sceneSize ?? self.bounds.size 
        
        //let sceneSize = self.bounds
        
        guard let frame = self.session.currentFrame?.capturedImage else { return nil }
        
        let bufferW = CVPixelBufferGetWidth(frame)
        let bufferH = CVPixelBufferGetHeight(frame)
        
        let t2 = CGAffineTransform(scaleX: 1.0 / CGFloat(bufferW), y: 1.0 / CGFloat(bufferH))
        outPoint = outPoint.applying(t2)
        
        
        // Transfrom the rect from image space to view space
        //point.y = 1 - point.y
        guard let fromCameraImageToViewTransform = self.session.currentFrame?.displayTransform(for: orientation, viewportSize: sceneSize) else {
            return nil
        }
        
        outPoint = outPoint.applying(fromCameraImageToViewTransform)
        let t = CGAffineTransform(scaleX: sceneSize.width, y: sceneSize.height)
        outPoint = outPoint.applying(t)
        return outPoint
        
    }
    
    
    func getCameraView(useFrame:ARFrame?=nil) -> CameraView? {
        
        guard var frame = self.session.currentFrame else { return nil }
        guard let camPos = self.pointOfView?.position else { return nil }
        
        if useFrame != nil { frame = useFrame! }
        
        let viewMat = frame.camera.viewMatrix(for: .landscapeRight) // world space to camera space
        let projMat = frame.camera.projectionMatrix // matrix_float4x4
        
        let camPoseSK = SCNMatrix4.init(frame.camera.transform)
        
        let viewMatGLK  = SCNMatrix4ToGLKMatrix4(SCNMatrix4.init(viewMat))
        let projMatGLK = SCNMatrix4ToGLKMatrix4(SCNMatrix4.init(projMat))
        
        //let intrinsics = frame.camera.intrinsics
        //let camMat = frame.camera.transform
        
        //let invProjView = (projMat * viewMat).inverse
        
        //let camPos = camPoseSK.translation
        let camDir = SCNVector3(-1 * camPoseSK.m31,
                                -1 * camPoseSK.m32,
                                -1 * camPoseSK.m33).normalized()
        
        //let imagePoint = self.pointer.viewToImage(point: screenPoint)!
        
        let w = Int(frame.camera.imageResolution.width)
        let h = Int(frame.camera.imageResolution.height)
        
        return CameraView(projectionMatrix : projMatGLK,
                          modelViewMatrix : viewMatGLK,
                          cameraDirection: camDir,
                          cameraPosition: camPos,
                          cameraPose: camPoseSK,
                          imageWidth : w,
                          imageHeight : h)
        
    }
    
}




/*
struct CameraView {
    let inverseProjViewMat : matrix_float4x4
    let cameraPosition : SCNVector3
    let imageWidth : Float
    let imageHeight : Float
}
*/
/*

func getCameraView() -> CameraView? {
    
    guard let frame = self.sceneView.session.currentFrame else { return nil }
    guard let camPos = self.sceneView.pointOfView?.position else { return nil }
    
    //guard let projMat = self.sceneView.pointOfView?.camera?.projectionTransform else { return }
    //guard let camTransform = self.sceneView.pointOfView?.worldTransform else { return }
    
    let viewMat = frame.camera.viewMatrix(for: .landscapeRight) // world space to camera space
    let projMat = frame.camera.projectionMatrix // matrix_float4x4
    //let intrinsics = frame.camera.intrinsics
    //let camMat = frame.camera.transform
    
    let invProjView = (projMat * viewMat).inverse
    
    //let imagePoint = self.pointer.viewToImage(point: screenPoint)!
    
    let w = Float(frame.camera.imageResolution.width)
    let h = Float(frame.camera.imageResolution.height)
    
    return CameraView(inverseProjViewMat: invProjView, cameraPosition: camPos, imageWidth: w, imageHeight: h)
    
}
*/


func hitTestRayFromImagePosAndCamerView( _ imagePoint : CGPoint , view : CameraView ) -> HitTestRay? {
    
    let screenPosOnFarClippingPlane = unprojectPoint(point: SCNVector3(imagePoint.x, imagePoint.y, 0.99),
                                                          inverseProjView: view.inverseProjViewMat,
                                                          viewWidth: Float(view.imageWidth),
                                                          viewHeight: Float(view.imageHeight) )
    
    let rayDirection = (screenPosOnFarClippingPlane - view.cameraPosition).normalized()
    
    return HitTestRay(origin: view.cameraPosition, direction: rayDirection)
    
}

func multProject(m : GLKMatrix4, x : Float, y : Float , z : Float ) -> SCNVector3 {
    
    let lw = 1.0 / (x * m.m03 + y * m.m13 + z * m.m23 + m.m33 )
    let ox = ( x * m.m00 + y * m.m10 + z * m.m20 + m.m30 ) * lw
    let oy = ( x * m.m01 + y * m.m11 + z * m.m21 + m.m31 ) * lw
    let oz = ( x * m.m02 + y * m.m12 + z * m.m22 + m.m32 ) * lw
    return SCNVector3.init(ox, oy, oz)
    
}

func unprojectPoint( imagePoint : SCNVector3,
                     view : CameraView ) -> SCNVector3 {
    
    let screenPosOnFarClippingPlane = unprojectPoint(point: SCNVector3(imagePoint.x, imagePoint.y, 0.99),
                                                     inverseProjView: view.inverseProjViewMat,
                                                     viewWidth: Float(view.imageWidth),
                                                     viewHeight: Float(view.imageHeight) )
    
    return screenPosOnFarClippingPlane
    
}

func unprojectPoint( point : SCNVector3 ,
                     inverseProjView : matrix_float4x4,
                     viewWidth : Float,
                     viewHeight : Float ) -> SCNVector3 {
    
    
    var y : Float = viewHeight - point.y - 1
    let x : Float = (2 * point.x) / viewWidth - 1
    y  = (2 * y) / viewHeight - 1
    let z : Float = (2 * point.z) - 1
    
    let invProj = SCNMatrix4ToGLKMatrix4(SCNMatrix4.init(inverseProjView))
    //let p = SCNVector3FromGLKVector3( GLKMatrix4MultiplyAndProjectVector3(invProj, GLKVector3Make(x, y, z)) )
    let p2 = multProject(m: invProj, x: x, y: y, z: z)
    
    return p2
    
}


func projectPoint( point : SCNVector3,
                   cameraView : CameraView,
                   cameraWidth : Int? = nil,
                   cameraHeight : Int? = nil
    ) -> CGPoint? {
    
    let camW = cameraWidth ?? cameraView.imageWidth
    let camH = cameraHeight ?? cameraView.imageHeight

    return projectPoint(point: point,
                        projectionMatrix: cameraView.projectionMatrix,
                        modelViewMatrix: cameraView.modelViewMatrix,
                        cameraWidth: camW, cameraHeight: camH)
    
}

func projectPoint( point : SCNVector3,
                   projectionMatrix : SCNMatrix4,
                   modelViewMatrix : SCNMatrix4,
                   cameraWidth : Int,
                   cameraHeight : Int,
                   rejectOutOfFrame : Bool = true
    ) -> CGPoint? {
    
    return projectPoint(point: point,
                        projectionMatrix: SCNMatrix4ToGLKMatrix4(projectionMatrix),
                        modelViewMatrix: SCNMatrix4ToGLKMatrix4(modelViewMatrix),
                        cameraWidth: cameraWidth,
                        cameraHeight: cameraHeight,
                        rejectOutOfFrame: rejectOutOfFrame)
    
}

func projectPoint( point : SCNVector3,
                   projectionMatrix : GLKMatrix4,
                   modelViewMatrix : GLKMatrix4,
                   cameraWidth : Int,
                   cameraHeight : Int,
                   rejectOutOfFrame : Bool = true
    ) -> CGPoint? {
    
    
    let camW = cameraWidth
    let camH = cameraHeight
    
    
    let mvp = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix)
    
    //print("-- Projection -- ")
    //print(SCNMatrix4FromGLKMatrix4(cameraView.projectionMatrix).np)
    //print("-- View -- ")
    //print(SCNMatrix4FromGLKMatrix4(cameraView.modelViewMatrix).np)
    
    //print("-- MVP ---")
    //print(SCNMatrix4FromGLKMatrix4(mvp).np)
    
    var pos = GLKMatrix4MultiplyAndProjectVector3(mvp, SCNVector3ToGLKVector3(point))
    
    //print("-- Multiply and project / NDC --")
    //print(pos.x, pos.y, pos.z)
    
    if pos.z < 0.8 || pos.z >= 1.0 {
        return nil
    }
    
    
    let px : CGFloat = (0.5 + CGFloat(pos.x) * 0.5) * CGFloat(camW)
    let py : CGFloat = (1.0 - (0.5 + CGFloat(pos.y) * 0.5)) * CGFloat(camH)
    
    if px < 0 || px > CGFloat(camW) || py < 0 || py > CGFloat(camH) {
        if rejectOutOfFrame {
            return nil
        }
    }
    
    //print("-- Final Point --")
    //print(px, py)
    
    return CGPoint(x: px, y: py)
    
}


public func getNormalizedImageFromQuad(_ pixelBuffer: CVPixelBuffer,
                                       _ quad : [CGPoint] ) -> UIImage {
    
    let ciContext = CIContext()
    
    CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
    
    var ciImage = CIImage(cvPixelBuffer: pixelBuffer, options: nil)
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
    
    //let width = CVPixelBufferGetWidth(pixelBuffer)
    //let height = CVPixelBufferGetHeight(pixelBuffer)
    
    //let tr = ciImage.orientationTransform(forExifOrientation: 6 )
    let tr = ciImage.orientationTransform(forExifOrientation: 4 )
    
    //tr = tr.translatedBy(x: bw * (1.0 - scale), y: 0.0 )
    //tr = tr.scaledBy(x: scale, y: scale )
    
    ciImage = ciImage.transformed(by: tr)
    
//    ORIENTATION_TOPLEFT = 1;
//    ORIENTATION_TOPRIGHT = 2;
//    ORIENTATION_BOTRIGHT = 3;
//    ORIENTATION_BOTLEFT = 4;
//    ORIENTATION_LEFTTOP = 5;
//    ORIENTATION_RIGHTTOP = 6;
//    ORIENTATION_RIGHTBOT = 7;
//    ORIENTATION_LEFTBOT = 8;
    
    // TL, TR, BL, BR
    ciImage = ciImage.applyingFilter("CIPerspectiveCorrection", parameters: [
        "inputTopLeft":    CIVector.init(cgPoint: quad[0]),
        "inputTopRight":   CIVector.init(cgPoint: quad[1]),
        "inputBottomLeft": CIVector.init(cgPoint: quad[2]),
        "inputBottomRight":CIVector.init(cgPoint: quad[3])])
    
    
    
    let cgImage:CGImage = ciContext.createCGImage(ciImage, from: ciImage.extent)!
    
    
    let image:UIImage = UIImage.init(cgImage: cgImage)
    
    
    return image
    
//
//    let material = SCNMaterial()
//    material.lightingModel = .constant
//
//    material.diffuse.contents = image
//    material.transparency = 1.0
//    material.writesToDepthBuffer = false
//    //material.readsFromDepthBuffer = false
//
//    self.planeGeometry.materials = [material]
//
//    let surf = """
//        float edge = 0.175;
//
//        float xx = smoothstep(0.0, edge, _surface.diffuseTexcoord.x );
//        xx *= (1.0 - smoothstep(1.0-edge, 1.0, _surface.diffuseTexcoord.x ));
//
//        xx *= smoothstep(0.0, edge, _surface.diffuseTexcoord.y );
//        xx *= (1.0 - smoothstep(1.0-edge, 1.0, _surface.diffuseTexcoord.y ));
//
//        _surface.transparent = mix(vec4(0.0), vec4(1.0), xx);
//
//        """
//    material.shaderModifiers = [SCNShaderModifierEntryPoint.surface : surf ]
//
    
}
