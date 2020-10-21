//
//  MMTextScrollView.swift
//  Red
//
//  Created by Nathaniel W Griswold on 10/1/20.
//  Copyright © 2020 ManicMind. All rights reserved.
//

import Cocoa

class MMTextScrollView: NSView, NibLoadable {

    @IBOutlet weak var portalContentView: NSView!
    weak var textPortalView : MMTextPortalView?
    
    override func awakeFromNib() {
        self.textPortalView = MMTextPortalView.createFromNib()
        if let textPortalView = self.textPortalView {
            textPortalView.frame = NSRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height)
            self.portalContentView.addSubview(textPortalView)
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}
