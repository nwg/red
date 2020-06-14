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

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        scrollVC = ScrollViewController(menu: mainMenu, frame: window.contentView!.frame)
        window.contentViewController = scrollVC
//        scrollVC!.view.frame = window.contentView!.frame
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

