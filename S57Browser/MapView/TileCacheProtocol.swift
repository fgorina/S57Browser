//
//  TileCache.swift
//  tracesuitest
//
//  Created by Francisco Gorina Vanrell on 15/02/2020.
//  Copyright © 2020 Francisco Gorina Vanrell. All rights reserved.
//

import Foundation
import MapKit

protocol TileCacheProtocol {
    
    func getTile(_ path: MKTileOverlayPath) throws -> Data?
    func addTile(_ path: MKTileOverlayPath, data: Data) throws
    func cacheName() -> String
    func isTileInCache(_ path: MKTileOverlayPath) -> Bool
    func removeTile(_ path: MKTileOverlayPath) throws
}
