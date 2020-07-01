//
//  ScrollViewController.swift
//  Red
//
//  Created by Nathaniel W Griswold on 6/14/20.
//  Copyright © 2020 ManicMind. All rights reserved.
//

import Cocoa

class ScrollViewController: NSViewController {

    @IBOutlet var scrollView: NSScrollView!
    var textVC : MMTextViewController!
    var lastLayoutY : CGFloat?
    var lastBounds : CGRect?
    var observation: NSKeyValueObservation?
    
    var hasInitializedScroll : Bool = false
    
//    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
//        super.init(nibName: nil, bundle: nil)
//        self.textVC = MMTextViewController(parentScrollView: self.scrollView)
//        self.scrollView.documentView = self.textVC.view
//    }
    convenience init() {
        self.init(nibName: nil, bundle: nil)



    }
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        func change(object : NSClipView, change : NSKeyValueObservedChange<CGRect>) {
            if !self.hasInitializedScroll {
                return
            }
            
            if let oldBounds = self.lastBounds {
                let newBounds = object.bounds
                let newY = oldBounds.origin.y + oldBounds.height - newBounds.height
                self.scrollView.contentView.scroll(to: NSPoint(x: 0, y: newY))
            }
            
            print("Setting bounds to \(object.bounds)")
            self.lastBounds = object.bounds
            //            print("myDate changed from: \(change.oldValue!), updated to: \(change.newValue!)")

        }
        
        let fun = { (object : NSClipView, change : NSKeyValueObservedChange<CGRect>) in
            if !self.hasInitializedScroll {
                return
            }
            
            if let oldBounds = self.lastBounds {
                let newBounds = object.bounds
                let newY = oldBounds.origin.y + oldBounds.height - newBounds.height
                self.scrollView.contentView.scroll(to: NSPoint(x: 0, y: newY))
            }
            
            print("Setting bounds to \(object.bounds)")
            self.lastBounds = object.bounds
            //            print("myDate changed from: \(change.oldValue!), updated to: \(change.newValue!)")
        }
        
//        observation = scrollView.contentView.observe(
//            \NSClipView.frame,
//            options: [.new],
//            changeHandler: change)
//        observation = scrollView.contentView.observe(
//            \NSClipView.bounds,
//            options: [.new],
//            changeHandler: change)


//        NSUserNotificationCenter.default.addObserver(self, forKeyPath: "something", options: [.initial, .new], context: nil)
        
    }
    
    override func viewWillLayout() {
        super.viewWillLayout()
        
        if !self.hasInitializedScroll {
            self.hasInitializedScroll = true
            let y = self.scrollView.documentView!.bounds.height - self.scrollView.contentView.bounds.height
            self.scrollView.documentView!.scroll(NSPoint(x: 0, y: y))
        }

    }
    override func viewDidLayout() {
        super.viewDidLayout()
        
        print("offset: \(self.scrollView.contentView.bounds)")

        
//        self.lastLayoutY = self.scrollView.contentView.bounds.origin.y
//        self.lastBounds = self.scrollView.contentView.bounds
//
//        if let lastLayoutY = self.lastLayoutY, let lastBounds = self.lastBounds {
//            let newY = lastLayoutY + lastBounds.height - self.scrollView.contentView.bounds.height
//            self.scrollView.contentView.scroll(to: NSPoint(x: 0, y: newY))
//        }
//
//        self.lastLayoutY = self.scrollView.contentView.bounds.origin.y
//        self.lastBounds = self.scrollView.contentView.bounds
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.scrollView.contentView.postsBoundsChangedNotifications = true
        self.scrollView.contentView.postsFrameChangedNotifications = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(viewBoundsChanged), name: NSView.boundsDidChangeNotification, object: self.scrollView.contentView)
        NotificationCenter.default.addObserver(self, selector: #selector(viewFrameChanged), name: NSView.frameDidChangeNotification, object: self.scrollView.contentView)


        self.scrollView.automaticallyAdjustsContentInsets = false
        
        self.textVC = MMTextViewController(parentScrollView: self.scrollView)
//        self.textVC.view.frame = self.view.bounds
//        self.textVC.view.layer?.masksToBounds = true
//        self.view.wantsLayer = true
//        self.view.layer?.backgroundColor = NSColor.purple.cgColor
        self.textVC.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 3000.0)
        self.scrollView.documentView = self.textVC.view
    }
    
    @objc func viewBoundsChanged(_ notification : NSNotification) {
        self.geometryChange()
//
////        print("here")
//
////        guard let documentView = self.scrollView.documentView else { return }
//        let contentView = self.scrollView.contentView
//        let contentBounds = contentView.bounds
//        guard let oldBounds = self.lastBounds else { self.lastBounds = contentBounds; return }
//
////        print("bounds changed")
//        let newBounds = contentBounds
//        if oldBounds.size.equalTo(newBounds.size) { self.lastBounds = contentBounds; return }
//        let newY = oldBounds.origin.y + oldBounds.height - newBounds.height
//
//        if (newY == newBounds.origin.y) { self.lastBounds = contentBounds; return }
//
//        print("Adjusting y to \(newY) from \(newBounds.origin.y), max is \(self.scrollView.documentView!.bounds.height - newBounds.height)")
//
//        self.scrollView.contentView.scroll(to: NSPoint(x: newBounds.origin.x, y: newY))
//        self.scrollView.reflectScrolledClipView(self.scrollView.contentView)
////        self.scrollView.contentView.bounds = CGRect(x: 0, y: newY, width: newBounds.width, height: newBounds.height)
//        self.lastBounds = newBounds
//        self.scrollView.setNeedsDisplay(self.scrollView.bounds)
    }
    
    func geometryChange() {
        if !self.hasInitializedScroll { return }
        
        let contentView = self.scrollView.contentView
        let contentBounds = contentView.bounds
        guard let oldBounds = self.lastBounds else { self.lastBounds = contentBounds; return }
        
        //        print("bounds changed")
        let newBounds = contentBounds
        if oldBounds.size.equalTo(newBounds.size) { self.lastBounds = contentBounds; return }
//        let newY = oldBounds.origin.y + oldBounds.height - newBounds.height
        let newY = oldBounds.maxY - newBounds.height
        
        if (newY == newBounds.origin.y) { self.lastBounds = contentBounds; return }
        
        print("Adjusting y to \(newY) from \(newBounds.origin.y), max is \(self.scrollView.documentView!.bounds.height - newBounds.height)")
        
        let newOrigin = NSPoint(x: newBounds.origin.x, y: newY)
        let finalBounds = CGRect(origin: newOrigin, size: newBounds.size)
//        self.scrollView.contentView.scroll(to: newOrigin)
//        self.scrollView.reflectScrolledClipView(self.scrollView.contentView)
        //        self.scrollView.reflectScrolledClipView(self.scrollView.contentView)
        self.scrollView.contentView.bounds = finalBounds
        
        self.lastBounds = finalBounds
        //        self.scrollView.setNeedsDisplay(self.scrollView.bounds)

    }

    @objc func viewFrameChanged(_ notification : NSNotification) {
        self.geometryChange()
    }

}

