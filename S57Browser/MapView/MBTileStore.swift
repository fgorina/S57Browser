//
//  MBTileStore.swift
//  ChartCalculator
//
//  Created by Francisco Gorina Vanrell on 22/3/23.
//

import Foundation
import MapKit
import SQLite

class MBTileStore {
    
    static var openedStores : [URL : MBTileStore] = [:]
    
    enum storeType : String {
        case baselayer = "baselayer"
        case overlay = "overlay"
    }
    
    enum tileFormat : String {
        case jpg = "jpg"
        case png = "png"
        case pbf = "pbf"
        case webp = "wepb"
    }
    var url : URL
    var db : Connection?
    var name : String = ""
    var format : tileFormat = .png
    var type : storeType = .baselayer
    var bounds : MKCoordinateRegion = MKCoordinateRegion.world
    var date : Date = Date()
    
    var minZoom = 0
    var maxZoom = 18
    
    var zoomLevels : [Int] = []
    
    var readonly : Bool = true
    
    
    static func getStoreFor(_ url : URL, readOnly : Bool = true) throws -> MBTileStore{
        
        if let someStore = MBTileStore.openedStores[url] {
            if readOnly == true {
                return someStore
            }else if !someStore.readonly {
                return someStore
            }else {
                someStore.db = try Connection(url.path(), readonly: false)
                return someStore
            }
        }else{
            let aStore = try MBTileStore(url, readOnly: readOnly)
            MBTileStore.openedStores[url] = aStore
            return aStore
        }

    }
    private init(_ url : URL, readOnly : Bool =  true) throws{
        
        
        self.url = url
        self.readonly = readOnly
        db = try Connection(url.path(), readonly: readOnly)
        print("Connected to \(url.absoluteString)")
        
        try loadBasicData()
        
        db = nil    // CLose the connection
        
    }
    
    func loadBasicData() throws{
        
        let metadata = Table("metadata")
        
        if let db = db {
            
            for line in try db.prepare(metadata){
                let variable = line[Expression<String>("name")]
                let value = line[Expression<String>("value")]
                
                switch variable {
                    
                case "name":
                    name = value
                    
                case "format":
                    format = tileFormat(rawValue: value) ?? .png
                    
                case "type":
                    type = storeType(rawValue: value) ?? .baselayer
                    
                case "bounds":
                    let items = value.split(separator: ",").compactMap{ s in
                        Double(string: String(s))
                    }
                    
                    if items.count == 4{
                        bounds = MKCoordinateRegion(top: items[3], left: items[0], bottom: items[1], right: items[2])
                    }else{
                        bounds = MKCoordinateRegion(top: 85, left: -180, bottom: -85, right: 180)
                    }
                    
                case "date":

                    date = Date.mbtilesFormat.date(from: value) ?? Date()
                    
                default:
                    break
                }
            }
            
            let tiles = Table("tiles")
            let zoom = Expression<Int>("zoom_level")
            minZoom =  (try db.scalar(tiles.select(zoom.min)) as? Int)  ?? 0//
            maxZoom =  (try db.scalar(tiles.select(zoom.max)) as? Int) ?? 18//
            
            let stmt =   try db.prepare("select distinct zoom_level as zl from tiles order by zoom_level")
            
            for row in stmt {
                let z : Int = Int(row[0] as! Int64)
                zoomLevels.append(z)
                
            }
            
        }
    }
    
    func loadTile(at path: MKTileOverlayPath) -> Data? {
        
        do {
            if db == nil {
                db = try? Connection(url.path(), readonly: readonly)
            }
            
            if let db = db{
                let zoom = path.z
                let column = path.x
                let m = 1 << path.z
                let row = m - 1 - path.y
                
                let blob = try db.scalar("select tile_data from tiles where zoom_level = ? and tile_column = ? and tile_row = ? ",
                                         zoom, column, row)
                
                if let blob = blob {
                    let someData = Data.fromDatatypeValue(blob as! Blob)
                    return someData
                }else{
                    return nil
                }
            }
        }catch{
            print("Error \(error)")
        }
        return nil
    }
    
    func checkTileExists(at path: MKTileOverlayPath) -> Bool {
        do {
            if db == nil {
                db = try? Connection(url.path(), readonly: readonly)
            }
            
            if let db = db{
                let zoom = path.z
                let column = path.x
                let m = 1 << path.z
                let row = m - 1 - path.y
                
                let exists = try db.scalar("select exists (select 1 from tiles where zoom_level = ? and tile_column = ? and tile_row = ?) ",
                                         zoom, column, row)
          
                return (Int.fromDatatypeValue(exists as! Int64) as Int) == 1
                
               
            }
        }catch{
            print("Error \(error)")
        }
        return false
    }
    
    func insertTile(at path: MKTileOverlayPath, data: Data){
        do {
            if db == nil {
                db = try? Connection(url.path(), readonly: readonly)
            }
            
            if let db = db {
                let zoom = path.z
                let column = path.x
                let m = 1 << path.z
                let row = m - 1 - path.y
                let blob = data.datatypeValue
                
                let zoom_level = Expression<Int>("zoom_level")
                let tile_column = Expression<Int>("tile_column")
                let tile_row = Expression<Int>("tile_row")
                let tile_data = Expression<Blob>("tile_data")
                
                let tiles = Table("tiles")
                
                try db.run(tiles.insert(zoom_level <- zoom,
                                        tile_column <- column,
                                        tile_row <- row,
                                        tile_data <- blob))
            }
            
        }catch{
            print("Error \(error)")
        }
    }
    
    
    func updateTile(at path: MKTileOverlayPath, data: Data){
        do {
            if db == nil {
                db = try? Connection(url.path(), readonly: readonly)
            }
            
            if let db = db {
                let zoom = path.z
                let column = path.x
                let m = 1 << path.z
                let row = m - 1 - path.y
                let blob = data.datatypeValue
                
                let zoom_level = Expression<Int>("zoom_level")
                let tile_column = Expression<Int>("tile_column")
                let tile_row = Expression<Int>("tile_row")
                let tile_data = Expression<Blob>("tile_data")
                
                let tiles = Table("tiles")
                
                let tile = tiles.filter(zoom_level == zoom && tile_column == column && tile_row == row)
                
                try db.run(tile.update(tile_data <- blob))
            }
            
        }catch{
            print("Error \(error)")
        }
    }
    
    func removeTile(at path: MKTileOverlayPath){
        do {
            if db == nil {
                db = try? Connection(url.path(), readonly: readonly)
            }
            
            if let db = db {
                let zoom = path.z
                let column = path.x
                let m = 1 << path.z
                let row = m - 1 - path.y
                
                let zoom_level = Expression<Int>("zoom_level")
                let tile_column = Expression<Int>("tile_column")
                let tile_row = Expression<Int>("tile_row")
                
                let tiles = Table("tiles")
                
                let tile = tiles.filter(zoom_level == zoom && tile_column == column && tile_row == row)
                
                try db.run(tile.delete())
            }
            
        }catch{
            print("Error \(error)")
        }

    }
    
    // Build a new .mbtiles store
    
    static func createMBTileStoreDatabase(_ url : URL, nameOfChart : String, format: tileFormat, type : storeType, bounds : MKCoordinateRegion) throws -> MBTileStore{
 
        var  db : Connection? = try Connection(url.path(), readonly: false)
            if let db = db {
                print("Connected to \(url.absoluteString)")
                
                // Metadata Table
                
                let name = Expression<String>("name")
                let value = Expression<String>("value")
                
                let metadata = Table("metadata")
                try db.run(metadata.create { t in
                    t.column(name)
                    t.column(value)
                })
                
                try db.run(metadata.insert(name <- "name", value <- nameOfChart))
                try db.run(metadata.insert(name <- "format", value <- format.rawValue))
                try db.run(metadata.insert(name <- "type", value <- type.rawValue))
                try db.run(metadata.insert(name <- "bounds", value <- bounds.mbtiles))
                try db.run(metadata.insert(name <- "date", value <- Date().mbtilesString))
                
                let zoom_level = Expression<Int>("zoom_level")
                let tile_column = Expression<Int>("tile_column")
                let tile_row = Expression<Int>("tile_row")
                let tile_data = Expression<SQLite.Blob>("tile_data")
                
                let tiles = Table("tiles")
                try db.run(tiles.create { t in
                    t.column(zoom_level)
                    t.column(tile_column)
                    t.column(tile_row)
                    t.column(tile_data)
                })
                let stmt = "CREATE UNIQUE INDEX i_tile ON tiles(zoom_level COLLATE BINARY ASC, tile_column COLLATE BINARY ASC, tile_row COLLATE BINARY ASC)"
                try db.run(stmt)
                
            }
            db = nil
            
        return try MBTileStore.getStoreFor(url, readOnly: false)
            
    }
    
    func createTileIndex() throws{
        
        let stmt = "CREATE UNIQUE INDEX i_tile ON tiles(zoom_level COLLATE BINARY ASC, tile_column COLLATE BINARY ASC, tile_row COLLATE BINARY ASC)"
       
            if db == nil {
                db = try? Connection(url.path(), readonly: readonly)
            }
            if let db = db{
                try db.run(stmt)
            }
    }
}

extension MKCoordinateRegion {
    
    var mbtiles : String {
        let tl = topLeft
        let br = bottomRight
        
        return "\(tl.longitude), \(br.latitude), \(br.longitude), \(tl.latitude)"
    }
}
