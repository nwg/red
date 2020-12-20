//
//  MMTextScrollView.swift
//  Red
//
//  Created by Nathaniel W Griswold on 10/1/20.
//  Copyright © 2020 ManicMind. All rights reserved.
//

import Cocoa
import RedLib

protocol MMTextScrollViewDataSource {
    func rows() -> Int
    func cols() -> Int
    func tileSize() -> CGSize
    func data(i: Int, j: Int) -> NSData?
    func frame(i: Int, j: Int) -> CGRect?
    func contentSize() -> CGSize
}

class MMTextScrollView: NSView, NibLoadable {

    @objc @IBOutlet dynamic weak var scrollView: NSScrollView!
    @IBOutlet weak var portalContentView: NSView!
    weak var textPortalView : MMTextPortalView?
    var dataSource : MMTextScrollViewDataSource? {
        set {
            if let dataSource = newValue {
                self.dataSourceInternal = dataSource
                self.updateForNewDataSource(dataSource)
            } else {
                self.dataSourceInternal = .none
            }
        }
        
        get {
            return self.dataSourceInternal
        }
    }
    var dataSourceInternal : MMTextScrollViewDataSource?
    var dataViews : [[MMTextPortalView?]]!
    var documentView : NSView?
    private var sendsBounds = false

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.scrollView.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(self, selector: #selector(self.observe(_:)), name: NSView.boundsDidChangeNotification, object: self.scrollView.contentView)
        
    }
    
    func startSendingBounds() {
        self.sendsBounds = true
    }
    
    @objc func observe(_ notif : NSNotification) {
        if !self.sendsBounds { return }
        
        var bounds = self.scrollView!.contentView.bounds
        if let tileSize = self.dataSource?.tileSize() {
            bounds.origin.y = self.scrollView!.documentView!.frame.size.height - bounds.origin.y - CGFloat(tileSize.height) / 2
            let delegate = NSApplication.shared.delegate as? AppDelegate
            bounds = CGRect(x: bounds.minX * 2, y: bounds.minY * 2, width: bounds.width * 2, height: bounds.height * 2)
            delegate?.setBounds(bounds)
        }
    }
    
    func syncPortalView(i : Int, j : Int) {
        if let dataSource = self.dataSourceInternal {
            if let frame = dataSource.frame(i: i, j: j) {
                var portalView : MMTextPortalView
                if let view = self.dataViews[i][j] {
                    portalView = view
                    if let data = dataSource.data(i: i, j: j) {
                        portalView.reload(data: data)
                    }
                } else {
                    guard let view = MMTextPortalView.createFromNib() else { return }
                    self.dataViews[i][j] = view
                    portalView = view
                    if let data = dataSource.data(i: i, j: j) {
                        portalView.setupImage(data: data, size: dataSource.tileSize())
                    }
                }
                portalView.frame = frame
                self.documentView!.addSubview(portalView)
            }
        }
    }
    
    func updateForNewDataSource(_ dataSource : MMTextScrollViewDataSource) {
        let contentSize = dataSource.contentSize()
        self.documentView = NSView(frame: CGRect(origin: .zero, size: contentSize))
        self.scrollView.documentView = self.documentView
        
        let y = contentSize.height
        self.scrollView.contentView.scroll(NSPoint(x: 0, y: y))
        
        self.dataViews = makeEmpty2D(dataSource.rows(), dataSource.cols())
        
        for i in 0..<dataSource.rows() {
            for j in 0..<dataSource.cols() {
                self.syncPortalView(i: i, j: j)
            }
            
        }
        
    }
    
    func dataDidChange(i: Int, j: Int) {
        self.syncPortalView(i: i, j: j)
    }
        
}
