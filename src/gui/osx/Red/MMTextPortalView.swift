//
//  MMTextPortalView.swift
//  Red
//
//  Created by Nathaniel W Griswold on 10/1/20.
//  Copyright © 2020 ManicMind. All rights reserved.
//

import Cocoa

class MMTextPortalView: NSView, CALayerDelegate {
    var directImageLayer : CALayer!
    var directImage : CGImage!

//    override func makeBackingLayer() -> CALayer {
//        self.directImageLayer = CALayer()
//        self.directImageLayer.delegate = self
//        // renderer_set_new_size(width, height)
//        // let data = renderer_
//        let provider = CGDataProvider(data: <#T##CFData#>)
//        self.directImage = CGImage(width: self.frame.width, height: self.frame.height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: self.frame.width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo.byteOrder32Little, provider: <#T##CGDataProvider#>, decode: <#T##UnsafePointer<CGFloat>?#>, shouldInterpolate: <#T##Bool#>, intent: <#T##CGColorRenderingIntent#>)
//        return self.directImageLayer
//    }

    override func resize(withOldSuperviewSize oldSize: NSSize) {
        super.resize(withOldSuperviewSize: oldSize)
        
        
    }
    
}
