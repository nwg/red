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
        window.contentView?.addSubview(self.textScrollView)

//
//        let path = "/tmp/test.txt"
//        clientQueue.async {
//            print("Running on socket \(socketFile.path)")
//
//
//            var result = libred_init("ipc://".appending(socketFile.path))
//            if result != 0 { abort() }
//
//            var buf : OpaquePointer?
//            result = libred_load_file(path, &buf)
//            if result != 0 { abort() }
            
//            let width = 800
//            let height = 600
//            let size = width * height * 4
//
//            var shm : OpaquePointer?
//            result = libred_create_and_attach_shared_memory(size, &shm)
//            if result != 0 { abort() }
//
//            var portal : OpaquePointer?
//            result = libred_open_portal(shm, Int32(width), Int32(height), &portal)
//            if result != 0 { abort() }
//
//            result = libred_draw_buffer_in_portal(buf, portal)
//            if result != 0 { abort() }
            

//            DispatchQueue.main.async {
//                let addr = libred_shm_get_addr(shm)
//                let bytes = addr?.bindMemory(to: UInt8.self, capacity: size)
//                let data = CFDataCreateWithBytesNoCopy(nil, bytes, size, nil)
//                self.textScrollView!.textPortalView!.setupImage(data: data!, width: width, height: height)
//            }
//        }
                
        let bundle = Bundle(identifier: "org.racket-lang.Racket")!
        let petite = bundle.bundleURL.appendingPathComponent("Versions/Current/boot/petite.boot")
        let scheme = bundle.bundleURL.appendingPathComponent("Versions/Current/boot/scheme.boot")
        let racket = bundle.bundleURL.appendingPathComponent("Versions/Current/boot/racket.boot")
        
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
        }

        client_queue.async {
            let bytes = UnsafeMutableRawPointer.allocate(byteCount: 4096, alignment: 4096)
            var memory : OpaquePointer?
            let result = libred_register_memory(bytes, 10, &memory)
            print("Result was \(result)")
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

