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
    
    var topPanel: PanelViewController!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        topPanel = PanelViewController(menu: mainMenu)
        topPanel.view.frame = window.contentView!.frame
        
        let firstVC = PanelViewController(menu: mainMenu)
        topPanel.splitViewItems = [ NSSplitViewItem(viewController: firstVC) ]
        
        window.contentViewController = topPanel
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

