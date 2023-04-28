//
//  S57Overlay.swift
//  S57Browser
//
//  Created by Francisco Gorina Vanrell on 26/4/23.
//

import Foundation
import MapKit
import S57Parser

extension S57Displayable {
    
    // Must develop to get icons and drawing style according to S52
    
    var  point : MKMapPoint? {
        get {
            guard !coordinates.isEmpty else { return nil}
            let pt = MKMapPoint(self.coordinates[0].coordinates)
            return pt
        }
    }
     
    var points : [MKMapPoint]?{
        get {
            guard !coordinates.isEmpty else { return nil}
            return coordinates.map { coord in
                MKMapPoint(coord.coordinates)
            }
        }
    }
    var imageName : String {
        return "smallcircle.filled.circle"
    }
    
}
enum S57OverlayError : Error{
    case emptyFeatures
    case noGeometricRegions
    case notEnoughCoordinates
}

class S57Overlay : NSObject, MKOverlay{
    
    
    var coordinate: CLLocationCoordinate2D    
    var boundingMapRect: MKMapRect
    
    
    var features : [any S57Displayable]
    
    init(_ features : [any S57Displayable])  throws {
        
        if features.isEmpty {
            throw S57OverlayError.emptyFeatures
        }
        
        self.features = features
        
        let regions = features.compactMap { f in f.region }
        guard !regions.isEmpty else {throw S57OverlayError.noGeometricRegions}

        boundingMapRect = regions[0].mapRect
        for someRegion in regions{
            boundingMapRect = boundingMapRect.union(someRegion.mapRect)
        }
        
        coordinate = MKCoordinateRegion(boundingMapRect).center
        super.init()
    }
    
    func canReplaceMapContent() -> Bool {
        return false
    }
}

class S57OverlayRenderer : MKOverlayRenderer {
    let red = CGColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
    let black = CGColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
    let magenta = CGColor(red: 1.0, green: 0.0, blue: 1.0, alpha: 0.5)
    
    
    override func draw(_ rect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext){
        
        
        
        guard let overlay = overlay as? S57Overlay else { return }
        
        for feature in overlay.features{
            
            if let regionRect = feature.region?.mapRect, regionRect.intersects(rect){
                
                // OK now draw it
                
                switch feature.prim{
                    
                case .point:
                    
#if os(macOS)
                    if let point  =  feature.point{
                        
                        let cgPoint = self.point(for: point)
                        if let nsImage = NSImage(named: "Cardinal_Pillar_North"){
                            let baseSize = 40.0
                            let size = baseSize / zoomScale
                            let rect = CGRect(x: cgPoint.x - size/2.0, y: cgPoint.y - size/2.0, width: size, height: size)
                            
                            let old = NSGraphicsContext.current
                            let nsContext = NSGraphicsContext(cgContext: context, flipped: true)
                            NSGraphicsContext.current = nsContext
                            nsImage.draw(in: rect)
                            NSGraphicsContext.current = old
                            
                        }else{
                            
                            let d = 5.0 / zoomScale
                            let arect = CGRect(x: cgPoint.x-d, y: cgPoint.y-d, width: 2*d, height: 2*d)
                            context.setFillColor(magenta)
                            context.setStrokeColor(black)
                            context.setLineWidth( 1.0 / zoomScale)
                            context.addEllipse(in: arect)
                            context.drawPath(using: .fillStroke)
                        }
                        
                    }
#elseif os(iOS)
                    
                    
                    if let point = feature.point{
                            
                            let cgPoint = self.point(for: point)
                        
                        if let uiImage = UIImage(named: "Cardinal_Pillar_North"){
                            
                            context.saveGState()
                             let baseSize = 40.0
                            let size = baseSize / zoomScale
                            let rect = CGRect(x: cgPoint.x - size/2.0, y: cgPoint.y - size/2.0, width: size, height: size)
                            context.translateBy(x: 0, y: rect.height)
                            context.scaleBy(x: 1.0, y: -1.0)

                            if let cgimage = uiImage.cgImage {
                                context.draw(cgimage, in: rect)
                            }
                            context.restoreGState()
                        }else{
                            let d = 5.0 / zoomScale
                            
                            let rect = CGRect(x: cgPoint.x-d, y: cgPoint.y-d, width: 2*d, height: 2*d)
                            context.setFillColor(magenta)
                            context.setStrokeColor(black)
                            context.setLineWidth(1.0 / zoomScale)
                            context.addEllipse(in: rect)
                            context.drawPath(using: .fillStroke)
                        }
                            
                        
                    }
#endif
                    
                    
                case .line:
                    let roadSize = MKRoadWidthAtZoomScale(zoomScale)
                    if let points = feature.points{
                        
                        let p0 = points[0]
                        
                        context.beginPath()
                        
                        context.move(to: self.point(for: p0))
                        
                        for p in points[1...]{
                            context.addLine(to: self.point(for: p))
                        }
                        
                        context.setStrokeColor(red)
                        context.setFillColor(red)
                        context.setLineWidth(roadSize/4.0)
                        
                        context.strokePath()
                        //context.fillPath()
                        
                    }
                    
                case .area:
                    
                    if let points = feature.points{
                        
                        let p0 = points[0]
                        
                        context.beginPath()
                        
                        context.move(to: self.point(for: p0))
                        
                        for p in points[1...]{
                            context.addLine(to: self.point(for: p))
                        }
                        context.closePath()
                        context.setFillColor(magenta)
                        context.fillPath()
                    }
                    
                default:
                    break
                    
                    
                }
            }
        }
    }
}
/*
 override func draw(_ rect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext){
 
 guard let overlay = overlay as? S57Overlay else { return }
 
 for feature in overlay.features{
 
 if let regionRect = feature.region?.mapRect, regionRect.intersects(rect){
 
 // OK now draw it
 
 switch feature.prim{
 
 case .point:
 
 let roadSize = MKRoadWidthAtZoomScale(zoomScale)
 let d = roadSize
 if let point  =  feature.point{
 
 let cgPoint = self.point(for: point)
 
 let rect = CGRect(x: cgPoint.x-d, y: cgPoint.y-d, width: 2*d, height: 2*d)
 context.setFillColor(red)
 context.setStrokeColor(black)
 context.setLineWidth(roadSize / 8.0)
 context.addEllipse(in: rect)
 context.drawPath(using: .fillStroke)
 
 }
 
 case .line:
 let roadSize = MKRoadWidthAtZoomScale(zoomScale)
 if let points = feature.points{
 
 let p0 = points[0]
 
 context.beginPath()
 
 context.move(to: self.point(for: p0))
 
 for p in points[1...]{
 context.addLine(to: self.point(for: p))
 }
 
 context.setStrokeColor(red)
 context.setFillColor(magenta)
 
 context.setLineWidth(roadSize/2.0)
 
 context.strokePath()
 //context.fillPath()
 
 }
 
 case .area:
 
 if let points = feature.points{
 
 let p0 = points[0]
 
 context.beginPath()
 
 context.move(to: self.point(for: p0))
 
 for p in points[1...]{
 context.addLine(to: self.point(for: p))
 }
 context.closePath()
 context.setFillColor(red)
 context.fillPath()
 }
 
 default:
 break
 
 
 }
 }
 }
 }
 
 }
 
 */
