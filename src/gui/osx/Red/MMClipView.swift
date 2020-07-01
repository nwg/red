//
//  MMClipView.swift
//  Red
//
//  Created by Nathaniel W Griswold on 6/17/20.
//  Copyright © 2020 ManicMind. All rights reserved.
//

import Cocoa

class MMClipView: NSClipView {

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.postsBoundsChangedNotifications = true
        
//        NSUserNotificationCenter.default.addObserver(self, forKeyPath: NSView.boundsDidChangeNotification.rawValue, options: [.new], context: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(viewBoundsChanged), name: NSView.boundsDidChangeNotification, object: self)        
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
    }

    override func viewBoundsChanged(_ notification: Notification) {
        
    }
    
    override func viewFrameChanged(_ notification: Notification) {
        
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}
