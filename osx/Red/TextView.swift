//
//  TextView.swift
//  Red
//
//  Created by Nathaniel W Griswold on 6/8/20.
//  Copyright © 2020 ManicMind. All rights reserved.
//

import SwiftUI

class MyTextView : NSTextView {
//    override func mouseDown(with event: NSEvent) {
//        print("Mouse Down")
//    }
}

struct TextView: NSViewRepresentable {
    @Binding var text: String
    typealias NSViewType = NSScrollView

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        let textView : MyTextView = nsView.documentView as! MyTextView
        guard textView.string != text else { return }
        textView.string = text
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        
        let myScrollView = MyTextView.scrollableTextView()
        let myTextView = myScrollView.documentView as! MyTextView
        myTextView.delegate = context.coordinator
        
        myTextView.font = NSFont(name: "HelveticaNeue", size: 15)
//        myTextView.scroll = true
        myTextView.isEditable = true
//        myTextView.isUserInteractionEnabled = true
        myTextView.backgroundColor = NSColor(white: 0.0, alpha: 0.1)
        
        return myScrollView
    }
    
    class Coordinator : NSObject, NSTextViewDelegate {

        var parent: TextView

        init(_ uiTextView: TextView) {
            self.parent = uiTextView
        }

        func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            return true
        }
                
        func textDidChange(_ notification: Notification) {
            let textObject = notification.object as! NSTextView
//            print("text now: \(String(describing: textObject.string))")
            self.parent.text = textObject.string
        }
        
        
        
    }
}
