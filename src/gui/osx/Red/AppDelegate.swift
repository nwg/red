//
//  AppDelegate.swift
//  Red
//
//  Created by Nathaniel W Griswold on 6/11/20.
//  Copyright © 2020 ManicMind. All rights reserved.
//

import Cocoa
import RedLib


//@NSApplicationMain
@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var mainMenu: NSMenu!
    var racketThread : Thread!
    var clientQueue = DispatchQueue(label: "RedLib client")
    var racketPid : pid_t = 0

    private var ctx : UnsafeMutableRawPointer!
    private var socket : UnsafeMutableRawPointer!
    private var outputPipe: [Int32] = [-1, -1]
    private var inputPipe: [Int32] = [-1, -1]

//    var scrollVC : ScrollViewController!
//    var textVC : MMTextViewController!

    var tilingTest : MMTilingTest!
    
    static func main() {
        var sigs : sigset_t = 0
        sigemptyset(&sigs)
        sigaddset(&sigs, SIGCHLD)

        pthread_sigmask(SIG_BLOCK, &sigs, nil)
        
        _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
    }
    
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

        let pid = String(ProcessInfo.processInfo.processIdentifier)
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(),
                                            isDirectory: true)
        let bundleDir = temporaryDirectoryURL.appendingPathComponent(Bundle.main.bundleIdentifier!, isDirectory: true)
        
        
        do {
            try FileManager.default.createDirectory(at: bundleDir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Error creating socket")
            NSApplication.shared.terminate(self)
        }
        
        
        let socketFile = bundleDir.appendingPathComponent(String(pid))

        print("Running on socket \(socketFile.path)")
        
        ctx = zmq_init(1)
        socket = zmq_socket(ctx, ZMQ_REQ);
        zmq_connect(socket, "ipc://".appending(socketFile.path))

        let racketPath = Bundle.main.url(forResource: "racket", withExtension: nil)!
//        let runServer = Bundle.main.url(forResource: "run-server", withExtension: "rkt")!
        let collects = Bundle.main.resourceURL!.appendingPathComponent("collects")
        
        let home = ProcessInfo.processInfo.environment["HOME"]
        let addon = URL(fileURLWithPath: home!).appendingPathComponent(".red/Racket/addon")
        let config = URL(fileURLWithPath: home!).appendingPathComponent(".red/Racket/etc")

        let args = [ racketPath.path, "-X", collects.path, "-A", addon.path, "-G", config.path, "-l", "red-dispatch", "--", socketFile.path ]
//        let args = [ "/bin/echo", "-t", runServer.absoluteString, "--", socketFile.absoluteString ]
//        let args = [ "/bin/cat" ]
        let argv: [UnsafeMutablePointer<CChar>?] = args.map{ $0.withCString(strdup) }
        defer { for case let arg? in argv { free(arg) } }
        
        assert(pipe(&outputPipe) == 0)
        assert(pipe(&inputPipe) == 0)

        var childFDActions : posix_spawn_file_actions_t?
        posix_spawn_file_actions_init(&childFDActions)
        
        posix_spawn_file_actions_adddup2(&childFDActions, outputPipe[1], 1)
        posix_spawn_file_actions_adddup2(&childFDActions, outputPipe[1], 2)
        posix_spawn_file_actions_addclose(&childFDActions, outputPipe[0])
        posix_spawn_file_actions_addclose(&childFDActions, outputPipe[1])

        posix_spawn_file_actions_adddup2(&childFDActions, inputPipe[0], 0)
        posix_spawn_file_actions_addclose(&childFDActions, inputPipe[0])
        posix_spawn_file_actions_addclose(&childFDActions, inputPipe[1])

        let result = posix_spawn(&racketPid, argv[0], &childFDActions, nil, argv + [nil], nil)
        if result != 0 {
            let error = String(format: "%s", strerror(result))
            print("spawn failed: \(error)")
            NSApplication.shared.terminate(self)
        }

        close(outputPipe[1])
        close(inputPipe[0])

        let t = Thread {

            let buf = UnsafeMutablePointer<UInt8>.allocate(capacity: 4096)
            while true {
                let nbytes = read(self.outputPipe[0], buf, 4096 - 1)
                assert(nbytes >= 0)
                buf[nbytes] = UInt8(0)
                if (nbytes > 0) {
                    let s = String(format: "%s", buf)
                    print(s, terminator: "")
                } else if nbytes == 0 {
                    return
                } else {
                    perror("Could not read bytes")
                }
            }
        }
        t.start()

        clientQueue.async {
            var result = mm_client_init(self.socket)
            assert(result == 0)

            print("Client running load file");
            let path = NSString.path(withComponents: [Bundle.main.resourcePath!, "test.txt"])
            result = mm_client_backend_load_file(path)
            if result == 0 {
                print("Backend load file succeeded")
            }
        }
        

        self.tilingTest = MMTilingTest()
        let bounds = window.contentView!.bounds
        let frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
        tilingTest.view.frame = frame
        window.contentView?.addSubview(self.tilingTest.view)
        
        print("Content view frame is \(window.contentView!.frame)")
        
        let blah = NSString()
        takePointer(bridgeRetained(obj: blah))
        
//        racketThread = Thread(block: {
//            let racketBundle = Bundle(identifier: "org.racket-lang.Racket")
//            let bootPath = NSString.path(withComponents: [racketBundle!.bundlePath, "Versions/Current/boot"])
//            let petite = NSString.path(withComponents: [bootPath, "petite.boot"])
//            let scheme = NSString.path(withComponents: [bootPath, "scheme.boot"])
//            let racket = NSString.path(withComponents: [bootPath, "racket.boot"])
//
//            init_server(CommandLine.arguments[0], petite, scheme, racket)
//            let ctx = mm_server_get_ctx();
//
//            DispatchQueue.main.async {
//                mm_client_init(ctx);
//                print("Client running load renderer");
////                mm_client_backend_load_renderer("something")
//                let path = NSString.path(withComponents: [Bundle.main.resourcePath!, "test.txt"])
//                mm_client_backend_load_file(path)
//            }
//
//            run_server()
//        })
//        racketThread.start()
        
    }
    
    func applicationDidUpdate(_ notification: Notification) {
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        kill(racketPid, SIGTERM)
        var stat_loc : Int32 = 0
        waitpid(racketPid, &stat_loc, 0)
    }


}

