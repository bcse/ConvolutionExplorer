//
//  accelerate.swift
//  ConvolutionExplorer
//
//  Created by Simon Gladman on 20/05/2015.
//  Copyright (c) 2015 Simon Gladman. All rights reserved.
//
// Thanks to https://github.com/j4nnis/AImageFilters

import UIKit
import Accelerate

func applyConvolutionFilterToImage(_ image: UIImage, kernel: [Int16], divisor: Int) -> UIImage?
{
    precondition(kernel.count == 9 || kernel.count == 25 || kernel.count == 49, "Kernel size must be 3x3, 5x5 or 7x7.")
    let kernelSide = UInt32(sqrt(Float(kernel.count)))
    
    guard let imageRef = image.cgImage else { return nil }
    guard let inProvider = imageRef.dataProvider else { return nil }
    guard let inBitmapData = inProvider.data else { return nil }
    
    var inBuffer = vImage_Buffer(data: UnsafeMutablePointer(mutating: CFDataGetBytePtr(inBitmapData)), height: UInt(imageRef.height), width: UInt(imageRef.width), rowBytes: imageRef.bytesPerRow)
    
    let pixelBuffer = malloc(imageRef.bytesPerRow * imageRef.height)
    
    var outBuffer = vImage_Buffer(data: pixelBuffer, height: UInt(imageRef.height), width: UInt(imageRef.width
    ), rowBytes: imageRef.bytesPerRow)
    
    var backgroundColor: [UInt8] = [0, 0, 0, 0]
    
    vImageConvolve_ARGB8888(&inBuffer, &outBuffer, nil, 0, 0, kernel, kernelSide, kernelSide, Int32(divisor), &backgroundColor, vImage_Flags(kvImageBackgroundColorFill))
    
    let outImage = UIImage(fromvImageOutBuffer: outBuffer, scale: image.scale, orientation: .up)
    
    free(pixelBuffer)
    
    return outImage
}

private extension UIImage
{
    convenience init?(fromvImageOutBuffer outBuffer: vImage_Buffer, scale: CGFloat, orientation: Orientation)
    {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let context = CGContext(data: outBuffer.data, width: Int(outBuffer.width), height: Int(outBuffer.height), bitsPerComponent: 8, bytesPerRow: outBuffer.rowBytes, space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        
        guard let outCGimage = context?.makeImage() else { return nil }
        
        self.init(cgImage: outCGimage, scale:scale, orientation: orientation)
    }
}
