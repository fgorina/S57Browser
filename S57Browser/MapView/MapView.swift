//
//  MapView.swift
//  S57Browser
//
//  Created by Francisco Gorina Vanrell on 26/4/23.
//


import Foundation
import SwiftUI
import Combine
import MapKit
import S57Parser


struct MapTap {
    var time : Date
    var location : CLLocation
    var rect: MKMapRect
    //var center : CLLocation
}

enum MapViewCommand {
    case center
    case region(MKCoordinateRegion)
    
}

#if os(iOS)
struct MapView: UIViewRepresentable {
    
    @Binding var features : [any S57Displayable]  // List of objects to display over
    @Binding var region : MKCoordinateRegion
    @Binding var currentZoom : Double
    @Binding var tap : MapTap?

    
    //MARK: UIVIewRepresentable
    
    func makeUIView(context: Context) -> MKMapView {
        
        let mapView = MKMapView()
        
        mapView.delegate = context.coordinator
        mapView.register(MKAnnotationView.self, forAnnotationViewWithReuseIdentifier: "nextWp")
        
        let czr = MKMapView.CameraZoomRange(minCenterCoordinateDistance: 12.0)
        mapView.setCameraZoomRange(czr, animated: true)
                
        //mapView.showsZoomControls = true
        if let ovl = try? S57Overlay(features){
            mapView.addOverlay(ovl, level: .aboveLabels)
        }

        mapView.setRegion(region, animated: true)

        mapView.showsScale = true
        mapView.showsCompass = true
        
        mapView.showsUserLocation = true
        
        mapView.isPitchEnabled = false
        mapView.isRotateEnabled = false
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.mapType = .standard
        
        let recognizer = BindableTapGestureRecognizer(action: {(pt: CGPoint) in
            checkTap(pt: pt, mapView: mapView)
        })
            
        mapView.addGestureRecognizer(recognizer)
        

        
        //mapView.setUserTrackingMode(recording ? .followWithHeading : .none, animated: true)
        
        return mapView
    }
}
#else
struct MapView: NSViewRepresentable {
    
    typealias NSViewType = MKMapView
    
    @Binding var features : [any S57Displayable]  // List of objects to display over
    @Binding var region : MKCoordinateRegion
    @Binding var currentZoom : Double
    @Binding var tap : MapTap?


    
    func makeNSView(context: Context) -> MKMapView {
        
        let mapView = MKMapView()
        mapView.bounds = CGRect(x: 0, y: 0, width: 400, height: 400)
        
        mapView.delegate = context.coordinator
        mapView.register(MKAnnotationView.self, forAnnotationViewWithReuseIdentifier: "nextWp")
        
        let czr = MKMapView.CameraZoomRange(minCenterCoordinateDistance: 12.0)
        mapView.setCameraZoomRange(czr, animated: true)
        
        
        //mapView.showsZoomControls = true
        
        //mapView.showsScale = true
        //mapView.showsCompass = true
         
        //context.coordinator.view = mapView
        if let ovl = try? S57Overlay(features){
            mapView.addOverlay(ovl, level: .aboveLabels)
        }
        mapView.setRegion(region, animated: false)
        
        mapView.showsUserLocation = true
        
        mapView.isPitchEnabled = false
        mapView.isRotateEnabled = false
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.mapType = .standard
        
        let recognizer = BindableTapGestureRecognizer(action: {(pt: CGPoint) in
            checkTap(pt: pt, mapView: mapView)
        })
            
        mapView.addGestureRecognizer(recognizer)

        return mapView
    }
    
    /*func sizeThatFits(_ proposal: ProposedViewSize, nsView: MKMapView, context: Context) -> CGSize? {
        CGSize(width: 400, height: 400)
    }
     */
}
        
    #endif
    
extension MapView {
    
    func checkTap(pt: CGPoint, mapView: MKMapView){
        
        let delta = 10.0  // It is qhat we consider near
            let coord = mapView.convert(pt, toCoordinateFrom: mapView)
        
            // Compute a map rect of
        
        let pt1 = CGPoint(x: pt.x - delta, y: pt.y - delta)
        let pt2 = CGPoint(x: pt.x + delta, y: pt.y + delta)
        
        let c1 = MKMapPoint(mapView.convert(pt1, toCoordinateFrom: mapView))
        let c2 = MKMapPoint(mapView.convert(pt2, toCoordinateFrom: mapView))
        
        let mapRect = MKMapRect(x: min(c1.x,c2.x), y: min(c1.y,c2.y), width: abs(c1.x-c2.x), height: abs(c1.y-c2.y))

        let tap = MapTap(time : Date(), location: CLLocation(latitude: coord.latitude, longitude: coord.longitude), rect: mapRect)
        
        DispatchQueue.main.async {
            self.tap = tap
        }
    }
     

    
    func updateView(_ view: MKMapView, context: Context) {
        if context.coordinator.updating {
            return
        }

        context.coordinator.updating = true
        
        
        let overlays = view.overlays.filter { ovl in
            return ovl .isKind(of: S57Overlay.self)
        }
        
        view.removeOverlays(overlays)
        
     
            if let ovl = try? S57Overlay(features){
                view.addOverlay(ovl, level: .aboveLabels)
            }
        

        context.coordinator.updating = false
        //view.isRotateEnabled = false
        //view.setUserTrackingMode(recording ? .followWithHeading : .none, animated: true)
        
        DispatchQueue.main.async {
            view.setRegion(region, animated: true)
        }

    }
}
#if os(iOS)

    
extension MapView{
    func updateUIView(_ view: MKMapView, context: Context) {
        updateView(view, context: context)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    

}
    
#elseif os(macOS)
extension MapView {
    func updateNSView(_ view: MKMapView, context: Context) {
        updateView(view, context: context)    }
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    

    
}
#endif
    
    
    
    
    
    // MARK: - Coordinator

extension MapView {
    
    class Coordinator: NSObject, MKMapViewDelegate {
        
        var parent : MapView
        var updating = false
        
        var boundingBox : MKMapRect = MKMapRect(x: 0.0, y: 0.0, width: 0.0, height: 0.0)
        
        var subscription : Cancellable?
        
        init(parent: MapView){
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            
            if overlay .isKind(of: S57Overlay.self){
                return S57OverlayRenderer(overlay: overlay as! S57Overlay)
            }
            
            else if overlay .isKind(of: MKTileOverlay.self){
                return   MKTileOverlayRenderer(tileOverlay: overlay as! MKTileOverlay)
                
            } else if overlay.isKind(of: MKPolygon.self){
                
                let renderer = MKPolygonRenderer(polygon: overlay as! MKPolygon)
                renderer.lineWidth = 1.0
                renderer.lineDashPattern = [8.0, 8.0]
                renderer.strokeColor = .purple
                return renderer
                
            }else {
                return  MKPolylineRenderer(overlay: overlay)
            }
        }
        
        //MARK: - MKAnnotationViews
        
/*        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            
            return nil
            
        }
*/
        
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            
            
            let frameWidth = mapView.frame.size.width
            let regionWidth = mapView.region.span.longitudeDelta
            DispatchQueue.main.async {
                self.parent.region = mapView.region
                self.parent.currentZoom = log2(360.0 * frameWidth / (regionWidth * 256.0))

            }
            
            
        }
    }
    
    // MARK: - Utilities
    
    func polylineOverlays(_ view : MKMapView) -> [MKPolyline]{
        
        return view.overlays.compactMap { ovl in
            if let poly = ovl as? MKPolyline {
                return poly
            }
            return nil
        }
    }
    
    
    
    func clearOverlays(_ map : MKMapView){
        let overlays = map.overlays
        
        for overlay in overlays {
            
            if let ovr = overlay as? MKTileOverlay{
                map.removeOverlay(ovr)
            }
            
            
            if let ovr = overlay as? S57Overlay {
                map.removeOverlay(ovr)
            }
         }
    }
    
    func clearTrackOverlays(_ map : MKMapView){
        let overlays = map.overlays
        
        for overlay in overlays {
            if let ovr = overlay as? MKPolyline{
                map.removeOverlay(ovr)
            }
            if let ovr = overlay as? MKPolygon{
                map.removeOverlay(ovr)
            }
            
        }
    }
    
}






