//
//  S57PointRenderer.swift
//
//  Interprets a feature with point gepometry and returns the appropiate image name
//
//  Images MUST be in the assets catalog with teh correct name and ideally as svg
//
//  S57Browser
//
//  Created by Francisco Gorina Vanrell on 5/5/23.
//

import Foundation
import S57Parser


struct S57PointRenderer {
    
    static func imageForFeature(_ feature : S57Feature) -> String{
        
        switch feature.objl{
            
        case 4:
            return"Anchorage"
            
        case 5: // Beacon Cardinal
            let category = feature.attributes[13]?.value ?? "" // Category
            return "BCNCAR0\(category)"
            // Idealment deuriem modificar en funció del tipus
            
            
        case 6: // Single danger
            return "BCNISD21"
            
        case 7: // Beacon Lateral
            let ctype = feature.attributes[2]?.value    // Support Type
            var type = "Stake"
            if ctype == "1"{
                
            }else{
                
            }
     
               
                
            let ccategory = feature.attributes[36]?.value // Category
            // Idealment deuriem modificar en funció del tipus
            var category = "Lateral_Pillar_PreferredChannel_Port"
            switch ccategory {
            case "1" :
                return "BCNLAT15"
            case "2":
                return "BCNLAT16"
                
            case "3" :
                return "BCNLAT15S"
                
            case "4":
                return "BCNLAT16B"
                
            default:
                return "BCNLAT15"
                
            }
          
        case 8: // Beacon Special Purpose
                return "BCNSPP13"
            
        case 14: // Buoy Cardinal
            let category = feature.attributes[13]?.value ?? "" // Category
            return "BOYCAR0\(category)"
            
        case 16:
            return "BOYISD12"

            
            
        case 17: // Buoy Lateral
        let ctype = feature.attributes[4]?.value    // Support Type
        var type = "Stake"
        if ctype == "1"{
            
        }else{
            
        }
 
           
            
        let ccategory = feature.attributes[36]?.value // Category
        // Idealment deuriem modificar en funció del tipus
        var category = "Lateral_Pillar_PreferredChannel_Port"
        switch ccategory {
        case "1" :
            return "BOYLAT13"
        case "2":
            return "BOYLAT14"
            
        case "3" :
            return "BOYLAT14"
            
        case "4":
            return "BOYLAT13"
            
        default:
            return "BCNLAT15"
            
        }

            
        
        case 18:
            return "BOYSAW12"
            
        case 19:
            return "BOYSPP11"
            
            
        case 64:    // Harbour
            let ctype = feature.attributes[30]?.value
            
            switch ctype {
                
            
            case "4" :
                return "F10"
            case "5":
                return "U1_1"
                
            default:
                return "U1_2"
            }
            
            
            
            
        default:
        
            return "Pillar"
        }
        
    }
    
    
}
