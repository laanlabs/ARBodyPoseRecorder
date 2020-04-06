//
//  UsefulExtensions.swift
//  BulletTimeCam
//
//  Created by cc on 10/12/18.
//  Copyright © 2018 Laan Labs. All rights reserved.
//

import Foundation
import UIKit
import SceneKit


extension UIImage {
    func blurred(radius: CGFloat) -> UIImage {
        let ciContext = CIContext(options: nil)
        guard let cgImage = cgImage else { return self }
        let inputImage = CIImage(cgImage: cgImage)
        guard let ciFilter = CIFilter(name: "CIGaussianBlur") else { return self }
        ciFilter.setValue(inputImage, forKey: kCIInputImageKey)
        ciFilter.setValue(radius, forKey: "inputRadius")
        guard let resultImage = ciFilter.value(forKey: kCIOutputImageKey) as? CIImage else { return self }
        guard let cgImage2 = ciContext.createCGImage(resultImage, from: inputImage.extent) else { return self }
        return UIImage(cgImage: cgImage2)
    }
}

extension URL {
    
    static func documentsDirectory() -> URL {
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
        
    }
}

// MARK: - Collection extensions
extension Array where Iterator.Element == CGFloat {
    var average: CGFloat? {
        guard !isEmpty else {
            return nil
        }
        
        var ret = self.reduce(CGFloat(0)) { (cur, next) -> CGFloat in
            var cur = cur
            cur += next
            return cur
        }
        let fcount = CGFloat(count)
        ret /= fcount
        return ret
    }
}

extension Array where Iterator.Element == SCNVector3 {
    var average: SCNVector3? {
        guard !isEmpty else {
            return nil
        }
        
        var ret = self.reduce(SCNVector3Zero) { (cur, next) -> SCNVector3 in
            var cur = cur
            cur.x += next.x
            cur.y += next.y
            cur.z += next.z
            return cur
        }
        let fcount = Float(count)
        ret.x /= fcount
        ret.y /= fcount
        ret.z /= fcount
        
        return ret
    }
    
}

extension Array where Iterator.Element == Float {
    var average: Float? {
        guard !self.isEmpty else {
            return nil
        }
        
        let sum = self.reduce(Float(0)) { current, next in
            return current + next
        }
        return sum / Float(self.count)
    }
}

extension Array where Iterator.Element == float3 {
    var average: float3? {
        guard !self.isEmpty else {
            return nil
        }
        
        let sum = self.reduce(float3(0)) { current, next in
            return current + next
        }
        return sum / Float(self.count)
    }
}

extension Array {
    var randomElement: Element {
        let index = Int(arc4random_uniform(UInt32(count)))
        return self[index]
    }
}

extension RangeReplaceableCollection where IndexDistance == Int {
    mutating func keepLast(_ elementsToKeep: Int) {
        if count > elementsToKeep {
            self.removeFirst(count - elementsToKeep)
        }
    }
}

extension Date {
    var secondsAgo : TimeInterval {
        return -self.timeIntervalSinceNow
    }
    var millisecondsAgo : TimeInterval {
        return -self.timeIntervalSinceNow * 1000.0
    }
}


extension String {
    var floatValue: Float {
        return (self as NSString).floatValue
    }
    
    // Python-y formatting:  "blah %i".format(4)
    func format(_ args: CVarArg...) -> String {
        return NSString(format: self, arguments: getVaList(args)) as String
    }
    
    
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        
        return ceil(boundingBox.height)
    }
    
    func width(withConstraintedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        
        return ceil(boundingBox.width)
    }
    
    
    
}

// MARK: Diagnostic Info

extension String {
    static var appVersion: String {
        guard let info = Bundle.main.infoDictionary,
            let name = info["CFBundleName"],
            let version = info["CFBundleShortVersionString"],
            let build = info["CFBundleVersion"] else { return "Unable to get version info"}
        
        return "\(name) \(version) (\(build))"
    }
}



// h,s,v 0-1 float
// r,g,b out is 0-255 int

func hsv2rgb(_ hue : CGFloat,
             saturation : CGFloat ,
             brightness : CGFloat ) -> (r: Int, g: Int, b: Int) {
    
    // Converts HSV to a RGB color
    //var rgb: RGB = (red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
    
    var r: CGFloat
    var g: CGFloat
    var b: CGFloat
    
    let i = Int(hue * 6)
    let f = hue * 6 - CGFloat(i)
    let p = brightness * (1 - saturation)
    let q = brightness * (1 - f * saturation)
    let t = brightness * (1 - (1 - f) * saturation)
    switch (i % 6) {
    case 0: r = brightness; g = t; b = p; break;
        
    case 1: r = q; g = brightness; b = p; break;
        
    case 2: r = p; g = brightness; b = t; break;
        
    case 3: r = p; g = q; b = brightness; break;
        
    case 4: r = t; g = p; b = brightness; break;
        
    case 5: r = brightness; g = p; b = q; break;
        
    default: r = brightness; g = t; b = p;
    }
    
    return ( Int(r * 255.0), Int(g*255.0), Int(b*255.0) )
    
}
