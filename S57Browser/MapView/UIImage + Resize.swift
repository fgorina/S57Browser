//
//  UIImage + Resize.swift
//  tracesuitest
//
//  Created by Francisco Gorina Vanrell on 26/02/2020.
//  Copyright © 2020 Francisco Gorina Vanrell. All rights reserved.
//
#if os(iOS)
import CoreImage
import UIKit
import Accelerate


extension UIImage{
    func resizeImageUsingVImage(size:CGSize) -> UIImage? {
         let cgImage = self.cgImage!
  
         var format = vImage_CGImageFormat(bitsPerComponent: 8, bitsPerPixel: 32, colorSpace: nil, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.first.rawValue), version: 0, decode: nil, renderingIntent: CGColorRenderingIntent.defaultIntent)
 
/*        var format = vImage_CGImageFormat(bitsPerComponent: UInt32(cgImage.bitsPerComponent), bitsPerPixel: UInt32(cgImage.bitsPerPixel), colorSpace: nil, bitmapInfo: cgImage.bitmapInfo, version: 0, decode: cgImage.decode, renderingIntent: CGColorRenderingIntent.defaultIntent)
*/
        var sourceBuffer = vImage_Buffer()
         defer {
              free(sourceBuffer.data)
         }
        var error = vImageBuffer_InitWithCGImage(&sourceBuffer, &format, nil, cgImage, numericCast(kvImageNoFlags))
         guard error == kvImageNoError else { return nil }
       // create a destination buffer
       //let scale = self.scale
       let destWidth = Int(size.width)
       let destHeight = Int(size.height)
       let bytesPerPixel = self.cgImage!.bitsPerPixel/8
       let destBytesPerRow = destWidth * bytesPerPixel
       let destData = UnsafeMutablePointer<UInt8>.allocate(capacity: destHeight * destBytesPerRow)
       defer {
             destData.deallocate()
       }
      var destBuffer = vImage_Buffer(data: destData, height: vImagePixelCount(destHeight), width: vImagePixelCount(destWidth), rowBytes: destBytesPerRow)
    // scale the image
     error = vImageScale_ARGB8888(&sourceBuffer, &destBuffer, nil, numericCast(kvImageHighQualityResampling))
     guard error == kvImageNoError else { return nil }
     // create a CGImage from vImage_Buffer
        let destCGImage = vImageCreateCGImageFromBuffer(&destBuffer, &format, nil, nil, numericCast(kvImageNoFlags), &error)?.takeRetainedValue()
    guard error == kvImageNoError else { return nil }
    // create a UIImage
     let resizedImage = destCGImage.flatMap { UIImage(cgImage: $0, scale: 0.0, orientation: self.imageOrientation) }
     //destCGImage = nil
    return resizedImage
    }
    
    
}

extension UIImage {
    func resizeUI(size:CGSize) -> UIImage? {
        
        UIGraphicsBeginImageContextWithOptions(size, false, self.scale)
        self.draw(in: CGRect(origin: CGPointZero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
    
    func combineImageAndResize(image: UIImage?, size: CGSize) -> UIImage?{
        UIGraphicsBeginImageContextWithOptions(size, false, self.scale)
        
        if let image = image {
            image.draw(in: CGRect(origin: CGPointZero, size: size))
        }
        self.draw(in: CGRect(origin: CGPointZero, size: size))

        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
    
}

extension UIImage {

    func colorized(color : UIColor) -> UIImage {
        let rect = CGRectMake(0, 0, self.size.width, self.size.height);
        UIGraphicsBeginImageContextWithOptions(rect.size, false, scale);
        let context = UIGraphicsGetCurrentContext()!;
        context.setBlendMode(.normal)
        
        // We need to flip it vertically. Why? I don't know
        
        context.saveGState() // Comments show
        context.translateBy(x: 0.0, y:  size.height)//
        
        context.scaleBy(x: 1.0, y: -1.0) //
        context.draw(self.cgImage!, in: rect)
        context.clip(to: rect, mask: self.cgImage!)
        context.setFillColor(color.cgColor)
        context.fill(rect)
        
        context.restoreGState() //
        let colorizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return colorizedImage
    }
    
}

struct IntColor : Codable, Hashable {
    
    var red : UInt8
    var green : UInt8
    var blue : UInt8
    var alpha : UInt8

}

extension UIImage {
    /**
     Replaces a color in the image with a different color.
     - Parameter color: color to be replaced.
     - Parameter with: the new color to be used.
     - Parameter tolerance: tolerance, between 0 and 1. 0 won't change any colors,
                            1 will change all of them. 0.5 is default.
     - Returns: image with the replaced color.
     */
    func replaceColor(_ colors: [IntColor], with: IntColor, tolerance: Int = 10, getStats : Bool = false) -> UIImage {
        guard let imageRef = self.cgImage else {
            return self
        }
        // Get color components from replacement color
        
        let newRed = with.red
        let newGreen = with.green
        let newBlue = with.blue
        let newAlpha = with.alpha

        let width = imageRef.width
        let height = imageRef.height
        
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitmapByteCount = bytesPerRow * height
        
        let rawData = UnsafeMutablePointer<UInt8>.allocate(capacity: bitmapByteCount)
        defer {
            rawData.deallocate()
        }
  
        for i in 0..<bitmapByteCount {
            rawData[i] = 0
        }
        guard let colorSpace = CGColorSpace(name: CGColorSpace.genericRGBLinear) else {         // Was CGColorSpace.genericRGBLinear
            return self
        }
        
        guard let context = CGContext(
            data: rawData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                | CGBitmapInfo.byteOrder32Big.rawValue
        ) else {
            return self
        }
        
        let rc = CGRect(x: 0, y: 0, width: width, height: height)
        // Draw source image on created context.
        context.draw(imageRef, in: rc)
        var byteIndex = 0
        var changes = false
        // Iterate through pixels
        
        var cellColors : [IntColor] = []
        var countPixels : [Int] = []
        
        
        while byteIndex < bitmapByteCount {
            // Get color of current pixel
            
            let currentColor = IntColor(red: rawData[byteIndex + 0], green: rawData[byteIndex + 1], blue: rawData[byteIndex + 2], alpha: rawData[byteIndex + 3])
            
            if getStats {
                if cellColors.contains(currentColor){
                    if let index = cellColors.firstIndex(of: currentColor) {
                        countPixels[index] += 1
                    }
                } else {
                    cellColors.append(currentColor)
                    countPixels.append(1)
                }
            }
              // Replace pixel if the color is close enough to the color being replaced.
            for color in colors {
                if compareColor(firstColor: color, secondColor: currentColor, tolerance: tolerance) {
                    rawData[byteIndex + 0] = newRed
                    rawData[byteIndex + 1] = newGreen
                    rawData[byteIndex + 2] = newBlue
                    rawData[byteIndex + 3] = newAlpha
                    changes = true
                    continue
                }
            }
            byteIndex += 4
        }
        
        if getStats {
            for (color, count) in zip(cellColors, countPixels) {
                print("\(color.red);\(color.green);\(color.blue);\(count)")
            }
        }
        if changes {
            // Retrieve image from memory context.
            guard let image = context.makeImage() else {
                return self
            }
            let result = UIImage(cgImage: image)
            return result
        } else {
            return self
        }
        
       
    }
    
    /**
     Check if two colors are the same (or close enough given the tolerance).
     - Parameter firstColor: first color used in the comparisson.
     - Parameter secondColor: second color used in the comparisson.
     - Parameter tolerance: how much variation can there be for the function to return true.
                            0 is less sensitive (will always return false),
                            1 is more sensitive (will always return true).
     */
    private func compareColor(
        firstColor: IntColor,
        secondColor: IntColor,
        tolerance: Int
    ) -> Bool {
          
        let r1 : Int = Int(firstColor.red)
        let g1 : Int = Int(firstColor.green)
        let b1 : Int = Int(firstColor.blue)
        let r2 : Int = Int(secondColor.red)
        let g2 : Int = Int(secondColor.green)
        let b2 : Int = Int(secondColor.blue)

        return abs(r1 - r2) <= tolerance
        && abs(g1 - g2 ) <= tolerance
        && abs(b1 - b2) <= tolerance
            //&& abs(firstColor.alpha - secondColor.alpha) <= tolerance
    }
    
}

#endif
