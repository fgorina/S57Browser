//
//  URL + Extensions.swift
//  S57Browser
//
//  Created by Francisco Gorina Vanrell on 24/4/23.
//

import Foundation
extension URL {
    var isDirectory: Bool {
       (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
}
