//
//  Drawer.swift
//  DiagramView
//
//  Created by Alex on 2017-09-10.
//  Copyright © 2017 Alex Kozachenko. All rights reserved.
//

import Cocoa

struct Constants {
    static let plusLineWidth: CGFloat = 3.0
    static let plusButtonScale: CGFloat = 0.6
    static let halfPointShift: CGFloat = 0.5
}

extension NSView {
    private var halfWidth: CGFloat {
        return bounds.width / 2
    }
    
    private var halfHeight: CGFloat {
        return bounds.height / 2
    }
}
