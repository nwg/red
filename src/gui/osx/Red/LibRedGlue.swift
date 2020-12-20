//
//  LibRedGlue.swift
//  Red
//
//  Created by Nathaniel W Griswold on 12/14/20.
//  Copyright © 2020 ManicMind. All rights reserved.
//

import Cocoa
import RedLib

public typealias RedRenderInfo = red_render_info_t;
public typealias RedTile = red_tile_t
public typealias RedBounds = red_bounds_t
public typealias RedTileMove = red_tile_move_t

struct TileMove {
    var iFrom : Int
    var jFrom : Int
    var iTo : Int
    var jTo : Int
}

func tileDidChange(_ tile : UnsafeMutablePointer<RedTile>?) {
    if let theTile = tile?.pointee {
        DispatchQueue.main.async {
            let delegate = NSApplication.shared.delegate as? AppDelegate
            let dataSource = delegate?.dataSource
            dataSource?.update(tile: theTile)
            let view = delegate?.textScrollView
            view?.dataDidChange(i: Int(theTile.i), j: Int(theTile.j))
        }
    }
}

func tileDidMove(_ moves : UnsafeMutablePointer<RedTileMove>?, len : Int32) {
    var arr = [TileMove]()
    guard let moves = moves else { return }
    for i in 0..<Int(len) {
        let smove = moves[i]
        arr.append(TileMove(iFrom: Int(smove.from_i), jFrom: Int(smove.from_j), iTo: Int(smove.to_i), jTo: Int(smove.to_j)))
    }
    DispatchQueue.main.async {
        let delegate = NSApplication.shared.delegate as? AppDelegate
        let dataSource = delegate?.dataSource
        dataSource?.processMoves(moves: arr)
        let view = delegate?.textScrollView
        view?.dataDidMove(moves: arr)
    }

}

func tileWasDeleted(_ tile : UnsafeMutablePointer<RedTile>?) {
    if let theTile = tile?.pointee {
        DispatchQueue.main.async {
            let delegate = NSApplication.shared.delegate as? AppDelegate
            let dataSource = delegate?.dataSource
            dataSource?.delete(tile: theTile)
            let view = delegate?.textScrollView
            view?.dataWasDeleted(i: Int(theTile.i), j: Int(theTile.j))
        }
    }
}

func InitializeRedGlue() {
    libred_set_tile_did_change_callback(tileDidChange)
    libred_set_tile_did_move_callback(tileDidMove)
    libred_set_tile_was_deleted_callback(tileWasDeleted)
}

func makeEmpty2D<T>(_ rows : Int, _ cols : Int) -> [[T?]] {
    return [[T?]].init(
        repeating: [T?].init(repeating: .none, count: cols),
        count: rows)
}

class RenderInfoScrollViewDataSource : MMTextScrollViewDataSource {
    var info : RedRenderInfo
    var data : [[NSData?]]
    var tiles : [[RedTile?]]
    
    init(_ info: RedRenderInfo) {
        self.info = info
        self.data = makeEmpty2D(Int(self.info.rows), Int(self.info.cols))
        self.tiles = makeEmpty2D(Int(self.info.rows), Int(self.info.cols))
    }
    
    func update(tile: RedTile) {
        let i = Int(tile.i)
        let j = Int(tile.j)
        self.data[i][j] = NSData(bytesNoCopy: tile.data!, length: self.bytesPerTile(), freeWhenDone: false)
        self.tiles[i][j] = tile
    }

    func processMoves(moves: [TileMove]) {
        var newTiles = self.tiles
        var newData = self.data
        for move in moves {
            newData[move.iTo][move.jTo] = self.data[move.iFrom][move.jFrom]
            newData[move.iFrom][move.jFrom] = .none
            newTiles[move.iTo][move.jTo] = self.tiles[move.iFrom][move.jFrom]
            newTiles[move.iFrom][move.jFrom] = .none
        }
        
        self.data = newData
        self.tiles = newTiles
    }

    func delete(tile: RedTile) {
        let i = Int(tile.i)
        let j = Int(tile.j)
        self.data[i][j] = .none
        self.tiles[i][j] = .none
    }
    
    func bytesPerTile() -> Int {
        return 4 * Int(self.info.tile_width) * Int(self.info.tile_height)
    }
    
    func contentSize() -> CGSize {
        return CGSize(width: Int(self.info.total_width / 2), height: Int(self.info.total_height / 2))
    }
    
    func data(i: Int, j: Int) -> NSData? {
        return self.data[i][j]
    }
        
    func frame(i: Int, j: Int) -> CGRect? {
        let size = self.contentSize()
        guard let tile = tiles[i][j] else { return .none }
        let y = Int(size.height) - Int(tile.y / 2) - Int(tile.h / 2)
        let frame = CGRect(x: Int(tile.x / 2), y: y, width: Int(tile.w / 2), height: Int(tile.h / 2))
        return frame
    }
    
    func rows() -> Int {
        return Int(info.rows)
    }

    func cols() -> Int {
        return Int(info.cols)
    }

    func tileWidth() -> Int {
        return Int(self.info.tile_width)
    }

    func tileHeight() -> Int {
        return Int(self.info.tile_height)
    }
    
    func tileSize() -> CGSize {
        return CGSize(width: self.tileWidth(), height: self.tileHeight())
    }

    func anyTile() -> RedTile? {
        for i in 0 ..< Int(self.info.rows) {
            for j in 0 ..< Int(self.info.cols) {
                if let tile = self.tiles[i][j] {
                    return tile
                }
            }
        }
        return .none
    }
}
