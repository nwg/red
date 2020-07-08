//
//  MMTilingView.swift
//  Red
//
//  Created by Nathaniel W Griswold on 7/8/20.
//  Copyright © 2020 ManicMind. All rights reserved.
//

import Cocoa
import CoreGraphics

class MMTilingView: NSView, CALayerDelegate {

    override func makeBackingLayer() -> CALayer {
        let tiledLayer = CATiledLayer()
        tiledLayer.delegate = self
        return tiledLayer
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    func draw(_ layer: CALayer, in ctx: CGContext) {
        let red = CGFloat(drand48())
        let green = CGFloat(drand48())
        let blue = CGFloat(drand48())
        ctx.setFillColor(red: red, green: green, blue: blue, alpha: 1.0)
        ctx.fill(ctx.boundingBoxOfClipPath)
    }
    
}
