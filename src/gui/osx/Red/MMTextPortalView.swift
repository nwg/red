//
//  MMTextPortalView.swift
//  Red
//
//  Created by Nathaniel W Griswold on 10/1/20.
//  Copyright © 2020 ManicMind. All rights reserved.
//

import Cocoa

class CustomImageView: NSView, CALayerDelegate {
    var image : NSImage!
    
    init(frame frameRect: NSRect, image: NSImage) {
        super.init(frame: frameRect)
        self.image = image
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func makeBackingLayer() -> CALayer {
        let layer = super.makeBackingLayer()

        layer.contents = self.image!

        return layer
    }
}

class MMTextPortalView: NSView, CALayerDelegate, NibLoadable {
    var directImageLayer : CALayer? = .none
    var directImage : CGImage?
    var image : NSImage?
    var customImageView : CustomImageView?
    
    override func resize(withOldSuperviewSize oldSize: NSSize) {
        super.resize(withOldSuperviewSize: oldSize)
    }
    
    public func setupImage(data : CFData, width: Int, height: Int) -> Void {
        let provider = CGDataProvider(data: data)
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue).union(.byteOrder32Little)
        self.directImage = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: bitmapInfo, provider: provider!, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
        self.image = NSImage(cgImage: self.directImage!, size: NSSize(width: width, height: height))
        
        self.customImageView = CustomImageView(frame: CGRect(x: 0, y: 0, width: width/2, height: height/2), image: self.image!)
        self.addSubview(self.customImageView!)
        
        if self.frame.size.width < frame.size.width || self.frame.size.height < frame.size.height {
            var myFrame = self.frame
            myFrame.size = frame.size
            self.frame = myFrame
        }
    }

}
