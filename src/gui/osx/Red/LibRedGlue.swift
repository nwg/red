//
//  LibRedGlue.swift
//  Red
//
//  Created by Nathaniel W Griswold on 12/14/20.
//  Copyright © 2020 ManicMind. All rights reserved.
//

import Foundation
import RedLib

public typealias RedRenderInfo = red_render_info_t
public typealias RedTile = red_tile_t
public typealias RedBounds = red_bounds_t

class RenderInfoScrollViewDataSource : MMTextScrollViewDataSource {
    var tiles = [UnsafeBufferPointer<RedTile>]()
    var info : RedRenderInfo
    
    init(_ info: RedRenderInfo) {
        self.info = info
        for i in 0..<Int(info.rows) {
            withUnsafePointer(to: &self.info.tiles.0.0) { (ptr) in
                let buffer = UnsafeBufferPointer(start: ptr + i * Int(info.cols), count: Int(info.cols))
                tiles.append(buffer)
            }
        }
    }
    
    func contentSize() -> CGSize {
        return CGSize(width: self.tileWidth() * self.cols(), height: self.tileHeight() * self.rows())
    }
    
    func data(i: Int, j: Int) -> NSData {
        let tile = self.tiles[i][j]
        let size = Int(tile.w) * Int(tile.h) * 4
        return NSData(bytesNoCopy: tile.data!, length: size, freeWhenDone: false)
    }
    
    func frame(i: Int, j: Int) -> CGRect {
        let tile = self.tiles[i][j]
        let size = self.contentSize()
        return CGRect(x: Int(tile.x), y: Int(size.height) - self.tileHeight() - Int(tile.y), width: Int(tile.w), height: Int(tile.h))
    }
    
    func rows() -> Int {
        return Int(info.rows)
    }

    func cols() -> Int {
        return Int(info.cols)
    }

    func tileWidth() -> Int {
        guard let t = anyTile() else { return 0 }
        return Int(t.w)
    }

    func tileHeight() -> Int {
        guard let t = anyTile() else { return 0 }
        return Int(t.h)
    }

    func anyTile() -> RedTile? {
        guard let first = tiles.first else { return .none }
        guard let tile = first.first else { return .none }
        return tile
    }
}
