//
//  MMTextView.swift
//  Red
//
//  Created by Nathaniel W Griswold on 6/17/20.
//  Copyright © 2020 ManicMind. All rights reserved.
//

import Cocoa
import CoreText

class MMTextView: NSView {
    
    struct LineInfo {
        let displayRect : NSRect
        let text : NSMutableAttributedString
    }
    
    var lineInfo : Array<LineInfo>?
    
    var lines : Array<NSMutableAttributedString>? {
        didSet {
            if lines != nil && lines!.count > 0 {
                recomputeLines()
            } else {
                self.lineInfo = []
            }

        }
    }
    var font : NSFont
    let lineHeight : Float64
    
    override init(frame frameRect: NSRect) {
        self.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        self.lineHeight = Float64(self.font.ascender - self.font.descender)
        self.lineInfo = []
        super.init(frame: frameRect)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        self.lineHeight = Float64(self.font.ascender - self.font.descender)
        self.lineInfo = []
        super.init(coder: aDecoder)
    }
    
    func recomputeLines() {
        if let lines = self.lines {
            let height = Float64(lines.count) * self.lineHeight
            var y = Float64(Float64(self.frame.height) - self.lineHeight)
            self.lineInfo = []
            for line in lines {
                let rect = NSRect(x: 0, y: CGFloat(y), width: self.frame.width, height: CGFloat(self.lineHeight))
                self.lineInfo!.append(LineInfo(displayRect: rect, text: line))
                y -= self.lineHeight
            }
            let displayRect = NSRect(x: 0, y: self.frame.height, width: self.frame.width, height: CGFloat(height))
            setNeedsDisplay(displayRect)
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        NSColor.green.set()
        
        let rect = dirtyRect
        let path = NSBezierPath(rect: rect)
        path.fill()
        
        NSColor.red.set()
        if let infos = self.lineInfo {
            for info in infos {
                let path = NSBezierPath(rect: info.displayRect)
                path.stroke()
            }
        }
    }
    
}
