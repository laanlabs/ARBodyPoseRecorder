//
//  VideoRecorder.swift
//  ARPoseRecord
//
//  Created by cc on 9/6/19.
//  Copyright © 2019 Laan Labs. All rights reserved.
//

import Foundation

import AVFoundation
import CoreImage
import UIKit

@available(iOS 11.0, *)
@objc public protocol RecorderDelegate {
    /**
     A protocol method that is triggered when a recorder ends recording.
     - parameter path: A `URL` object that returns the video file path.
     - parameter noError: A boolean that returns true when the recorder ends without errors. Otherwise, it returns false.
     */
    func recorder(didEndRecording path: URL, with noError: Bool)
    
    /**
     A protocol method that is triggered when a recorder fails recording.
     - parameter error: An `Error` object that returns the error value.
     - parameter status: A string that returns the reason of the recorder failure in a string literal format.
     */
    func recorder(didFailRecording error: Error?, and status: String)
    
    /**
     A protocol method that is triggered when a recorder is modified.
     - parameter duration: A double that returns the duration of current recording
     */
    @objc optional func recorder(didUpdateRecording duration: TimeInterval)
    
    /**
     A protocol method that is triggered when the application will resign active.
     - parameter status: A `RecordARStatus` object that returns the AR recorder current status.
     
     
     - NOTE: Check [applicationWillResignActive(_:)](https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622950-applicationwillresignactive) for more information.
     */
    //@objc func recorder(willEnterBackground status: RecordARStatus)
    
}


@available(iOS 11.0, *)
class VideoRecorder: NSObject {
    
    private var assetWriter: AVAssetWriter!
    private var videoInput: AVAssetWriterInput!
    private var session: AVCaptureSession!
    
    private var pixelBufferInput: AVAssetWriterInputPixelBufferAdaptor!
    private var videoOutputSettings: Dictionary<String, AnyObject>!
    

    private var isRecording: Bool = false
    
    var delegate : RecorderDelegate?
    
    init(output: URL, width: Int, height: Int, adjustForSharing: Bool,
           queue: DispatchQueue ) {
        
        super.init()
        do {
            assetWriter = try AVAssetWriter(outputURL: output, fileType: AVFileType.mp4)
        } catch {
            // FIXME: handle when failed to allocate AVAssetWriter.
            return
        }
        
        //HEVC file format only supports A10 Fusion Chip or higher.
        //to support HEVC, make sure to check if the device is iPhone 7 or higher
        videoOutputSettings = [
            AVVideoCodecKey: AVVideoCodecType.h264 as AnyObject,
            AVVideoWidthKey: width as AnyObject,
            AVVideoHeightKey: height as AnyObject
        ]
        
        let attributes: [String: Bool] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        
        videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoOutputSettings)
        
        videoInput.expectsMediaDataInRealTime = true
        pixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput, sourcePixelBufferAttributes: nil)
        
        
        if assetWriter.canAdd(videoInput) {
            assetWriter.add(videoInput)
        } else {
            delegate?.recorder(didFailRecording: assetWriter.error, and: "An error occurred while adding video input.")
            isWritingWithoutError = false
        }
        
        
        assetWriter.shouldOptimizeForNetworkUse = adjustForSharing
        
    }
    
    
    var startingVideoTime: CMTime?
    var isWritingWithoutError: Bool?
    var currentDuration: TimeInterval = 0 // Seconds
    
    func insert(pixel buffer: CVPixelBuffer, with intervals: CFTimeInterval) -> Bool {
        let time: CMTime = CMTime(seconds: intervals, preferredTimescale: 1000000)
        return insert(pixel: buffer, with: time)
    }
    
    func insert(pixel buffer: CVPixelBuffer, with time: CMTime) -> Bool {
        if assetWriter.status == .unknown {
            guard startingVideoTime == nil else {
                isWritingWithoutError = false
                return false
            }
            startingVideoTime = time
            if assetWriter.startWriting() {
                assetWriter.startSession(atSourceTime: startingVideoTime!)
                currentDuration = 0
                isRecording = true
                isWritingWithoutError = true
            } else {
                delegate?.recorder(didFailRecording: assetWriter.error, and: "An error occurred while starting the video session.")
                currentDuration = 0
                isRecording = false
                isWritingWithoutError = false
            }
        } else if assetWriter.status == .failed {
            delegate?.recorder(didFailRecording: assetWriter.error, and: "Video session failed while recording.")
//            logAR.message("An error occurred while recording the video, status: \(assetWriter.status.rawValue), error: \(assetWriter.error!.localizedDescription)")
            currentDuration = 0
            isRecording = false
            isWritingWithoutError = false
            return false
        }
        
        if videoInput.isReadyForMoreMediaData {
            append(pixel: buffer, with: time)
            currentDuration = time.seconds - startingVideoTime!.seconds
            isRecording = true
            isWritingWithoutError = true
            delegate?.recorder?(didUpdateRecording: currentDuration)
            return true
        }
        
        return false
        
    }
    
    func pause() {
        isRecording = false
    }
    
    func end(writing finished: @escaping () -> Void){
        if let session = session {
            if session.isRunning {
                session.stopRunning()
            }
        }
        
        if assetWriter.status == .writing {
            assetWriter.finishWriting(completionHandler: finished)
        }
    }
    
    func append(pixel buffer: CVPixelBuffer, with time: CMTime) {
        pixelBufferInput.append(buffer, withPresentationTime: time)
    }
    
}


