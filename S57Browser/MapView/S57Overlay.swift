//
//  S57Overlay.swift
//  S57Browser
//
//  Created by Francisco Gorina Vanrell on 26/4/23.
//

import Foundation
import MapKit
import S57Parser


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
    
    let fontName = "Futura" as CFString // Avenir
    
    
    let contourColor = CGColor(red: 107.0/255.0, green: 118.0/155.0, blue: 107.0/256.0, alpha: 1.0)
    
    
    override func draw(_ rect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext){
        
        guard let overlay = overlay as? S57Overlay else { return }
        
        // Font Size changes with zoomScale :(
        let fontSmall = CTFontCreateWithName(fontName, 6.0 / zoomScale, nil)
        let fontBig = CTFontCreateWithName(fontName, 8.0 / zoomScale, nil)
        
        // Draw rect to show size of cells. Comment after
        //drawRect(rect, zoomScale: zoomScale, context: context)
        
        // Scale: 1:scale suposes a 72 ppi and uses center of rect for latitude.
        
        let region = MKCoordinateRegion(rect)
        let scale = (72.0 * 1000.0)/(25.4 * zoomScale * MKMapPointsPerMeterAtLatitude(region.center.latitude))
        
        
        for feature in overlay.features{
            
            if let featureRect = mapRect(feature, context: context){
                
                if  featureRect.intersects(rect){
                    
                    // OK now draw it
                    var display = true
                    if let f = feature as? S57Feature{  // Check if  minimum scale. Att 133 is minimum scle
                        if let xscale = f.attributes[133]?.value{
                            if let minScale = Double(xscale){
                                display = minScale >= scale
                            }
                        }
                    }
                    
                    if display {
                        drawFeature(feature, rect: rect, fontBig: fontBig, fontSmall: fontSmall, zoomScale: zoomScale, context: context)
                    }
                }
            }
        }
    }
    
    
    private func drawFeature(_ feature : any S57Displayable, rect : MKMapRect, fontBig: CTFont, fontSmall: CTFont, zoomScale: MKZoomScale, context: CGContext){
        
        switch feature.prim {
        case .point:
            drawPoint(feature, rect: rect, fontBig: fontBig, fontSmall: fontSmall, zoomScale: zoomScale, context: context)
            
        case .line:
            drawLine(feature, rect: rect, zoomScale: zoomScale, context: context)
            
        case .area:
            drawArea(feature, rect: rect, zoomScale: zoomScale, context: context)
            
        default:
            break
        }
        
        if let feature = feature as? S57Feature {
            
            for ffpt in feature.ffpt{
                
                if let daugther = ffpt.feature{
                    if ffpt.relationshipIndicator == .slave{
                        drawFeature(daugther, rect: rect, fontBig: fontBig, fontSmall: fontSmall, zoomScale: zoomScale, context: context)
                    }
                }
                
            }
            
            
        }
        
    }
    private func drawRect(_ rect : MKMapRect, zoomScale: MKZoomScale, context: CGContext ){
        context.saveGState()
        let boundingRect = self.rect(for: rect)
        let mark = boundingRect//.insetBy(dx: boundingRect.width/10.0, dy: boundingRect.height/10.0)
        context.setStrokeColor(red)
        context.setFillColor(red)
        context.setLineWidth(1 / zoomScale)
        
        context.addRect(mark)
        context.drawPath(using: .stroke)
        context.restoreGState()
    }
    
    
    
    private func mapRect(_ feature : any S57Displayable, context : CGContext) -> MKMapRect?{
        
        if let f = feature as? S57Feature, f.objl == 129{
            if let aRect = feature.region?.mapRect{
                return aRect
            }
        }
        
        
        switch feature.prim {
        case .point:
            let realSize = context.convertToUserSpace(CGSize(width: 20.0, height: 20.0))
            let center  =  self.point(for: feature.point!) // Inc User coordinates
            let aRect = CGRect(x: center.x - realSize.width / 2.0, y: center.y - realSize.height / 2.0, width: realSize.width, height: realSize.height)
            return self.mapRect(for: aRect)
            
        default:
            
            if let aRect = feature.region?.mapRect{
                return (aRect)
            }
            
        }
        
        return  nil
    }
    
    private func drawPoint(_ feature : any S57Displayable, rect : MKMapRect, fontBig: CTFont, fontSmall: CTFont, zoomScale: MKZoomScale, context: CGContext){
        var imageName : String?
        var text : String?
        if let f = feature as? S57Feature{
            
            
            if f.objl == 129{  // Sounding. IS a diffeerent way to do it
                drawSounding(feature: f, rect: rect, font: fontSmall, context: context)
                return
                
            }else{
                imageName = S57PointRenderer.imageForFeature(f)
                text = S57PointRenderer.textForFeature(f)
            }
        }
        // ATENCIó: La mida dels simbols es estable independent del Zoom!!!
        
        if let point  = feature.point{
            if let imageName = imageName {
                drawImage(imageName, at: point, zoomScale: zoomScale, in: context)
            }
            if let text = text {
                drawText(text, at: point, font: fontBig, in: context)
            }
        }
        
    }
    
    
    private func drawSounding( feature : S57Feature, rect : MKMapRect, font: CTFont, context: CGContext){
        for fspt in feature.fspt{
            if let v = fspt.vector{
                for coord in v.expandedCoordinates{
                    if let value = coord.depth?.formatted() {
                        let mapPoint = MKMapPoint(coord.coordinates)
                        if rect.contains(mapPoint){
                            drawText(value, at: mapPoint, font: font, in: context)
                        }
                    }
                }
            }
        }
    }
    
    
    private func drawLine(_ feature : any S57Displayable, rect : MKMapRect,zoomScale: MKZoomScale, context: CGContext){
        
        context.saveGState()
        let roadSize = MKRoadWidthAtZoomScale(zoomScale)
        if let points = feature.points{
            
            let p0 = points[0]
            
            context.beginPath()
            
            context.move(to: self.point(for: p0))
            
            for p in points[1...]{
                context.addLine(to: self.point(for: p))
            }
            
            context.setStrokeColor(S57PointRenderer.colorForItem(feature))
            //context.setFillColor(red)
            context.setLineWidth(1.0 / zoomScale)
            
            context.strokePath()
            //context.fillPath()
            
        }
        context.restoreGState()
        
        
    }
    
    private func drawArea(_ feature : any S57Displayable, rect : MKMapRect, zoomScale: MKZoomScale, context: CGContext){
        
        context.saveGState()
        if let points = feature.points{
            
            let p0 = points[0]
            
            context.beginPath()
            
            context.move(to: self.point(for: p0))
            
            for p in points[1...]{
                context.addLine(to: self.point(for: p))
            }
            context.closePath()
            
            let storePath = context.path!
            if let f = feature as? S57Feature {
                if let dashes = S57PointRenderer.borderArea(f){
                    context.setStrokeColor(dashes.color)
                    context.setLineWidth(dashes.width / zoomScale)
                    context.setLineDash(phase: 0.0, lengths: dashes.dashes.map{$0 / zoomScale})
                    context.strokePath()
                    
                }
                if S57PointRenderer.fillArea(f){
                    context.addPath(storePath)
                    context.setFillColor(S57PointRenderer.colorForItem(feature))
                    context.fillPath()
                }
                
                
            }else{
                context.setFillColor(S57PointRenderer.colorForItem(feature))
                context.fillPath()
            }
        }
        
        // Now turn interior points transparent (hope)
        
        if let points = feature.interiorPoints{
            
            let p0 = points[0]
            
            context.beginPath()
            
            context.move(to: self.point(for: p0))
            
            for p in points[1...]{
                context.addLine(to: self.point(for: p))
            }
            context.closePath()
            context.setFillColor(CGColor.clear)
            context.fillPath()
            
        }
        
        // Now draw an image at the center
        var imageName = "SpecialPP_Pillar"
        if let f = feature as? S57Feature{
            if let imageName = S57PointRenderer.imageForFeature(f){
                if let point = f.center{
                    drawImage(imageName, at: point, zoomScale: zoomScale, in: context)
                }
                
            }
        }
        
        context.restoreGState()
    }
    
    
    
    
    
    // Auxiliary function to draw a text at  point (centered)
    private func drawText(_ text : String, at point : MKMapPoint, font: CTFont, in context : CGContext){
        let cgPoint = self.point(for: point)
        context.saveGState()
        context.setTextDrawingMode(.fillStroke)
        context.textMatrix = CGAffineTransformMakeScale(1.0, -1.0)
        
        // Parameters
        
        let color = CGColor.black
        //let fontSize: CGFloat = size / zoomScale
        // You can use the Font Book app to find the name
        //let fontName = "Helvetica" as CFString // Chalk
        //let font = CTFontCreateWithName(fontName, fontSize, nil)
        
        let attributes: [NSAttributedString.Key : Any] = [.font: font, .foregroundColor: color]
        
        // Text
        
        let string = text
        let attributedString = NSAttributedString(string: string,
                                                  attributes: attributes)
        
        // Render
        
        let line = CTLineCreateWithAttributedString(attributedString)
        
        let stringRect = CTLineGetImageBounds(line, context)
        let x = cgPoint.x - stringRect.width / 2.0 - stringRect.origin.x
        let y = cgPoint.y + stringRect.height / 2.0 + stringRect.origin.y
        
        context.textPosition = CGPoint(x: x, y: y)
        
        CTLineDraw(line, context)
        context.restoreGState()
        
    }
    
    private func drawImage(_ imageName : String, at point : MKMapPoint, zoomScale: MKZoomScale, in context : CGContext){
        context.saveGState()
        
#if os(macOS)
        
        
        let cgPoint = self.point(for: point)
        if let nsImage = NSImage(named: imageName){
            let imageSize = nsImage.size
            //et proposedSize = context.convertToUserSpace(imageSize)
            //let relativeSize = 1.0
            let baseSize = context.convertToUserSpace(imageSize)
            let factor = 1.0
            let someRect = CGRect(x: cgPoint.x - baseSize.width/2.0/factor, y: cgPoint.y - baseSize.height/2.0/factor, width: baseSize.width/factor, height: baseSize.height/factor)
            
            
            let old = NSGraphicsContext.current
            let nsContext = NSGraphicsContext(cgContext: context, flipped: true)
            NSGraphicsContext.current = nsContext
            nsImage.draw(in: someRect)
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
        
#elseif os(iOS)
        
        
        let cgPoint = self.point(for: point)
        
        if let uiImage = UIImage(named: imageName){
            let imageSize = uiImage.size
            
            context.saveGState()
            
            let baseSize = context.convertToUserSpace(imageSize)
            let factor = 1.0
            let someRect = CGRect(x: cgPoint.x - baseSize.width/2.0/factor, y: cgPoint.y - baseSize.height/2.0/factor, width: baseSize.width/factor, height: baseSize.height/factor)
            
            context.translateBy(x: 0, y: cgPoint.y)
            context.scaleBy(x: 1.0, y: -1.0)
            context.translateBy(x: 0, y: -cgPoint.y)
            
            if let cgimage = uiImage.cgImage {
                context.draw(cgimage, in: someRect)
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
#endif
        context.restoreGState()
    }
}
