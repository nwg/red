//
//  ScrollViewController.swift
//  Red
//
//  Created by Nathaniel W Griswold on 6/14/20.
//  Copyright © 2020 ManicMind. All rights reserved.
//

import Cocoa

//class MyTextResponder : NSResponder {
//    var textView : MyTextView!
//
//    convenience init(forView: MyTextView) {
//        self.init()
//        self.textView = forView
//    }
//
//    override func keyDown(with event: NSEvent) {
//        print("Key down")
//    }
//}

class MyTextView : NSView, NSTextInputClient {
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func insertText(_ string: Any, replacementRange: NSRange) {
        
    }
    
    func setMarkedText(_ string: Any, selectedRange: NSRange, replacementRange: NSRange) {
        
    }
    
    func unmarkText() {
        
    }
    
    func selectedRange() -> NSRange {
        return NSRange(location: 0, length: 0)
    }
    
    func markedRange() -> NSRange {
        return NSRange(location: 0, length: 0)
    }
    
    func hasMarkedText() -> Bool {
        return false
    }
    
    func attributedSubstring(forProposedRange range: NSRange, actualRange: NSRangePointer?) -> NSAttributedString? {
        return NSAttributedString(string: "Something")
    }
    
    func validAttributesForMarkedText() -> [NSAttributedString.Key] {
        return []
    }
    
    func firstRect(forCharacterRange range: NSRange, actualRange: NSRangePointer?) -> NSRect {
        return NSRect(origin: .zero, size: CGSize(width: 20, height: 40))
    }
    
    func characterIndex(for point: NSPoint) -> Int {
        return 0
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func becomeFirstResponder() -> Bool {
        return true
    }
    
    override func resignFirstResponder() -> Bool {
        return true
    }
    
    override func keyDown(with event: NSEvent) {
        print("Key down")
        self.inputContext?.handleEvent(event)
    }
    
    override func deleteBackward(_ sender: Any?) {
        
    }
    
    override func doCommand(by selector: Selector) {
        super.doCommand(by: selector)
    }
    
    override func insertNewline(_ sender: Any?) {
        
    }
}

class ScrollViewController: NSViewController {

    @IBOutlet var scrollView: NSScrollView!
    var initialFrame : CGRect = CGRect(origin: .zero, size: CGSize(width: 100, height: 100))
    var textView : NSTextView!
    var myView : NSView!
    
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
//        let textStorage = NSTextStorage()
//        let manager = NSLayoutManager()
//        let container = NSTextContainer(size: NSSize(width: self.view.frame.size.width, height: self.view.frame.size.height))
//        let textView = NSTextView(frame: NSRect(origin: .zero,
//                                                size: NSSize(width: self.view.frame.size.width, height: self.view.frame.size.height)),
//                                  textContainer: container)
//        textView.isEditable = true
//        textView.isSelectable = true
//        textView.textColor = NSColor.white
//        self.textView = textView
        self.myView = MyTextView(frame: NSRect(origin: .zero, size: NSSize(width: self.view.frame.size.width, height: self.view.frame.size.height)))
        self.myView.wantsLayer = true
        self.myView.layer?.backgroundColor = NSColor.red.cgColor
        self.myView.becomeFirstResponder()
        
        

//        textStorage.addLayoutManager(manager)
//        manager.addTextContainer(container)
//        let delegate = TextViewDelegate()
//        textView.delegate = delegate
        let documentView = NSView(frame: CGRect(origin: .zero, size: CGSize(width: self.view.frame.size.width, height: 2000)))
        documentView.wantsLayer = true
        documentView.layer?.backgroundColor = NSColor.green.cgColor
        documentView.addSubview(myView)
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

        self.myView.frame = clipView.bounds
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
