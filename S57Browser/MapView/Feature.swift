//
//  Feature.swift
//  S57Browser
//
//  Created by Francisco Gorina Vanrell on 26/4/23.
//

import Foundation
import MapKit


enum FeatureSource {
    
    case stack          // Comes from
    case library        // Library of StackObjects
    case ais            // Ships
    case coast           // Feature - COALNE
    case lights         // Feature - LIGHTS
    case weather        // Comes from beaches
    case track
    case currentRoute

}

// Compatible to S57Geometry
enum FeatureGeometry {
    
        case point
        case line
        case area
        case null
        
        public var description : String {
            switch self {
            case .point:
                return "Point"
            case .line:
                return "Line"
            case .area:
                return "Area"
            case .null:
                return "Null"

            }
        }
}


protocol Feature {
    var id : UUID {get}
    var featureSource : FeatureSource {get}
    var featureClass : String {get}
    var featureGeom : FeatureGeometry {get}
    
    
}
