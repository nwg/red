//
//  AppDelegate.swift
//  Red
//
//  Created by Nathaniel W Griswold on 6/11/20.
//  Copyright © 2020 ManicMind. All rights reserved.
//

import Cocoa
import RedLib
import Racket


//@NSApplicationMain
@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var mainMenu: NSMenu!
    var racketThread : Thread!
    var clientQueue = DispatchQueue(label: "RedLib client")
    var racketPid : pid_t = 0

    private var outputPipe: [Int32] = [-1, -1]
    private var inputPipe: [Int32] = [-1, -1]
    
    private var buffer : OpaquePointer?
    private var portal : OpaquePointer?

    private var bytes : UnsafeMutableRawPointer?

    var textScrollView : MMTextScrollView!
    var dataSource : RenderInfoScrollViewDataSource!
    
    static func main() {
        var sigs : sigset_t = 0
        sigemptyset(&sigs)
        sigaddset(&sigs, SIGCHLD)

        pthread_sigmask(SIG_BLOCK, &sigs, nil)
        
        InitializeRedGlue()
        _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let width = 1600
        let height = 1200

        self.textScrollView = MMTextScrollView.createFromNib()
        var frame = self.window.frame
        frame.size = CGSize(width: width/2, height: height/2)
        frame = NSWindow.frameRect(forContentRect: frame, styleMask: self.window.styleMask)
        self.window.setFrame(frame, display: true)
        self.window.contentView?.addSubview(self.textScrollView)
        let contentRect = CGRect(x: 0, y: 0, width: width/2, height: height/2)
        self.textScrollView.frame = contentRect
        
        let bundle = Bundle(identifier: "org.racket-lang.Racket")!
        let petite = bundle.bundleURL.appendingPathComponent("Versions/Current/boot/petite.boot")
        let scheme = bundle.bundleURL.appendingPathComponent("Versions/Current/boot/scheme.boot")
        let racket = bundle.bundleURL.appendingPathComponent("Versions/Current/boot/racket.boot")
        
        let startTime = DispatchTime.now()
        
        let initialized = DispatchSemaphore(value: 0)
        
        let t = Thread {
            libred_init("Red", petite.path, scheme.path, racket.path)
            initialized.signal()
            libred_run()
        }
        
        t.start()

        let client_queue = DispatchQueue(label: "Client")

        client_queue.async {
            initialized.wait()
            let elapsed = DispatchTime.now().uptimeNanoseconds - startTime.uptimeNanoseconds
            print("Startup took \(elapsed/1000000)ms")
        }

        client_queue.async {

            var result : Int32
            result = libred_create_buffer(&self.buffer)
            if result != 0 { abort() }

            result = libred_buffer_open_file(self.buffer, "/tmp/big-file.txt")
            if result != 0 { abort() }
            
            result = libred_open_portal(self.buffer, Int32(width), Int32(height), &self.portal)
            if result != 0 { abort() }

            var info = RedRenderInfo()
            result = libred_get_render_info(self.portal, &info)
            self.dataSource = RenderInfoScrollViewDataSource(info)
            
            self.clientQueue.asyncAfter(deadline: .now() + 1) {
                let b = RedBounds(x:0, y:0, w: UInt64(width), h: UInt64(height))
                result = libred_set_current_bounds(self.buffer, b)
            }
                
            DispatchQueue.main.async {
                self.textScrollView!.dataSource = self.dataSource
                self.textScrollView.startSendingBounds()
                self.window.makeKeyAndOrderFront(self)
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
        }
    }
    
    func setBounds(_ bounds : CGRect) {
        let redBounds = red_bounds_t(x: UInt64(max(bounds.minX, 0)), y: UInt64(max(bounds.minY, 0)), w: UInt64(bounds.width), h: UInt64(bounds.height))
        libred_set_current_bounds(self.portal, redBounds)
    }
    
    func applicationDidUpdate(_ notification: Notification) {
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        kill(racketPid, SIGTERM)
        var stat_loc : Int32 = 0
        waitpid(racketPid, &stat_loc, 0)
    }


}

