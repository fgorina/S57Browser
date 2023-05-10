//
//  S57Displayable + Extensions.swift
//  S57Browser
//
//  Created by Francisco Gorina Vanrell on 9/5/23.
//

import Foundation
import MapKit
import S57Parser

extension S57Displayable {
    
    // Must develop to get icons and drawing style according to S52
    
    var  point : MKMapPoint? {
        get {
            guard !coordinates.exterior.isEmpty else { return nil}
            let pt = MKMapPoint(self.coordinates.exterior[0].coordinates)
            return pt
        }
    }
    
    var points : [MKMapPoint]?{
        get {
            guard !coordinates.exterior.isEmpty else { return nil}
            return coordinates.exterior.map { coord in
                MKMapPoint(coord.coordinates)
            }
        }
    }
    
    var interiorPoints : [MKMapPoint]?{
        get {
            guard !coordinates.interior.isEmpty else { return nil}
            return coordinates.interior.map { coord in
                MKMapPoint(coord.coordinates)
            }
        }
    }
    
    var imageName : String {
        return "smallcircle.filled.circle"
    }
    
    var center : MKMapPoint? {   // http://en.wikipedia.org/wiki/Centroid
        
        if let points = points {
            var a = 0.0
            var cx = 0.0
            var cy = 0.0
            
            // Compute a
            
            for i in 0..<points.count-1{
                a = a + points[i].x * points[i+1].y - points[i+1].x * points[i].y
            }
            a = a / 2.0
            for i in 0..<points.count-1{
                cx = cx + (points[i].x + points[i+1].x)*(points[i].x*points[i+1].y - points[i+1].x*points[i].y)
                cy = cy + (points[i].y + points[i+1].y)*(points[i].x*points[i+1].y - points[i+1].x*points[i].y)
            }
            
            cx = cx / (6 * a)
            cy = cy / (6 * a)
            
            return MKMapPoint(x: cx, y: cy)
            
        }else{
            return nil
        }
    }
    
}
