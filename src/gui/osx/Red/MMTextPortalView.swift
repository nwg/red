//
//  MMTextPortalView.swift
//  Red
//
//  Created by Nathaniel W Griswold on 10/1/20.
//  Copyright © 2020 ManicMind. All rights reserved.
//

import Cocoa

class CustomImageView: NSView, CALayerDelegate {
    var image : NSImage?
    var data : NSData?
    var width : Int = 0
    var height : Int = 0
    var cgImage : CGImage?
    
    init(frame frameRect: NSRect, width: Int, height: Int, data: NSData) {
        self.width = width
        self.height = height
        self.data = data
        super.init(frame: frameRect)
        
        self.createImage()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func createImage() {
        let provider = CGDataProvider(data: self.data!)
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue).union(.byteOrder32Little)
        self.cgImage = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: bitmapInfo, provider: provider!, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
        self.image = NSImage(cgImage: self.cgImage!, size: NSSize(width: width, height: height))
    }
    
    func reload() {
        self.createImage()
        self.layer?.contents = self.image
        self.needsDisplay = true
        self.displayIfNeeded()
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
    var data : NSData?
    
    override func resize(withOldSuperviewSize oldSize: NSSize) {
        super.resize(withOldSuperviewSize: oldSize)
    }
    
    public func reload() {
        self.customImageView?.reload()
    }
    
    public func setupImage(data : CFData, width: Int, height: Int) -> Void {
        self.data = data
        
        self.customImageView = CustomImageView(frame: CGRect(x: 0, y: 0, width: width/2, height: height/2), width: width, height: height, data:data)
        self.addSubview(self.customImageView!)
        
        if self.frame.size.width < frame.size.width || self.frame.size.height < frame.size.height {
            var myFrame = self.frame
            myFrame.size = frame.size
            self.frame = myFrame
        }
    }

}
