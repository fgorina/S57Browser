//
//  MKCoordinateRegion + utils.swift
//  ChartCalculator
//
//  Created by Francisco Gorina Vanrell on 23/3/23.
//

import Foundation
import MapKit

extension MKCoordinateRegion {
    
    func contains(_ loc : CLLocationCoordinate2D) -> Bool{
        let rect = self.mapRect
        let point = MKMapPoint(loc)
        return rect.contains(point)
    }
    
    var area : Double {// In MKMapPoint units
        
        let r = self.mapRect
        let area = r.width * r.height
        
        return area
    }
    
}

