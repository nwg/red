//
//  MMTextPortalView.swift
//  Red
//
//  Created by Nathaniel W Griswold on 10/1/20.
//  Copyright © 2020 ManicMind. All rights reserved.
//

import Cocoa

class MMTextPortalView: NSView, CALayerDelegate, NibLoadable {
    var directImageLayer : CALayer? = .none
    var directImage : CGImage?
    
    @IBOutlet weak var boxView: NSBox!
    @IBOutlet weak var imageView: NSImageView!

    override func resize(withOldSuperviewSize oldSize: NSSize) {
        super.resize(withOldSuperviewSize: oldSize)
    }

    public func setupImage(data : CFData, width: Int, height: Int) -> Void {
        let provider = CGDataProvider(data: data)
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue).union(.byteOrder32Little)
        self.directImage = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: bitmapInfo, provider: provider!, decode: nil, shouldInterpolate: false, intent: .defaultIntent)

        self.imageView?.removeFromSuperview()
        let image = NSImage(cgImage: self.directImage!, size: NSSize(width: width, height: height))
        
        let imageView = NSImageView(image: image)
        imageView.frame = self.bounds
        self.imageView = imageView
        self.addSubview(imageView)
    }

}
