//
//  Binding+onChange.swift
//  ChartCalculator
//
//  Created by Francisco Gorina Vanrell on 2/3/23.
//

import Foundation
import SwiftUI

extension Binding {
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler(newValue)
            }
        )
    }
}
