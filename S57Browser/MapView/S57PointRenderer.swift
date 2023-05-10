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
import MapKit



struct S57PointRenderer {
    
    static func colorForItem(_ item : any S57Displayable) -> CGColor{
        
        if let f = item as? S57Feature{
            
            
            
            
            if f.prim == .line {
                return CGColor(red: 107.0/255.0, green: 118.0/255.0, blue: 107.0/255.0, alpha: 1.0)
            }
            
            switch f.objl{
            
            case 13:    // Build Area
                return CGColor(red: 181.0/255.0, green: 147.0/255.0, blue: 59.0/255.0, alpha: 1.0)
                
            case 42:    // Depth Area
                let v = Double(f.attributes[87]?.value ?? "0") ?? 0.0 // Minimum value
                
                if v >= 30.0 {
                    return CGColor(red: 220.0/255.0, green: 228.0/255.0, blue: 200.0/255.0, alpha: 1.0)
                }else {
                    return CGColor(red: 197.0/255.0, green: 210.0/255.0, blue: 191.0/255.0, alpha: 1.0)
                }
                
            case 71:    // Land Area
                return CGColor(red: 203.0/255.0, green: 183.0/255.0, blue: 112.0/255.0, alpha: 1.0)

            case 86:    // Obstruction
                return CGColor(red: 129.0/255.0, green: 194.0/255.0, blue: 225.0/255.0, alpha: 1.0)
                
                
            case 121:       // Sea Bed Area
                let v = f.attributes[187]?.value ?? "0"
                
                if v == "4" {
                    return CGColor(red: 147.0/255.0, green: 180.0/255.0, blue: 133.0/255.0, alpha: 1.0)

                }else{
                    return CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0)
                }
                
             
            default:
                return CGColor(red: 1.0, green: 0.0, blue: 1.0, alpha: 0.5)
                
            }
            
            
            
            
            
            
            
        }else{
            return CGColor(red: 1.0, green:0.0, blue: 0.0, alpha: 1.0)
        }
        
    }
    
    static func imageForFeature(_ feature : S57Feature) -> String?{
        
        switch feature.objl{
            
        case 2:
            return "AIRARE02"
            
        case 4:
            return "ACHARE02"
            
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
            
        case 8: // Beacon Safe Water
                return "BCNSAW13"

          
        case 9: // Beacon Special Purpose
                return "BCNSPP13"
            
        case 12:    // Building, single
            return "BUISGL01"       // Add treatment for function
            
        case 14: // Buoy Cardinal
            let category = feature.attributes[13]?.value ?? "" // Category
            return "BOYCAR0\(category)"
            
        case 15:  // Buoy Installation
            let buoyShape = feature.attributes[4]?.value ?? ""
            if buoyShape == "7"{
                return "BOYSUP02"
            }else{
                return "BOYDEF03"
            }
            
        case 16:        // Buoy Isolated Danger
            return "BOYISD12"

            
            
        case 17: // Buoy Lateral
        let ctype = feature.attributes[4]?.value    // Support Type
        var type = "Stake"
        if ctype == "1"{
            
        }else{
            
        }
 
           
            
        let ccategory = feature.attributes[36]?.value // Category
        // Idealment deuriem modificar en funció del tipus
        
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

            
        
        case 18:    // Buoy SafeWater
            return "BOYSAW12"
            
        case 19:    // Buoy SpecialPurpose
            
            let buoyShape = feature.attributes[4]?.value ?? ""
            if buoyShape == "7"{
                return "BOYSUP02"
            }else{
                return "BOYSPP11"
            }
            
        case 58: // Fog Signal
            return "FOGSIG01"
            
        case 59: // Fortified Structure
            return "FORSTC01"
            
        case 64:    // Harbour
            let ctype = feature.attributes[30]?.value
            
            switch ctype {
                
            
            case "4" :
                return "HRBFAC09"
            case "5":
                return "SMCFAC02"
                
            default:
                return "SMCFAC02"
            }
            
        case 72: // Land Elevation
            
            return "POSGEN04"
            
            
        case 74:    // Landmark
            let ctype = feature.attributes[35]?.value
            let conspiscuous = feature.attributes[83]?.value ?? "" == "1"
            
            switch ctype {
            case "1":
                return conspiscuous ? "CAIRNS11" : "CAIRNS01"
                
            case "3":
                return conspiscuous ? "CHIMNY11" : "CHIMNY01"
                
            case "9":
                return conspiscuous ? "MONUMT12" : "MONUMT02"

            case "17":
                return conspiscuous ? "TOWERS03" : "TOWERS01"
                
            default:
                return conspiscuous ? "TOWERS03" : "TOWERS01"
                
            }
            
        case 75:    // Lights
            let color = feature.attributes[75]?.value
            
            switch color {
                
            case "0", "6":
                return "LIGHTS13_1"
                
            case "3":
                return "LIGHTS11_1"
                
            case "4":
                return "LIGHTS12_1"
                
            default:
                return "LIGHTS13_1"
                
            }
            
        case 81:
            return "MAGVAR01"
            
        case 82:    // Fish Factory
            return "MARCUL"
            
        case 86, 159, 153:    // Obstruction, Wreck
            let category = feature.attributes[42]?.value
            let waterLevelEffect = feature.attributes[187]?.value ?? ""
            let sounding = feature.attributes[179]?.value ?? ""
            
            switch category {
                                
            case "5":
                return "FSHHAV01"
                 
            case "7":
                return "FOULGND1"
                
            default:
                
                switch waterLevelEffect {
                case "2":
                    return "OBSTRN11"
                    
                case "4":
                    return "OBSTRN03"
                    
                default:
                    if let vSounding = Double(sounding){
                        
                        if vSounding > 20.0 {
                            return "DANGER02"
                        }else{
                            return "DANGER01"       // Shoud put the sounding somewhere
                        }
                        
                    }else {
                        return "OBSTRN01"
                    }
                }
                
            }
            
        case 87:
            return "OFSPLF01"
            
        case 91:
            return "PILBOP02"
            
        case 103:
            return "RTPBCN02"
            
        case 105:
            return "DRFSTA01"

        case 112:   // restricted Area/
            
            let ctype = feature.attributes[131]?.value
            
            switch ctype {
            case "1":
                return "ACHRES51"
                
            default:
                return "BOYDEF03"   // Acabar de posar valors
            }
            
        case 125:
            let conspiscuous = feature.attributes[83]?.value ?? "" == "1"

            return conspiscuous ? "SILBUI11" : "SILBUI01"
             
        case 144:   // Top Marks are not used asa they are already codified in beacon / buoy
            return nil
            
        default:
        
            return "X"  // Deault Not Found, a circle in black with magenta center
        }
        
    }
        
    static func textForFeature(_ feature : S57Feature) -> String?{
        
        switch feature.objl{
  
            
        case 72: // Land Elevation
            
            return nil
             
        case 86, 159, 153:    // Obstruction, Wreck
            let category = feature.attributes[42]?.value
            let waterLevelEffect = feature.attributes[187]?.value ?? ""
            let sounding = feature.attributes[179]?.value ?? ""
            
                switch waterLevelEffect {
                case "2":
                    return nil
                    
                case "4":
                    return nil
                    
             
                    
                default:
                    if let vSounding = Double(sounding){
                        
                        return sounding
                        
                    }else {
                        return nil
                    }
                }
            
        case 144:   // Top Marks are not used asa they are already codified in beacon / buoy
            return nil
            
        default:
        
            return nil
        }
        
    }
    
    static func borderArea(_ feature : S57Feature) -> (color: CGColor, width: CGFloat, dashes: [CGFloat])?{
        
        switch feature.objl{
            
        case 302, 306:
            return (S57PointRenderer.colorForItem(feature), width: 2.0, dashes: [1.0])

        case 86:
            return (CGColor.black, width: 1.0, dashes: [1.0, 1.0])

        default:
            return nil
            
        }
    }

    // Return true if area should be filled

    static func fillArea(_ feature : S57Feature) -> Bool{
        
        switch feature.objl{
            
        case 302, 306:
            return false
            
        
            
        default:
            return true
            
        }
    }

    
}
