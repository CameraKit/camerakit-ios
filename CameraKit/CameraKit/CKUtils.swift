//
//  CKUtils.swift
//  CameraKit
//
//  Created by Adrian Mateoaea on 23/01/2019.
//  Copyright © 2019 Wonderkiln. All rights reserved.
//

import UIKit

@objc public class CKUtils: NSObject {
    
    @objc public static func cropAndScale(_ image: UIImage, width: Int, height: Int) -> UIImage? {
        let fromRect = CGRect(x: 0, y: 0, width: image.size.height, height: image.size.width)
        var toRect = CGRect(x: 0, y: 0, width: height, height: width)
        
        let fromAspectRatio = fromRect.width / fromRect.height
        let toAspectRatio = toRect.width / toRect.height
        
        if fromAspectRatio < toAspectRatio {
            toRect.size.width = fromRect.width
            toRect.size.height = fromRect.width / toAspectRatio
            toRect.origin.y = (fromRect.height - toRect.height) / 2.0
        } else {
            toRect.size.height = fromRect.height
            toRect.size.width = fromRect.height * toAspectRatio
            toRect.origin.x = (fromRect.width - toRect.width) / 2.0
        }
        
        guard let croppedCgImage = image.cgImage?.cropping(to: toRect) else {
            return nil
        }
        
        guard let colorSpace = croppedCgImage.colorSpace else { return nil }
        guard let context = CGContext(data: nil, width: height, height: width, bitsPerComponent: croppedCgImage.bitsPerComponent, bytesPerRow: height * croppedCgImage.bitsPerPixel, space: colorSpace, bitmapInfo: croppedCgImage.alphaInfo.rawValue) else { return nil }
        
        context.interpolationQuality = .high
        context.draw(croppedCgImage, in: CGRect(x: 0, y: 0, width: height, height: width))
        
        guard let finalCgImage = context.makeImage() else {
            return nil
        }
        
        return UIImage(cgImage: finalCgImage, scale: 1.0, orientation: .right)
    }
}
