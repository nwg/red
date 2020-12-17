//
//  MMTextScrollView.swift
//  Red
//
//  Created by Nathaniel W Griswold on 10/1/20.
//  Copyright © 2020 ManicMind. All rights reserved.
//

import Cocoa

protocol MMTextScrollViewDataSource {
    func rows() -> Int
    func cols() -> Int
    func tileWidth() -> Int
    func tileHeight() -> Int
    func data(i: Int, j: Int) -> NSData
    func frame(i: Int, j: Int) -> CGRect
    func contentSize() -> CGSize
}

class MMTextScrollView: NSView, NibLoadable {

    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var portalContentView: NSView!
    weak var textPortalView : MMTextPortalView?
    var dataSource : MMTextScrollViewDataSource?
    var cachedData : [[NSData]]?
    var dataViews : [[MMTextPortalView]]?
    var documentView : NSView?
    
    func dataDidChange(_ i : Int, _ j : Int) {
        let view = self.dataViews![i][j]
        view.reload()
    }
    
    func reloadData() {
        var contentSize = self.dataSource!.contentSize()
        contentSize = CGSize(width: contentSize.width/2, height: contentSize.height/2)
        self.documentView = NSView(frame: CGRect(origin: .zero, size: contentSize))
        self.scrollView.documentView = self.documentView
        self.cachedData = nil
        guard let dataSource = self.dataSource else { return }

        self.cachedData = [[NSData]]()
        self.dataViews = [[MMTextPortalView]]()
        
        for i in 0..<dataSource.rows() {
            var cachedDataCol = Array<NSData>()
            self.cachedData?.append(cachedDataCol)
            
            var dataViewsCol = [MMTextPortalView]()
            for j in 0..<dataSource.cols() {
                let data = dataSource.data(i: i, j: j)
                cachedDataCol.append(data)
                
                if let portalView = MMTextPortalView.createFromNib() {
                    var frame = dataSource.frame(i: i, j: j)
                    frame = CGRect(x: frame.minX / 2, y: frame.minY / 2, width: frame.width / 2, height: frame.height / 2)
                    portalView.frame = frame
                    portalView.setupImage(data: data, width: dataSource.tileWidth(), height: dataSource.tileHeight())
                    self.documentView!.addSubview(portalView)
                    dataViewsCol.append(portalView)
                }
            }
            
            self.dataViews?.append(dataViewsCol)
        }
        
    }
    
}
