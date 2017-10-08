//
//  ColorBackgrondView.swift
//  DiagramView
//
//  Created by Alex on 2017-09-22.
//  Copyright © 2017 Alex Kozachenko. All rights reserved.
//

import Cocoa

public class ColorBackgrondView: NSView {
    
    @IBInspectable public var backgroundColor: NSColor = #colorLiteral(red: 0.06274510175, green: 0, blue: 0.1921568662, alpha: 1)
    
    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Drawing code here.
        backgroundColor.set()
        let rect = NSBezierPath(rect: dirtyRect)
        rect.fill()
    }
    
}

