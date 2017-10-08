//
//  Attributes.swift
//  DiagramView
//
//  Created by Alex on 2017-09-08.
//  Copyright © 2017 Alex Kozachenko. All rights reserved.
//

import Cocoa

class StringAttributesManager {
    static func  createStringAttributes(font: NSFont = NSFont.systemFont(ofSize: 12), alignment: NSTextAlignment = .center, color: NSColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)) -> [NSAttributedStringKey:Any] {
        
        let paraStyle = NSParagraphStyle.default.mutableCopy()
            as! NSMutableParagraphStyle
        paraStyle.alignment = alignment
        
        let attributes = [
            NSAttributedStringKey.font: font,
            NSAttributedStringKey.paragraphStyle: paraStyle,
            NSAttributedStringKey.foregroundColor: color
        ]
        return attributes
    }
}
