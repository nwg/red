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
    
    var tiledLayer : CATiledLayer!

    override func makeBackingLayer() -> CALayer {
        self.tiledLayer = CATiledLayer()
        self.tiledLayer.delegate = self
        print("\(self.tiledLayer.tileSize)")
        return self.tiledLayer
    }
    
    override var acceptsFirstResponder: Bool {
        get {
            return true
        }
    }
    
    override func keyDown(with event: NSEvent) {
//        if let keyString = theEvent.charactersIgnoringModifiers where keyString == "UP" || keyString == "up" {
//            Swift.print("BUT...BUT…")
//        }
        let changeSize = CGFloat(100)
        if let key = event.specialKey {
            switch (key) {
            case .upArrow:
                let currentSize = tiledLayer.tileSize
                let newSize = CGSize(width: currentSize.width + changeSize, height: currentSize.height + changeSize)
                tiledLayer.tileSize = newSize
            case .downArrow:
                let currentSize = tiledLayer.tileSize
                let newSize = CGSize(width: currentSize.width - changeSize, height: currentSize.height - changeSize)
                tiledLayer.tileSize = newSize
            default:
                break
            }
        } else {
            super.keyDown(with: event)
        }
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
