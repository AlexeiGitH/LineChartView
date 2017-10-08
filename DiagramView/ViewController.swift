//
//  ViewController.swift
//  DiagramView
//
//  Created by Alex on 2017-04-30.
//  Copyright © 2017 Alex Kozachenko. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTextFieldDelegate {
    
    @IBOutlet weak var diagramView: NSView!
    
    @IBOutlet weak var paddingTopLeft: NSTextField!
    @IBOutlet weak var paddingTopRight: NSTextField!
    @IBOutlet weak var paddingBottomLeft: NSTextField!
    @IBOutlet weak var paddingBottomRight: NSTextField!
    @IBOutlet weak var yAxisUnitStep: NSTextField!
    @IBOutlet weak var yAxisUnitStepper: NSStepper!
    
    var diagram: LineChartView<Int, Double>!
    var timer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1).cgColor
        
        let ratesValues = [19.10, 19.34,19.25,19.50,19.30,19.70,19.55,19.60,19.20,19.3,19.10,19.0]
        let xValues = Array(1...12)
        
//        diagram = LineChartView<Int, Double>(frame: diagramView.frame)
//        diagram.data(xPoints: xValues, yPoints: ratesValues)
        
        diagram = LineChartView<Int, Double>(frame: diagramView.frame, xValues: xValues, yValues: ratesValues)
        diagramView.addSubview(diagram)
        paddingTopLeft.delegate = self
        paddingTopRight.delegate = self
        paddingBottomLeft.delegate = self
        paddingBottomRight.delegate = self
        
        let cstr = NSLayoutConstraint.centeredFullSize(forView: diagram, inView: diagramView)
        cstr.forEach({ $0.isActive = true })
    }


    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    private enum PaddingSide {
        case Top, Right, Left, Bottom
    }
    
    private func changePadding(newValue: CGFloat, side: PaddingSide) {
        switch side {
        case .Top:
            diagram.paddingTop = newValue
        case .Right:
            diagram.paddingRight = newValue
        case .Left:
            diagram.paddingLeft = newValue
        case .Bottom:
            diagram.paddingBottom = newValue
        }
        diagram.update()
    }
    //MARK:- NSControlTextEditingDelegate2
    override func controlTextDidChange(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField, diagram != nil else {
            return
        }
        guard let strNum = NumberFormatter().number(from: textField.stringValue) else {
            return
        }
        let newVal = CGFloat(strNum)
        
        if textField.tag == 10 {
            changePadding(newValue: newVal, side: .Top)
        } else if textField.tag == 11 {
            changePadding(newValue: newVal, side: .Right)
        } else if textField.tag == 12 {
            changePadding(newValue: newVal, side: .Bottom)
        } else if textField.tag == 13 {
            changePadding(newValue: newVal, side: .Left)
        }
        else if textField.tag == 17 {
            yAxisUnitStep.isEnabled = true
            diagram.yAxisUnitStep = newVal
            diagram.update()
        }
    }
    override func controlTextDidEndEditing(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField, diagram != nil else {
            return
        }
        guard let strNum = NumberFormatter().number(from: textField.stringValue) else {
            return
        }
        
        let newVal = CGFloat(strNum)
        
        if textField.tag == 10 {
            changePadding(newValue: newVal, side: .Top)
        } else if textField.tag == 11 {
            changePadding(newValue: newVal, side: .Right)
        } else if textField.tag == 12 {
            changePadding(newValue: newVal, side: .Bottom)
        } else if textField.tag == 13 {
           changePadding(newValue: newVal, side: .Left)
        } else if textField.tag == 17 {
            diagram.yAxisUnitStep = newVal
            diagram.update()
        }
    }
    
    //
    @IBAction func LineColorPickerColorCHanged(_ sender: NSColorWell) {
        guard diagram != nil else {return}
        diagram.chartLineColour = sender.color
        diagram.update()
    }
    @IBAction func LineWidthFieldChanged(_ sender: NSTextField) {
//        guard  else {return}
        guard  let newWidth = Float(sender.stringValue), diagram != nil else {
            return
        }
        diagram.chartLineWidth = CGFloat(newWidth)
        diagram.update()
    }
    
    @IBAction func PointColorPickerColorChanged(_ sender: NSColorWell) {
        guard diagram != nil else {return}
        diagram.chartPointColour = sender.color
        diagram.update()
    }
    @IBAction func PointRadiusFieldChanged(_ sender: NSTextField) {
        //        guard  else {return}
        guard  let newWidth = Float(sender.stringValue), diagram != nil else {
            return
        }
        diagram.chartPointRadius = CGFloat(newWidth)
        diagram.update()
    }
    
    @IBAction func YAxisNumberChanged(_ sender: NSTextField) {
        guard  let n = Float(sender.stringValue), diagram != nil else {
            return
        }
        diagram.yAxisUnitStep = CGFloat(n)
        diagram.update()
    }

}
