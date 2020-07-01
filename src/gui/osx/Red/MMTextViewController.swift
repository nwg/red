//
//  MMTextViewController.swift
//  Red
//
//  Created by Nathaniel W Griswold on 6/17/20.
//  Copyright © 2020 ManicMind. All rights reserved.
//

import Cocoa

class MMTextViewController: NSViewController {

    var parentScrollView : NSScrollView!
    var hasInitializedScroll = false
    @IBOutlet var textView: MMTextView!

    init(parentScrollView: NSScrollView) {
        self.parentScrollView = parentScrollView
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable) required init?(coder aDecoder: NSCoder) {
        fatalError("disabled init")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.textView.lines = [
            NSMutableAttributedString(string: "Something"),
            NSMutableAttributedString(string: "Something else"),
            NSMutableAttributedString(string: "Something else else")]


//        self.parentScrollView.documentView?.scroll(.zero)
//        if let documentView = self.parentScrollView.documentView {
//        }
//        self.parentScrollView.scrollToBeginningOfDocument(nil)
        // Do view setup here.
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        self.textView.recomputeLines()
    }
    
    override func viewWillLayout() {
        super.viewWillLayout()
//        if !self.hasInitializedScroll {
//            self.hasInitializedScroll = true
//            self.view.scroll(NSPoint(x: 0, y: self.view.bounds.size.height))
//            
//        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        self.view.autoresizingMask = .none

    }
    
    
}
