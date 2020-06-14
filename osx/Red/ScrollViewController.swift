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
    var initialFrame : CGRect = CGRect(origin: .zero, size: CGSize(width: 100, height: 100))
    var textView : NSTextView!
    
    convenience init(menu: NSMenu, frame: CGRect) {
        self.init(nibName: nil, bundle: nil)
        self.initialFrame = frame
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.frame = self.initialFrame
//        let textView = NSTextView(
//            frame: NSRect(origin: .zero, size: CGSize(width: self.view.frame.size.width, height: 2000)),
//            textContainer: NSTextContainer(containerSize: NSSize(width: self.view.frame.size.width, height: self.view.frame.size.height)))
        let textStorage = NSTextStorage()
        let manager = NSLayoutManager()
        let container = NSTextContainer(size: NSSize(width: self.view.frame.size.width, height: self.view.frame.size.height))
        let textView = NSTextView(frame: NSRect(origin: .zero,
                                                size: NSSize(width: self.view.frame.size.width, height: self.view.frame.size.height)),
                                  textContainer: container)
        textView.isEditable = true
        textView.isSelectable = true
        textView.textColor = NSColor.white
        self.textView = textView

        textStorage.addLayoutManager(manager)
        manager.addTextContainer(container)
        let delegate = TextViewDelegate()
        textView.delegate = delegate
        let documentView = NSView(frame: CGRect(origin: .zero, size: CGSize(width: self.view.frame.size.width, height: 2000)))
        documentView.wantsLayer = true
        documentView.layer?.backgroundColor = NSColor.green.cgColor
        documentView.addSubview(textView)
        self.scrollView.documentView = documentView
        self.scrollView.backgroundColor = NSColor.green
        self.scrollView.contentView.scroll(to: .zero)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(boundsDidChange),
                                               name: NSView.boundsDidChangeNotification,
                                               object: scrollView.contentView)

//        self.scrollView.contentView.scrollToBeginningOfDocument(nil)
    }
    
    @objc func boundsDidChange(notification: NSNotification) {
        let clipView = notification.object as! NSClipView

        self.textView.frame = clipView.bounds
    }
    
}

class TextViewDelegate : NSObject, NSTextViewDelegate {
    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        return true
    }
    
//    func textDidChange(_ notification: Notification) {
//        let textObject = notification.object as! NSTextView
//        //            print("text now: \(String(describing: textObject.string))")
//        self.parent.text = textObject.string
//    }

}
