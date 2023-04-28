//
//  MBTileCache.swift
//  ChartCalculator
//
//  Created by Francisco Gorina Vanrell on 27/3/23.
//

import Foundation
import Foundation
import MapKit

class MBTileCache : TileCacheProtocol {
    
    var store : MBTileStore
    var name : String
    
    init(_ name : String) throws {
        
    
        if !name.hasSuffix(".mbtiles"){
            self.name = name.appending(".mbtiles")
        }else {
            self.name = name
        }
        let url = MBTileOverlay.URLforDatabase(self.name)
        
        // Check if exists
        
        if FileManager.default.fileExists(atPath: url.path){
            store = try MBTileStore.getStoreFor(url, readOnly: false)
        }else {
            store = try MBTileStore.createMBTileStoreDatabase(url, nameOfChart: name, format: .png, type: .baselayer, bounds: MKCoordinateRegion.world)
        }
    }
    
    func getTile(_ path: MKTileOverlayPath) throws -> Data? {
        return store.loadTile(at: path)
    }
    
    func addTile(_ path: MKTileOverlayPath, data: Data) throws {
        store.insertTile(at: path, data: data)
    }
    
    func cacheName() -> String {
        return name
    }
    
    func isTileInCache(_ path: MKTileOverlayPath) -> Bool {
        return store.checkTileExists(at: path)
    }
    
    func removeTile(_ path: MKTileOverlayPath) throws {
        store.removeTile(at: path)
    }
}

