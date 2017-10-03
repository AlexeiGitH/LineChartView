//
//  LineChart.swift
//  LineChart
//
//  Created by Alex on 2017-08-31.
//  Copyright © 2017 Alex Kozachenko. All rights reserved.
//

import Cocoa

class LineChartView<x:CustomStringConvertible, y:Numeric>: NSView {
    
    //must be convertable to a CGFloat (so that adhere to Numeric protocol).
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
    var reversed = false
    
    var chartLineWidth: CGFloat = 1
    var chartLineColour: NSColor = #colorLiteral(red: 0, green: 0.9411764706, blue: 1, alpha: 1)
    var chartlineCapStyle: NSLineCapStyle = .buttLineCapStyle
    var chartlineJoinStyle: NSLineJoinStyle = .roundLineJoinStyle
    
    var chartPointRadius: CGFloat = 4
    var chartPointColour: NSColor = #colorLiteral(red: 0, green: 0.9411764706, blue: 1, alpha: 1)
    
    var xAxisLineWidth: CGFloat = 0.6
    var yAxisLineWidth: CGFloat = 0.6
    
    var xAxisLineColor: NSColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
    var yAxisLineColor: NSColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
    
    // ** GRIDLINES **
    var xGridlinesWidth: CGFloat = 0.2
    var yGridlinesWidth: CGFloat = 0.2
    
    var xGridlinesColor: NSColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
    var yGridlinesColor: NSColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
    
    ///By default it shows 3 grid lines
    var yAxisUnitStep: CGFloat = 1
    var yAxisLabelsNumberOfDecimal: Int = 2
    
    // these used to scale the graph's Y axis and to put labels on Y axis
    /// Assigned on initialzation, and by default is equal to the Max value of Y points
    var yAxisMax: CGFloat = 10.0
    /// Assigned on initialzation, and by default is equal to the Min value of Y points
    var yAxisMin: CGFloat = 0.0
    
    ///By default is the same as the number of Y points.
    ///Needs to be set after initialization

    // ** PADDING **
    //padding to clear area around the content
    private let minPadding: CGFloat = 20
    
    var padding: CGFloat = 20 {
        didSet {
            padding = checkPadding(p: padding)
            matchPaddingsToMainPadding()
        }
    }
    var paddingTop: CGFloat = 20 {
        didSet {
            paddingTop = checkPadding(p: paddingTop)
        }
    }
    var paddingBottom: CGFloat = 20{
        didSet {
            paddingBottom = checkPadding(p: paddingBottom)
        }
    }
    var paddingLeft: CGFloat = 20 {
        didSet {
            paddingLeft = checkPadding(p: paddingLeft)
        }
    }
    var paddingRight: CGFloat = 20 {
        didSet {
            paddingRight = checkPadding(p: paddingRight)
        }
    }

    
    //Text attribute
    var yAttrs : [String : Any]! = [:] //used to add values of Y axis (lowest, heightest)
    
    //MARK:- Private variables
    // used to calculate the distance between point on a X coordinate axis. Should be enough space to place all the xPoints.
    private var xIntervalWidth: CGFloat = 1
    // number of points needed to be displayed on a chart.
    // TODO: Add manual number of intervals. If *manualInterwalWidth* is `true`, the number of intervals is calculated based on the *xIntervalWidth*. If *manualInterwalWidth* is `false`, *numberOfIntervals* used to calculate the *xIntervalWidth*.
    private var numberOfIntervals: Int = 0
    
    

    
    //MARK:- INIT
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        editAttributes()
        resetYAxisUnitStep()
    }
    
    init(frame frameRect: NSRect, xValues: [x], yValues: [y]) {
        super.init(frame: frameRect)
        self.xPoints = xValues
        self.yPoints = yValues
        editAttributes()
        resetYAxisUnitStep()
    }
    
    required init?(coder: NSCoder) {
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
    override func draw(_ dirtyRect: NSRect) {
        drawGraph()
    }
    
    // graphic context
    private var currentContext : CGContext? {
        get {
            if #available(OSX 10.10, *) {
                return NSGraphicsContext.current()?.cgContext
            } else if let contextPointer = NSGraphicsContext.current()?.graphicsPort {
                let context: CGContext = Unmanaged.fromOpaque(contextPointer).takeRetainedValue()
                return context
            }
            return nil
        }
    }
    
    private func drawGraph() {
        calculateDrawingVariables()
        drawXAxis()
        drawYAxis()
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
        guard numberOfIntervals > 0 else {
            return
        }
        let y = self.frame.height - paddingTop
        for i in 1..<numberOfIntervals {
            let x = xCoordinateFor(column: i)
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
    }
    
    //horizontal bottom to top
    private func drawYGridlines() {

        guard yPoints.count > 0 else { return }
        if yAxisUnitStep <= 0 { yAxisUnitStep = 0.01 } //to avoid devision by 0

        //calculate number of grids to display
        let gridNumFloat = round((yAxisMax-yAxisMin)/yAxisUnitStep)
        var numGrids = Int(round(gridNumFloat))
        let decimalsMultiplier = CGFloat(pow(10, Double(yAxisLabelsNumberOfDecimal)))
        if ( round((gridNumFloat * yAxisUnitStep + yAxisMin)*decimalsMultiplier)/decimalsMultiplier > yAxisMax) {
            numGrids -= 1
        }
        
        guard  numGrids > 0 else { return }
        
        let leftX = xCoordinateFor(column: numberOfIntervals-1)
        
        // add low Y label
        let value = yAxisMin
        let yCoord = yCoordinateFor(value: value)
    
        let label = String(format: "%.\(yAxisLabelsNumberOfDecimal)f", value)
        let startLabelPoint = CGPoint(x: paddingLeft, y: yCoord)
        label.draw(at: startLabelPoint, withAttributes: yAttrs)
        
        // add other labels
        for gridN in 1...numGrids {
            let value = yAxisMin + CGFloat(gridN) * yAxisUnitStep
            let yCoord = yCoordinateFor(value: value)
            let leftPoint = CGPoint(x: paddingLeft, y: yCoord) //left side
            let rightPoint = CGPoint(x: leftX, y: yCoordinateFor(value: value)) //left bottom corner
            
            let path = NSBezierPath()
            path.move(to: leftPoint)
            path.line(to: rightPoint)
            yGridlinesColor.set()
            let pattern: [CGFloat] = [4.0, 0.0]
            path.setLineDash(pattern, count: 1, phase: 0)
            path.stroke()
            
            //Label string
            let label = String(format: "%.\(yAxisLabelsNumberOfDecimal)f", value)
            let startLabelPoint = CGPoint(x: paddingLeft, y: yCoord)
            label.draw(at: startLabelPoint, withAttributes: yAttrs)
        }
    }

    
    //MARK: chart Points Positions Calculations

    func autoParameters() {
        resetPadding()
    }
    
    final func editAttributes(font: NSFont = NSFont.systemFont(ofSize: 12), alignment: NSTextAlignment = .left, color: NSColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)) {
        let paraStyle = NSParagraphStyle.default().mutableCopy()
            as! NSMutableParagraphStyle
        paraStyle.alignment = alignment
        
        self.yAttrs = [
            NSFontAttributeName: font,
            NSParagraphStyleAttributeName: paraStyle,
            NSForegroundColorAttributeName: color,
            //  NSBackgroundColorAttributeName: NSColor.yellow //for debuging purpose
        ]
    }
    final func yLabelsColor(color: NSColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)) {
        changeColorOfYAttributes(toColor: color)
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
    ///To update the chart view when one or more attributes were changed
    func update() {
        needsDisplay = true
    }
    
    //TODO:- To convert points to the value on a graph
    override func mouseDown(with event : NSEvent) {
        
        let  pointFromNil = convert(event.locationInWindow, from: nil)
        
        Swift.print("pointFromNil: \(pointFromNil)")
    }
    
    //MARK:- Private methods
    /**
     Calculates all the parameters to draw a graph
     */
    private func calculateDrawingVariables() {
        xIntervalWidth = max((self.frame.width - paddingLeft - paddingRight) / CGFloat(numberOfIntervals-1), CGFloat(1))
    }
    ///Default color is white
    private func changeColorOfYAttributes(toColor: NSColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)) {
        self.yAttrs[NSForegroundColorAttributeName] = toColor
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
