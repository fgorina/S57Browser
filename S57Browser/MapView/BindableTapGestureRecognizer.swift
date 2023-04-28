//
//  BindableTapGestureRecognizer.swift
//  S57Browser
//
//  Created by Francisco Gorina Vanrell on 27/4/23.
//

import Foundation

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif


#if os(iOS)

final class BindableTapGestureRecognizer: UITapGestureRecognizer {
    private var action: (CGPoint) -> Void

    init(action: @escaping (CGPoint) -> Void) {
        self.action = action
        super.init(target: nil, action: nil)
        self.addTarget(self, action: #selector(execute))
    }

    @objc private func execute() {
        if state == .ended {
            let pt = location(in: self.view)
            action(pt)
        }
    }
}

#elseif os(macOS)
final class BindableTapGestureRecognizer: NSClickGestureRecognizer {
    private var theAction: (CGPoint) -> Void

    init(action: @escaping (CGPoint) -> Void) {
        self.theAction = action
        
        super.init(target: nil, action: nil)
        self.numberOfClicksRequired = 1
        self.buttonMask = 1
        self.target = self
        self.action = #selector(execute)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func execute(sender: NSGestureRecognizer) {
        if state == .ended {
            let pt = location(in: self.view)
            theAction(pt)
        }
    }
}

#endif
