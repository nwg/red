//
//  AppDelegate.swift
//  Red
//
//  Created by Nathaniel W Griswold on 6/11/20.
//  Copyright © 2020 ManicMind. All rights reserved.
//

import Cocoa
import RedLib


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var mainMenu: NSMenu!
    var racketThread : Thread!
    
//    var scrollVC : ScrollViewController!
//    var textVC : MMTextViewController!

    var tilingTest : MMTilingTest!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
//        scrollVC!.view.frame = window.contentView!.frame
        //        let frameSize = window.contentRect(forFrameRect: window.frame)
//        scrollVC = ScrollViewController(menu: mainMenu, frame: window.contentView!.frame)
//        window.contentViewController = scrollVC
//        window.contentViewController = scrollVC
        
//        window.titlebarAppearsTransparent = true
//        scrollVC = ScrollViewController()
//
////        textVC = MMTextViewController(nibName: nil, bundle: nil)
//        let bounds = window.contentView!.bounds
//        let frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
////        scrollVC.view.frame = window.contentView!.bounds
        
        self.tilingTest = MMTilingTest()
        let bounds = window.contentView!.bounds
        let frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
        tilingTest.view.frame = frame
        window.contentView?.addSubview(self.tilingTest.view)
        
        print("Content view frame is \(window.contentView!.frame)")
        
        let blah = NSString()
        takePointer(bridgeRetained(obj: blah))
        
        racketThread = Thread(block: {
            let racketBundle = Bundle(identifier: "org.racket-lang.Racket")
            let bootPath = NSString.path(withComponents: [racketBundle!.bundlePath, "Versions/Current/boot"])
            let petite = NSString.path(withComponents: [bootPath, "petite.boot"])
            let scheme = NSString.path(withComponents: [bootPath, "scheme.boot"])
            let racket = NSString.path(withComponents: [bootPath, "racket.boot"])

            init_server(CommandLine.arguments[0], petite, scheme, racket)
            let ctx = mm_server_get_ctx();

            DispatchQueue.main.async {
                mm_client_init(ctx);
                print("Client running load renderer");
//                mm_client_backend_load_renderer("something")
                mm_client_backend_load_file("test.txt")
            }
            
            run_server()
        })
        racketThread.start()
        
    }
    
    func applicationDidUpdate(_ notification: Notification) {
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

