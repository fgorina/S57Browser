//
//  MBTileOverlay.swift
//  ChartCalculator
//
//  Created by Francisco Gorina Vanrell on 21/3/23.
//

import Foundation
import MapKit
import SQLite


class MBTileOverlay : MKTileOverlay {
    
    static var tileOverlays : [String : MBTileOverlay] = [:]
    static var queue : DispatchQueue = DispatchQueue(label: "MBTile")
    
    var url : URL
    var backupOverlay : MKTileOverlay?
    
    private var store : MBTileStore
    private var lastZoom = 0

    
    private init(_ name : String, backup: MKTileOverlay? = nil) throws{
        
        url = MBTileOverlay.URLforDatabase(name)
        backupOverlay = backup
        store = try MBTileStore.getStoreFor(url)
        super.init(urlTemplate: nil)
        
        print("Connected")
        // Buld our documents
    }
    
    static func URLforDatabase(_ name : String) -> URL {
        let docsDir = Storage.getURL(for: .documents)
        var nom = name
        if !nom.hasSuffix(".mbtiles"){
            nom = nom + ".mbtiles"
        }
        return docsDir.appendingPathComponent("OverlayCaches").appendingPathComponent(nom)
        
    }
    
    static func newOverlay(_ name : String) throws -> MBTileOverlay{
        
        if let overlay = tileOverlays[name]{
            return overlay
        }else {
            MBTileOverlay.tileOverlays[name] = try MBTileOverlay(name, backup: nil)
            return  MBTileOverlay.tileOverlays[name]!
        }
        
    }
    #if os(iOS)
    func extractImage(from: UIImage, rect: CGRect, expandedTo: CGSize) -> Data?{
        
        let cgImage = from.cgImage
        
        if let cropped = cgImage?.cropping(to: rect) {
            let image = UIImage(cgImage: cropped)
            let finalImage = image.resizeUI(size: expandedTo)
            // Now we must get a jpeg representation
            let data = finalImage?.pngData()
            return data
        } else {
            return nil
        }
        
    }
    #endif
    
    public func loadUnderSampledTile(at path: MKTileOverlayPath, fromZoomLevel zl: Int) async throws -> Data{
        
        let deltaZoom = zl - path.z // We supose that zl i bigger than path.z
        let factor = 1 << deltaZoom // That is the power we need
        
        // For every original tile we need a square of factor tiles by factor tiles
        // That is 256 * factor by 256 * factor
        // Tile coordinates are factor * orig coordinates and incrementing
        
        let base_x = path.x * factor
        let base_y = path.y * factor
        
        var tiles : [Data?] = Array<Data?>(repeating: nil, count: factor * factor)  // Creating a place to receive data
        
        for iy in 0..<factor{
            for ix in 0..<factor {
                let somePath = MKTileOverlayPath(x: base_x + ix, y: base_y + iy, z: zl, contentScaleFactor: 1.0)
                let index = iy * factor + ix
                tiles[index] = store.loadTile(at: somePath)
                if tiles[index] == nil { // If we don't find the data Kaputt!!!
                    throw TMKTileOverlayError.invalidFormat
                }
            }
        }
        
        let tileSize = CGSize(width: self.tileSize.width * CGFloat(factor), height:  self.tileSize.height * CGFloat(factor))
        UIGraphicsBeginImageContextWithOptions(tileSize, false, 1.0)
        
        for iy in 0..<factor{
            for ix in 0..<factor {
                let index = iy * factor + ix
                let pt = CGPoint(x: CGFloat(ix) * self.tileSize.width, y: CGFloat(iy) * self.tileSize.height)
                if let data = tiles[index]{
                    if let image = UIImage(data: data){
                        image.draw(at: pt)
                    }
                }
            }
        }
        
        let combinedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let resizedImage = combinedImage?.resizeUI(size: self.tileSize)
        if let data = resizedImage?.pngData(){
            return data
        }else{
            throw TMKTileOverlayError.invalidFormat
        }
    }
    
    override func loadTile(at path: MKTileOverlayPath)  async throws -> Data {
        if path.z != lastZoom{
            print("New Zoom \(path.z)")
            lastZoom = path.z
        }
        var zoom = path.z
        
        // 1.- zoom es mesp gran que minZoom però no hi es
        
        if  zoom < store.minZoom  && (store.minZoom - zoom) <= 3{   // Try to underzoom the image
            do {
                return try await loadUnderSampledTile(at: path, fromZoomLevel:  store.minZoom)
            }catch{
                if let backup = backupOverlay, self.store.type == .baselayer {
                    return try await backup.loadTile(at: path)
                }else{
                    throw TMKTileOverlayError.notFound
                }
            }
            
        }else if  zoom < store.minZoom {    // Too  ig a difference, Lookup for backup
            if let backup = backupOverlay, self.store.type == .baselayer{
                return try await backup.loadTile(at: path)
            }else{
                throw TMKTileOverlayError.notFound
            }
            
        }else if store.zoomLevels.contains(zoom){   // Fast and easy one
            let data = store.loadTile(at: path)
            if let data = data {
                return data
            }else{
                if let backup = backupOverlay, self.store.type == .baselayer{
                    return try await backup.loadTile(at: path)
                }else{
                    throw TMKTileOverlayError.notFound
                }
                
            }
            
        }else { // Enviem el de una mida anterior agrandit
            while zoom <= store.maxZoom && !store.zoomLevels.contains(zoom){
                zoom = zoom + 1
            }
            if store.zoomLevels.contains(zoom){
                do {
                    return try await loadUnderSampledTile(at: path, fromZoomLevel:  zoom)
                }catch {
                    
                }
            }
            
            zoom = path.z
            
            while zoom >= store.minZoom && !store.zoomLevels.contains(zoom){
                zoom = zoom - 1
            }

            // Hem de calcular quina necessitem
            let overzoom = path.z - zoom
            let factor = 1 << overzoom
            let w = CGFloat(256 / factor)
            let baseTile = MKTileOverlayPath(x: path.x/factor, y: path.y/factor, z: zoom, contentScaleFactor: path.contentScaleFactor)
            let ix = path.x - (baseTile.x * factor)
            let iy = path.y - (baseTile.y * factor)
            let rect = CGRect(x: CGFloat(ix) * w, y: (CGFloat(iy) * w), width: w, height: w)
            
            if let data = store.loadTile(at: baseTile){
                if let image = UIImage(data: data) {
                    if let moreData = self.extractImage(from: image, rect: rect, expandedTo: CGSize(width: 256.0, height: 256.0)){
                        return(moreData)
                    }else{
                        throw TMKTileOverlayError.invalidFormat
                    }
                }else{
                    throw TMKTileOverlayError.invalidFormat
                }
            }else {
                if let backup = backupOverlay, self.store.type == .baselayer{
                    return try await backup.loadTile(at: path)
                }else{
                    throw TMKTileOverlayError.notFound
                }
                
            }
        }
    }
}
