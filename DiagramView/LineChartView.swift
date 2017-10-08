//
//  LineChart.swift
//  LineChart
//
//  Created by Alex on 2017-08-31.
//  Copyright © 2017 Alex Kozachenko. All rights reserved.
//

import Cocoa

public class LineChartView<x:CustomStringConvertible, y:Numeric>: NSView {
    
    //must be convertable to a CGFloat (sso that adhere to Numeric protocol).
    private var yPoints: [y] = [] {
        didSet {
            if let max = yPoints.max(by: { (a, b) -> Bool in
                return a < b
            }) {
                yAxisMax = CGFloat(fromNumeric: max)
            }
            if let min = yPoints.min(by: < ) { // or by: {$0 < $1}
                yAxisMin = CGFloat(fromNumeric: min)
            }
        }
    }
    //can be any type, sinice its value is not used to calculate point's position in a view
    private var xPoints: [x] = [] {
        didSet {
            numberOfIntervals = xPoints.count
        }
    }
    
    //MARK:- CUSTOMIZE STYLE
    /** False by default.
     If true drawing starts from right to left
     */
    public var reversed = false
    
    public var chartLineWidth: CGFloat = 1
    public var chartLineColour: NSColor = #colorLiteral(red: 0, green: 0.9411764706, blue: 1, alpha: 1)
    public var chartlineCapStyle: NSBezierPath.LineCapStyle = .buttLineCapStyle
    public var chartlineJoinStyle: NSBezierPath.LineJoinStyle = .roundLineJoinStyle
    
    public var chartPointRadius: CGFloat = 4
    public var chartPointColour: NSColor = #colorLiteral(red: 0, green: 0.9411764706, blue: 1, alpha: 1)
    
    public var xAxisLineWidth: CGFloat = 0.6
    public var yAxisLineWidth: CGFloat = 0.6
    
    public var xAxisLineColor: NSColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
    public var yAxisLineColor: NSColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
    
    // ** X & Y Axis
    ///If true, axis is not displayed. False by default
    public var hideXAxis = false
    public var hideYAxis = false
    
    public var hideXAxisLabels = false
    public var hideYAxisLabels = false
    
    
    // ** GRIDLINES **
    ///If true, grid lines are displayed. Default is true.
    public var hideYGridlines = false
    public var hideXGridlines = false
    
    public var xGridlinesWidth: CGFloat = 0.2
    public var yGridlinesWidth: CGFloat = 0.2
    
    public var xGridlinesColor: NSColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
    public var yGridlinesColor: NSColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
    
    ///By default it shows 3 grid lines
    public var yAxisUnitStep: CGFloat = 1
    public var yAxisLabelsNumberOfDecimal: Int = 2
    
    // these used to scale the graph's Y axis and to put labels on Y axis
    /// Assigned on initialzation, and by default is equal to the Max value of Y points
    public var yAxisMax: CGFloat = 10.0
    /// Assigned on initialzation, and by default is equal to the Min value of Y points
    public var yAxisMin: CGFloat = 0.0
    
    ///By default is the same as the number of Y points.
    ///Needs to be set after initialization
    
    // ** PADDING **
    //padding to clear area around the content
    private let minPadding: CGFloat = 20
    
    public var padding: CGFloat = 20 {
        didSet {
            padding = checkPadding(p: padding)
            matchPaddingsToMainPadding()
        }
    }
    public var paddingTop: CGFloat = 20 {
        didSet {
            paddingTop = checkPadding(p: paddingTop)
        }
    }
    public var paddingBottom: CGFloat = 20{
        didSet {
            paddingBottom = checkPadding(p: paddingBottom)
        }
    }
    public var paddingLeft: CGFloat = 20 {
        didSet {
            paddingLeft = checkPadding(p: paddingLeft)
        }
    }
    public var paddingRight: CGFloat = 20 {
        didSet {
            paddingRight = checkPadding(p: paddingRight)
        }
    }
    
    
    //Text attribute
    private var yAttrs : [NSAttributedStringKey : Any]! = [:] //used to add values of Y axis (lowest, heightest)
    
    //MARK:- Private variables
    // used to calculate the distance between point on a X coordinate axis. Should be enough space to place all the xPoints.
    private var xIntervalWidth: CGFloat = 1
    // number of points needed to be displayed on a chart.
    // TODO: Add manual number of intervals. If *manualInterwalWidth* is `true`, the number of intervals is calculated based on the *xIntervalWidth*. If *manualInterwalWidth* is `false`, *numberOfIntervals* used to calculate the *xIntervalWidth*.
    private var numberOfIntervals: Int = 0
    
    //MARK:- INIT
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        editAttributes()
        resetYAxisUnitStep()
    }
    
    public init(frame frameRect: NSRect, xValues: [x], yValues: [y]) {
        super.init(frame: frameRect)
        data(xPoints: xValues, yPoints: yValues)
        editAttributes()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: SETTERS
    ///A method to set the data to draw the chart
    final func data(xPoints: [x], yPoints: [y]) {
        self.xPoints = xPoints;
        self.yPoints = yPoints;
        calculateDrawingVariables()
        resetYAxisUnitStep()
    }
    
    //MARK:- DRAWING
    public final override func draw(_ dirtyRect: NSRect) {
        drawGraph()
    }
    
    // graphic context
    private var currentContext : CGContext? {
        get {
            if #available(OSX 10.10, *) {
                return NSGraphicsContext.current?.cgContext
            } else if let contextPointer = NSGraphicsContext.current?.graphicsPort {
                let context: CGContext = Unmanaged.fromOpaque(contextPointer).takeRetainedValue()
                return context
            }
            return nil
        }
    }
    
    private  final func drawGraph() {
        calculateDrawingVariables()
        if !hideXAxis { drawXAxis() }
        if !hideYAxis { drawYAxis() }
        drawXGridlines()
        drawYGridlines()
        drawGraphLine()
    }
    
    /**
     The main method that draws a chart. If *yPoints* is > that 0, it starts to draw the line from right to left.
     - - -
     */
    private func drawGraphLine() {
        
        guard yPoints.count > 0 && xPoints.count > 0 else {
            return
        }
        
        //draws from left to right (in case if num of y points < num of x pointsd (we know time interval, but there's no data for that period
        let path = NSBezierPath()
        path.lineWidth = chartLineWidth
        path.lineCapStyle = chartlineCapStyle
        path.lineJoinStyle = chartlineJoinStyle
        chartLineColour.setStroke()
        chartPointColour.setFill()
        
        func coordinatesForXandY(xVal: Int, yVal: y) -> (x: CGFloat, y: CGFloat){
            let x = xCoordinateFor(column: xVal)
            let y = yCoordinateFor(value: CGFloat(fromNumeric: yVal))
            return (x: x,y: y)
        }
        
        func drawCircleAt(point: CGPoint, radius: CGFloat) {
            var point = point
            point.x -= radius/2
            point.y -= radius/2
            let circlePoint = NSBezierPath(ovalIn: NSRect(origin: point, size: CGSize(width: radius, height: radius)))
            circlePoint.fill()
        }
        if reversed {
            var currentPointNumber = numberOfIntervals - 1
            
            //last point from the right
            let coordinates = coordinatesForXandY(xVal: currentPointNumber, yVal: yPoints.last!)
            
            path.move(to: CGPoint(x: coordinates.x, y: coordinates.y))
            
            //calculate x and y coordinates for each point. X coordinates does not depend on xPoints values, but only on the number of the argument.
            // y coordinate primarily depends on a value of yPoints[i].
            
            //calculate how many points to draw
            
            for yPointNum in (0..<yPoints.count) {
                
                let coordinates = coordinatesForXandY(xVal: currentPointNumber, yVal: yPoints[yPoints.count-yPointNum-1])
                
                let to = NSPoint(x: coordinates.x, y: coordinates.y)
                
                drawCircleAt(point: to, radius: chartPointRadius)
                
                
                path.line(to: to)
                currentPointNumber -= 1
            }
            path.stroke()
        }
        else {
            //always starts with 0, even if manual Number of intervals
            var currentPointNumber = 0
            
            //start from left bottom
            path.move(to: CGPoint(x: xCoordinateFor(column: currentPointNumber), y: yCoordinateFor(value: CGFloat(fromNumeric: yPoints.first!))))
            
            //add line to every yPoint or to N numberOfIntervals if specified
            for pointNum in (0..<yPoints.count) {
                if currentPointNumber < numberOfIntervals {
                    let coordinates = coordinatesForXandY(xVal: currentPointNumber, yVal: yPoints[pointNum])
                    let pointTo = NSPoint(x: coordinates.x, y: coordinates.y)
                    path.line(to: pointTo)
                    
                    drawCircleAt(point: pointTo, radius: chartPointRadius)
                    
                    currentPointNumber += 1
                }
            }
            path.stroke()
        }
    }
    
    /**
     This method draws a x coordinate axis line (bottom line).
     Just a solid line to show the bounds of a graph.
     It starts from the left padding and fill the full width of a view (-right padding)
     */
    private func drawXAxis() {
        //left bottom corner
        let startX = CGPoint(x: paddingLeft, y: paddingBottom)
        //right bottom corner
        let endX = CGPoint(x: xCoordinateFor(column: numberOfIntervals-1), y: paddingBottom)
        
        let xAxis = NSBezierPath()
        xAxis.move(to: startX)
        xAxis.line(to: endX)
        
        xAxis.lineWidth = xAxisLineWidth
        xAxisLineColor.set()
        
        xAxis.stroke()
    }
    /**
     This method draws a Y coordinate axis (bottom to top). Just a solid line to show the bounds of a graph. It starts from the left bottom (+ padding) and fills the full height of a view (- padding)
     Additionally it adds two labels that show the min and max values of the Y Axis
     */
    private func drawYAxis() {
        let startX = CGPoint(x: paddingLeft, y: paddingBottom) //left bottom corner
        let endX = CGPoint(x: paddingLeft, y: self.frame.height - paddingTop) //left upper corner
        
        let yAxis = NSBezierPath()
        yAxis.move(to: startX)
        yAxis.line(to: endX)
        yAxis.lineWidth = yAxisLineWidth
        yAxisLineColor.set()
        yAxis.stroke()
    }
    
    //vartical from left to right
    private func drawXGridlines() {
        guard numberOfIntervals > 0, hideXAxisLabels != true || hideXGridlines != true else {
            return
        }
        let y = self.frame.height - paddingTop
        for i in 1..<numberOfIntervals {
            
            let x = xCoordinateFor(column: i)
            if !hideXGridlines {
                let start = CGPoint(x: x, y: paddingBottom)
                let end = CGPoint(x: x, y: y)
                let path = NSBezierPath()
                path.move(to: start)
                path.line(to: end)
                path.lineWidth = xGridlinesWidth
                xGridlinesColor.set()
                let pattern: [CGFloat] = [4.0, 0.0]
                path.setLineDash(pattern, count: 1, phase: 0)
                path.stroke()
            }
            //add Labels
            if !hideXAxisLabels {
                let label = "\(xPoints[i])"
                let labelSize = label.size();
                let startLabelPoint = CGPoint(x: x-labelSize.width/2, y: paddingBottom-labelSize.height)
                label.draw(at: startLabelPoint, withAttributes: yAttrs)
            }
        }
        if !hideXAxisLabels {
            //add 0 label outside of the loop
            let x = xCoordinateFor(column: 0)
            let label = "\(xPoints[0])"
            let labelSize = label.size();
            let startLabelPoint = CGPoint(x: x-labelSize.width/2, y: paddingBottom-labelSize.height)
            label.draw(at: startLabelPoint, withAttributes: yAttrs)
        }
    }
    
    //horizontal bottom to top
    private func drawYGridlines() {
        
        guard yPoints.count > 0, hideYAxisLabels == false || hideYGridlines == false else { return }
        if yAxisUnitStep <= 0 { yAxisUnitStep = 0.01 } //to avoid devision by 0
        
        //calculate number of grids to display
        let gridNumFloat = round((yAxisMax-yAxisMin)/yAxisUnitStep)
        var numGrids = Int(round(gridNumFloat))
        let decimalsMultiplier = CGFloat(pow(10, 3.0))
        if ( round((gridNumFloat * yAxisUnitStep + yAxisMin)*decimalsMultiplier)/decimalsMultiplier > yAxisMax) {
            numGrids -= 1
        }
        
        let leftX = xCoordinateFor(column: numberOfIntervals-1)
        
        // add bottom(min) Y label
        if !hideYAxisLabels {
            let value = yAxisMin
            let yCoord = yCoordinateFor(value: value)
            
            let label = String(format: "%.\(yAxisLabelsNumberOfDecimal)f", value)
            let startLabelPoint = CGPoint(x: paddingLeft, y: yCoord)
            label.draw(at: startLabelPoint, withAttributes: yAttrs)
        }
        guard  numGrids > 0 else { return }
        
        // add other labels
        for gridN in 1...numGrids {
            let value = yAxisMin + CGFloat(gridN) * yAxisUnitStep
            let yCoord = yCoordinateFor(value: value)
            
            if !hideYGridlines {
                let leftPoint = CGPoint(x: paddingLeft, y: yCoord) //left side
                let rightPoint = CGPoint(x: leftX, y: yCoordinateFor(value: value)) //left bottom corner
                
                let path = NSBezierPath()
                path.move(to: leftPoint)
                path.line(to: rightPoint)
                yGridlinesColor.set()
                path.lineWidth = yGridlinesWidth
                
                let pattern: [CGFloat] = [4.0, 0.0]
                path.setLineDash(pattern, count: 1, phase: 0)
                path.stroke()
            }
            //Label string
            if !hideYAxisLabels {
                let label = String(format: "%.\(yAxisLabelsNumberOfDecimal)f", value)
                let startLabelPoint = CGPoint(x: paddingLeft, y: yCoord)
                label.draw(at: startLabelPoint, withAttributes: yAttrs)
            }
        }
    }
    
    
    //MARK: chart Points Positions Calculations
    
    func autoParameters() {
        resetPadding()
    }
    
    public final func editAttributes(font: NSFont = NSFont.systemFont(ofSize: 11), alignment: NSTextAlignment = .left, color: NSColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)) {
        let paraStyle = NSParagraphStyle.default.mutableCopy()
            as! NSMutableParagraphStyle
        paraStyle.alignment = alignment
        
        self.yAttrs = [
            NSAttributedStringKey.font: font,
            NSAttributedStringKey.paragraphStyle: paraStyle,
            NSAttributedStringKey.foregroundColor: color,
            //  NSBackgroundColorAttributeName: NSColor.yellow //for debuging purpose
        ]
    }
    
    public final func labelsColor(color: NSColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)) {
        changeColorOfAttributes(toColor: color)
    }
    
    ///Sets the padding. Cannot be lower than 20
    func resetPadding() {
        self.padding = minPadding
        matchPaddingsToMainPadding()
    }
    func resetPadding(to: CGFloat) {
        self.padding = checkPadding(p: to)
        matchPaddingsToMainPadding()
    }
    final func resetYAxisUnitStep() {
        yAxisUnitStep = ((yAxisMax-yAxisMin)/3)
    }
    ///To update the chart view when one or more parameters were changed
    public final func update() {
        needsDisplay = true
    }
    
    //TODO:- To convert points to the value on a graph
    public override func mouseDown(with event : NSEvent) {
        let  pointFromNil = convert(event.locationInWindow, from: nil)
    }
    
    //MARK:- Private methods
    /**
     Calculates all the parameters to draw a graph
     */
    private func calculateDrawingVariables() {
        xIntervalWidth = max((self.frame.width - paddingLeft - paddingRight) / CGFloat(numberOfIntervals-1), CGFloat(1))
    }
    ///Default color is white
    private func changeColorOfAttributes(toColor: NSColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)) {
        self.yAttrs[NSAttributedStringKey.foregroundColor] = toColor
    }
    private func checkPadding(p: CGFloat) -> CGFloat {
        return p < minPadding ? minPadding : p
    }
    private func matchPaddingsToMainPadding() {
        self.paddingRight = padding
        self.paddingLeft = padding
        self.paddingTop = padding
        self.paddingBottom = padding
    }
    ///returns x coordinate for column. Column is just a point on an X coordinate.
    private func xCoordinateFor(column: Int) -> CGFloat {
        //padding depends on a `reversed` property.
        var p = paddingLeft
        if reversed {
            p = paddingRight
        }
        return CGFloat(column) * xIntervalWidth + p
    }
    private func yCoordinateFor(value: y) -> CGFloat {
        
        let value:CGFloat = CGFloat(fromNumeric: value)
        let proportion = (value-yAxisMin)/(yAxisMax-yAxisMin) //to find out the position of a dot on a screen as a percentage
        
        // y = (height - padding from top and bottom) * proportion + marhin to have a space between the bottom of a view and the point
        return (self.frame.height - paddingTop - paddingBottom) * proportion + paddingTop + paddingBottom
    }
    ///returns y coordinate for row
    private func yCoordinateFor(value: CGFloat) -> CGFloat {
        let value:CGFloat = CGFloat(fromNumeric: value)
        
        //to find out the position of a dot on a screen as a percentage
        let proportion = (value-yAxisMin)/(yAxisMax-yAxisMin)
        // y = (height - padding from top and bottom) * proportion + marhin to have a space between the bottom of a view and the point
        return (self.frame.height - paddingTop - paddingBottom) * proportion + paddingBottom
    }
}


