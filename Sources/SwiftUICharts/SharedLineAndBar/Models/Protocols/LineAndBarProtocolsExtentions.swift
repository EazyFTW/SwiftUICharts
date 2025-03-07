//
//  LineAndBarProtocolsExtentions.swift
//  
//
//  Created by Will Dale on 13/02/2021.
//

import SwiftUI

// MARK: - Data Set
extension CTLineBarChartDataProtocol where Self: GetDataProtocol,
                                           SetType: DataFunctionsProtocol {
    public var range: Double {
        get {
            var _lowestValue: Double
            var _highestValue: Double
            
            switch self.chartStyle.baseline {
            case .minimumValue:
                _lowestValue = self.dataSets.minValue()
            case .minimumWithMaximum(of: let value):
                _lowestValue = value
            case .zero:
                _lowestValue = 0
            }
            
            switch self.chartStyle.topLine {
            case .maximumValue:
                _highestValue = self.dataSets.maxValue()
            case .maximum(of: let value):
                _highestValue = max(self.dataSets.maxValue(), value)
            }
            
            return (_highestValue - _lowestValue)
        }
    }
    
    public var minValue: Double {
        get {
            switch self.chartStyle.baseline {
            case .minimumValue:
                return self.dataSets.minValue()
            case .minimumWithMaximum(of: let value):
                return value
            case .zero:
                return 0
            }
        }
    }
    
    public var maxValue: Double {
        get {
            switch self.chartStyle.topLine {
            case .maximumValue:
                return self.dataSets.maxValue()
            case .maximum(of: let value):
                return max(self.dataSets.maxValue(), value)
            }
        }
    }
    
    public var average: Double {
        return self.dataSets.average()
    }
}

// MARK: - Y Axis
extension CTLineBarChartDataProtocol where Self: GetDataProtocol {
    /**
     Array of labels generated by
     `getYLabels(_ specifier: String) -> [String]`.
     
     They are either auto calculated numbers
     or array of strings.
     */
    internal var labelsArray: [String] {
        self.generateYLabels(self.viewData.yAxisSpecifier,
                             numberFormatter: self.viewData.yAxisNumberFormatter)
    }
    
    /**
     Labels to display on the Y axis
     
     If `yAxisLabelType`is set to `.numeric`, the labels get
     generated based on the range between the `minValue` and
     `maxValue`.
     
     If `yAxisLabelType`is set to `.custom`, the labels come
     from `ChartData -> yAxisLabels`.
     
     - Parameters:
        - specifier: Decimal precision of the labels.
     - Returns: Array of labels.
     */
    private func generateYLabels(_ specifier: String, numberFormatter: NumberFormatter?) -> [String] {
        switch self.chartStyle.yAxisLabelType {
        case .numeric:
            let dataRange: Double = self.range
            let minValue: Double = self.minValue
            let range: Double = dataRange / Double(self.chartStyle.yAxisNumberOfLabels-1)
            let firstLabel: [String] = {
                if let formatter = numberFormatter,
                   let formattedNumber = formatter.string(from: NSNumber(value:minValue)) {
                    return [formattedNumber]
                } else {
                    return [String(format: specifier, minValue)]
                }
            }()
            let otherLabels: [String] = (1...self.chartStyle.yAxisNumberOfLabels-1).map {
                let value = minValue + range * Double($0)
                if let formatter = numberFormatter,
                   let formattedNumber = formatter.string(from: NSNumber(value: value)) {
                    return formattedNumber
                } else {
                    return String(format: specifier, value)
                }
            }
            let labels = firstLabel + otherLabels
            return labels
        case .custom:
            return self.yAxisLabels ?? []
        }
    }
}


extension CTLineBarChartDataProtocol {
   internal var yAxisPaddingHeight: CGFloat {
        (self.viewData.xAxisLabelHeights.max() ?? 0) + self.viewData.xAxisTitleHeight
    }
}

extension CTLineBarChartDataProtocol where Self: GetDataProtocol {
    public func getYAxisLabels() -> some View {
        VStack {
            if self.chartStyle.xAxisLabelPosition == .top {
                Spacer()
                    .frame(height: yAxisPaddingHeight)
            }
            ForEach(self.labelsArray.indices.reversed(), id: \.self) { i in
                Text(LocalizedStringKey(self.labelsArray[i]))
                    .font(self.chartStyle.yAxisLabelFont)
                    .foregroundColor(self.chartStyle.yAxisLabelColour)
                    .lineLimit(1)
                    .overlay(
                        GeometryReader { geo in
                            Rectangle()
                                .foregroundColor(Color.clear)
                                .onAppear {
                                    self.viewData.yAxisLabelWidth.append(geo.size.width)
                                }
                        }
                    )
                    .accessibilityLabel(LocalizedStringKey("Y-Axis-Label"))
                    .accessibilityValue(LocalizedStringKey(self.labelsArray[i]))
                if i != 0 {
                    Spacer()
                        .frame(minHeight: 0, maxHeight: 500)
                }
            }
            if self.chartStyle.xAxisLabelPosition == .bottom {
                Spacer()
                    .frame(height: yAxisPaddingHeight)
            }
        }
        .ifElse(self.chartStyle.xAxisLabelPosition == .bottom, if: {
            $0.padding(.top, -8)
        }, else: {
            $0.padding(.bottom, -8)
        })
    }
}

// MARK: - Axes Titles
extension CTLineBarChartDataProtocol {
    /**
     Returns the title for y axis.
     
     This also informs `ViewData` of it width so
     that the positioning of the views in the x axis
     can be calculated.
     */
    public func getYAxisTitle(colour: AxisColour) -> some View {
        Group {
            if let title = self.chartStyle.yAxisTitle {
                VStack {
                    if self.chartStyle.xAxisLabelPosition == .top {
                        Spacer()
                            .frame(height: yAxisPaddingHeight)
                    }
                    VStack(spacing: 0) {
                        Text(LocalizedStringKey(title))
                            .font(self.chartStyle.yAxisTitleFont)
                            .foregroundColor(self.chartStyle.yAxisTitleColour)
                            .background(
                                GeometryReader { geo in
                                    Rectangle()
                                        .foregroundColor(Color.clear)
                                        .onAppear {
                                            self.viewData.yAxisTitleWidth = geo.size.height + 10 // 10 to add padding
                                            self.viewData.yAxisTitleHeight = geo.size.width
                                        }
                                }
                            )
                            .rotationEffect(Angle.init(degrees: -90), anchor: .center)
                            .fixedSize()
                            .frame(width: self.viewData.yAxisTitleWidth)
                        Group {
                            switch colour {
                            case .none:
                                EmptyView()
                            case .style(let size):
                                self.getAxisColourAsCircle(customColour: self.getColour(), width: size)
                            case .custom(let colour, let size):
                                self.getAxisColourAsCircle(customColour: colour, width: size)
                            }
                        }
                        .offset(x: 0, y: self.viewData.yAxisTitleHeight / 2)
                    }
                    if self.chartStyle.xAxisLabelPosition == .bottom {
                        Spacer()
                            .frame(height: yAxisPaddingHeight)
                    }
                }
            }
        }
    }
    
    /**
     Returns the title for x axis.
     
     This also informs `ViewData` of it height so
     that the positioning of the views in the y axis
     can be calculated.
     */
    internal func getXAxisTitle() -> some View {
        Group {
            if let title = self.chartStyle.xAxisTitle {
                Text(LocalizedStringKey(title))
                    .font(self.chartStyle.xAxisTitleFont)
                    .foregroundColor(self.chartStyle.xAxisTitleColour)
                    .ifElse(self.chartStyle.xAxisLabelPosition == .bottom, if: {
                        $0.padding(.top, 2)
                    }, else: {
                        $0.padding(.bottom, 2)
                    })
                    .background(
                        GeometryReader { geo in
                            Rectangle()
                                .foregroundColor(Color.clear)
                                .onAppear {
                                    self.viewData.xAxisTitleHeight = geo.size.height + 10
                                }
                        }
                    )
            }
        }
    }
    
    internal func getAxisColourAsCircle(customColour: ColourStyle, width: CGFloat) -> some View {
        Group {
            if let colour = customColour.colour {
                HStack {
                    Circle()
                        .fill(colour)
                        .frame(width: width, height: width)
                }
            } else if let colours = customColour.colours {
                HStack {
                    Circle()
                        .fill(LinearGradient(gradient: Gradient(colors: colours),
                                             startPoint: .leading,
                                             endPoint: .trailing))
                        .frame(width: width, height: width)
                }
            } else if let stops = customColour.stops {
                let stops = GradientStop.convertToGradientStopsArray(stops: stops)
                HStack {
                    Circle()
                        .fill(LinearGradient(gradient: Gradient(stops: stops),
                                             startPoint: .leading,
                                             endPoint: .trailing))
                        .frame(width: width, height: width)
                }
            } else { EmptyView() }
        }
    }
}
extension CTLineBarChartDataProtocol where Self: CTLineChartDataProtocol,
                                           Self.SetType: CTLineChartDataSet {
    public func getColour() -> ColourStyle {
        dataSets.style.lineColour
    }
}
extension CTLineBarChartDataProtocol where Self: CTLineChartDataProtocol,
                                           Self.SetType: CTMultiLineChartDataSet,
                                           Self.SetType.DataSet: CTLineChartDataSet {
    public func getColour() -> ColourStyle {
        dataSets.dataSets.first?.style.lineColour ?? ColourStyle()
    }
}
extension CTLineBarChartDataProtocol where Self: CTBarChartDataProtocol {
    public func getColour() -> ColourStyle {
        barStyle.colour
    }
}


// MARK: - Extra Y Axis Labels
extension CTLineBarChartDataProtocol {
    
    internal var extraLabelsArray: [String] { self.generateExtraYLabels(self.viewData.yAxisSpecifier) }
    private func generateExtraYLabels(_ specifier: String) -> [String] {
        guard let extraLineData = extraLineData else { return [] }
        let dataRange: Double = extraLineData.range
        let minValue: Double = extraLineData.minValue
        let range: Double = dataRange / Double(extraLineData.style.yAxisNumberOfLabels-1)
        let firstLabel = [String(format: specifier, minValue)]
        let otherLabels = (1...extraLineData.style.yAxisNumberOfLabels-1).map { String(format: specifier, minValue + range * Double($0)) }
        let labels = firstLabel + otherLabels
        return labels

    }
    
    public func getExtraYAxisLabels() -> some View {
        VStack {
            if self.chartStyle.xAxisLabelPosition == .top {
                Spacer()
                    .frame(height: yAxisPaddingHeight)
            }
            ForEach(self.extraLabelsArray.indices.reversed(), id: \.self) { i in
                Text(LocalizedStringKey(self.extraLabelsArray[i]))
                    .font(self.chartStyle.yAxisLabelFont)
                    .foregroundColor(self.chartStyle.yAxisLabelColour)
                    .lineLimit(1)
                    .overlay(
                        GeometryReader { geo in
                            Rectangle()
                                .foregroundColor(Color.clear)
                                .onAppear {
                                    self.viewData.yAxisLabelWidth.append(geo.size.width)
                                }
                        }
                    )
                    .accessibilityLabel(LocalizedStringKey("Y-Axis-Label"))
                    .accessibilityValue(LocalizedStringKey(self.extraLabelsArray[i]))
                if i != 0 {
                    Spacer()
                        .frame(minHeight: 0, maxHeight: 500)
                }
            }
            if self.chartStyle.xAxisLabelPosition == .bottom {
                Spacer()
                    .frame(height: yAxisPaddingHeight)
            }
        }
        .ifElse(self.chartStyle.xAxisLabelPosition == .bottom, if: {
            $0.padding(.top, -8)
        }, else: {
            $0.padding(.bottom, -8)
        })
    }
    
    public func getExtraYAxisTitle(colour: AxisColour) -> some View {
        Group {
            if let title = self.extraLineData?.style.yAxisTitle {
                VStack {
                    if self.chartStyle.xAxisLabelPosition == .top {
                        Spacer()
                            .frame(height: yAxisPaddingHeight)
                    }
                    VStack {
                        Text(LocalizedStringKey(title))
                            .font(self.chartStyle.yAxisTitleFont)
                            .foregroundColor(self.chartStyle.yAxisTitleColour)
                            .background(
                                GeometryReader { geo in
                                    Rectangle()
                                        .foregroundColor(Color.clear)
                                        .onAppear {
                                            self.viewData.extraYAxisTitleWidth = geo.size.height + 10 // 10 to add padding
                                            self.viewData.extraYAxisTitleHeight = geo.size.width
                                        }
                                }
                            )
                            .rotationEffect(Angle.init(degrees: -90), anchor: .center)
                            .fixedSize()
                            .frame(width: self.viewData.extraYAxisTitleWidth)
                        Group {
                            switch colour {
                            case .none:
                                EmptyView()
                            case .style(let size):
                                self.getAxisColourAsCircle(customColour: self.extraLineData?.style.lineColour ?? ColourStyle(), width: size)
                            case .custom(let colour, let size):
                                self.getAxisColourAsCircle(customColour: colour, width: size)
                            }
                        }
                        .offset(x: 0, y: self.viewData.extraYAxisTitleHeight / 2)
                    }
                    if self.chartStyle.xAxisLabelPosition == .bottom {
                        Spacer()
                            .frame(height: yAxisPaddingHeight)
                    }
                }
            }
        }
    }
}
