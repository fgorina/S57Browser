//
//  Double+format.swift
//  GRAM_01
//
//  Created by Francisco Gorina Vanrell on 19/08/2019.
//  Copyright © 2019 Francisco Gorina Vanrell. All rights reserved.
//

import Foundation

extension Double {
    
    func toDmm() -> Double {
        let v = self
        let degrees = floor(v)
        let minutes = (v - degrees) * 60.0 / 100.0
        
        let dmm = degrees + minutes
        
        return dmm
    }
    
    func toDdd() -> Double {
        
        let v = self
        
        let degrees = floor(v)
        let fraction = ((v-degrees) * 100.0)/60.0
        
        let deg = degrees + fraction
        
        return deg

    }
    
    
    
    func formated() -> String {
        return String(format: "%10.1f", self)
    }
    
    func formated(format : String) -> String{
        return String(format: format, self)
    }
    
    func formatted(decimals: Int, separator: Bool = true) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = decimals
        formatter.maximumFractionDigits = decimals
        formatter.usesGroupingSeparator = true

        return formatter.string(from: NSNumber(value:self))!
    }
    
    func asHoursMinutes() -> String{
        let hours = Int(floor(self / 3600.0))
        let minutes = Int(floor(((self - Double(hours * 3600)) / 60.0)))
        //let seconds = Int(floor(self - Double(hours * 3600) - Double(minutes * 3600)))
        
        return "\(hours):\(minutes)"
        
    }
    
    func asDDDmmm() -> String{
        
        let s = self.sign == .minus ? -1.0 : 1.0
        
        
        let v = abs(self)
        let degrees = NSNumber(value: floor(v) * s)
        let minutes = NSNumber(value:((v - floor(v)) * 60.0))
        
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        
        let sd = formatter.string(from: degrees)!
   
        formatter.maximumFractionDigits = 1
        formatter.minimumIntegerDigits = 2
        
        let sm = formatter.string(from: minutes)!

        
        //let seconds = Int(floor(self - Double(hours * 3600) - Double(minutes * 3600)))
        
        return "\(sd)º \(sm)'"
        
    }
    
    init?(string: String){
        
        // Detectar si hi ha alguna comma
        var clean : String = string
        
        let comma = clean.firstIndex(of: ",")
        let point = clean.firstIndex(of: ".")
        
        if let comma = comma, let point = point {
            if comma < point {
                clean = clean.replacingOccurrences(of: ",", with: "")   // , is thousands, . is decimal
            }else {
                clean = clean.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")  // . is Thousands, , is decimal
            }
        } else if comma != nil {
            clean = clean.replacingOccurrences(of: ",", with: ".")  // , is decimal
        }
        
        self.init(clean)
    }
    
}

func csc(_ x: Double) -> Double {
    
    let c = sin(x)
    
    if abs(c) < 1.0e-12 {
        return Double.infinity
    } else {
        return 1.0 / c
    }
    
}

func sec(_ x: Double) -> Double {
    
    let c = cos(x)
    
    if abs(c) < 1.0e-12 {
        return Double.infinity
    } else {
        return 1.0 / c
    }
    
}

func cot(_ x : Double) -> Double{
    
    let c = tan(x)
    
    if abs(c) < 1.0e-12 {
        return Double.infinity
    } else {
        return 1.0 / c
    }
}

func gdinv(_ x : Double) -> Double {
    return log(tan(x) + sec(x))
}

func gd(_ x : Double) -> Double {
    return 2 * atan(exp(x)) - Double.halfPi
}

extension Int {
    func leadingZeroes(digits: Int)->String{
        let format = "%0\(digits)d"
        return String(format: format, self)
    }
}
