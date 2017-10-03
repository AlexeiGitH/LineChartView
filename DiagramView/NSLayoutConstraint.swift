//  NSLayoutConstraint.swift
//  Created by Alex on 2017-08-31.

import Cocoa

extension NSLayoutConstraint {
    
    static func centeredFullSize(forView: NSView, inView: NSView)  -> [NSLayoutConstraint] {
        
        forView.translatesAutoresizingMaskIntoConstraints = false
        
        //height
        let heightContraints = NSLayoutConstraint(item: forView, attribute:
            .height, relatedBy: .equal, toItem: inView,
                     attribute: NSLayoutAttribute.height, multiplier: 1,
                     constant: 0)
        
        //width
        let widthContraints = NSLayoutConstraint(item: forView, attribute:
            .width, relatedBy: .equal, toItem: inView,
                    attribute: NSLayoutAttribute.width, multiplier: 1.0,
                    constant: 0)
        
        //centerY - center Vertically
        
        let centerY = NSLayoutConstraint(item: forView, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: inView, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0)
        
        //centerX - center Horizontally
        let centerX = NSLayoutConstraint(item: forView, attribute: .centerX, relatedBy: .equal, toItem: inView, attribute: .centerX, multiplier: 1.0, constant: 0)
       
       
        return [heightContraints, widthContraints, centerX, centerY]
    }
    
    static func aspectRatioWidth(forView: NSView, inView: NSView, ratio: CGFloat) -> NSLayoutConstraint {
        let ratioConstraint = NSLayoutConstraint(item: forView, attribute: .width, relatedBy: .equal, toItem: forView, attribute: .width, multiplier: ratio, constant: 0)
        return ratioConstraint
    }
    static func aspectRatioHeight(forView: NSView, inView: NSView, ratio: CGFloat) -> NSLayoutConstraint {
        let ratioConstraint = NSLayoutConstraint(item: forView, attribute: .height, relatedBy: .equal, toItem: forView, attribute: .height, multiplier: ratio, constant: 0)
        return ratioConstraint
    }
}

