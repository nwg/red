//
//  AppDelegate.swift
//  Red
//
//  Created by Nathaniel W Griswold on 6/11/20.
//  Copyright © 2020 ManicMind. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var mainMenu: NSMenu!
    
    var scrollVC : ScrollViewController!
    var textVC : MMTextViewController!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
//        scrollVC!.view.frame = window.contentView!.frame
        //        let frameSize = window.contentRect(forFrameRect: window.frame)
//        scrollVC = ScrollViewController(menu: mainMenu, frame: window.contentView!.frame)
//        window.contentViewController = scrollVC
//        window.contentViewController = scrollVC
        
//        window.titlebarAppearsTransparent = true
        scrollVC = ScrollViewController()
        
//        textVC = MMTextViewController(nibName: nil, bundle: nil)
        let bounds = window.contentView!.bounds
        let frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
//        scrollVC.view.frame = window.contentView!.bounds
        window.contentView?.addSubview(scrollVC.view)
        scrollVC.view.frame = frame
        
        print("Content view frame is \(window.contentView!.frame)")
        
        let blah = NSString()
        takePointer(bridgeRetained(obj: blah))
        
//        scrollVC.view.layer.
    }
    
    func applicationDidUpdate(_ notification: Notification) {
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

