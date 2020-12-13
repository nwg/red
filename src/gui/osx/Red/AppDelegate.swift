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
    
    private var bytes : UnsafeMutableRawPointer?

    var textScrollView : MMTextScrollView!
    
    static func main() {
        var sigs : sigset_t = 0
        sigemptyset(&sigs)
        sigaddset(&sigs, SIGCHLD)

        pthread_sigmask(SIG_BLOCK, &sigs, nil)
        
        _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.textScrollView = MMTextScrollView.createFromNib()
        let bounds = window.contentView!.bounds
        let frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
        self.textScrollView.frame = frame
        
                
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

            let width = 1600
            let height = 1200
            let size = width * height * 4
            
            self.bytes = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: 4096)
            var memory : OpaquePointer?
            var result = libred_register_memory(self.bytes, size, &memory)
            if result != 0 { abort() }
            
            var portal : OpaquePointer?
            result = libred_open_portal(memory, Int32(width), Int32(height), &portal)
            if result != 0 { abort() }

            var buffer : OpaquePointer?
            result = libred_create_buffer(&buffer)
            if result != 0 { abort() }
            
            result = libred_buffer_open_file(buffer, "/tmp/big-file.txt")
            if result != 0 { abort() }
            result = libred_draw_buffer_in_portal(buffer, portal)
            if result != 0 { abort() }
            
            
            DispatchQueue.main.async {
                let bound = self.bytes?.bindMemory(to: UInt8.self, capacity: size)
                let data = CFDataCreateWithBytesNoCopy(nil, bound, size, nil)
                self.textScrollView!.textPortalView!.setupImage(data: data!, width: width, height: height)
                self.textScrollView.frame = CGRect(x: 0, y: 0, width: width/2, height: height/2)
                var frame = self.window.frame
                frame.size = CGSize(width: width/2, height: height/2)
                frame = NSWindow.frameRect(forContentRect: frame, styleMask: self.window.styleMask)
                self.window.setFrame(frame, display: true)
                self.window.contentView?.addSubview(self.textScrollView)
                self.window.makeKeyAndOrderFront(self)
                NSApplication.shared.activate(ignoringOtherApps: true)
            }

        }
    }
    
    func applicationDidUpdate(_ notification: Notification) {
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        kill(racketPid, SIGTERM)
        var stat_loc : Int32 = 0
        waitpid(racketPid, &stat_loc, 0)
    }


}

