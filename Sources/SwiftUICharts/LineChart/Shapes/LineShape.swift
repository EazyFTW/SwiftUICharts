//
//  LineShape.swift
//  LineChart
//
//  Created by Will Dale on 24/12/2020.
//

import SwiftUI

/**
 Main line shape
 */
internal struct LineShape<DP>: Shape where DP: CTStandardDataPointProtocol & IgnoreMe {
    
    private let dataPoints: [DP]
    private let lineType: LineType
    private let isFilled: Bool
    private let minValue: Double
    private let range: Double
    private let ignoreValue: Double
    
    internal init(
        dataPoints: [DP],
        lineType: LineType,
        isFilled: Bool,
        minValue: Double,
        range: Double,
        ignoreValue: Double
    ) {
        self.dataPoints = dataPoints
        self.lineType = lineType
        self.isFilled = isFilled
        self.minValue = minValue
        self.range = range
        self.ignoreValue = ignoreValue
    }
    
    internal func path(in rect: CGRect) -> Path {
        switch lineType {
            case .curvedLine:
                return ignoreValue == -Double.infinity ? Path.curvedLine(rect: rect, dataPoints: dataPoints, minValue: minValue, range: range, isFilled: isFilled) : Path.curvedLineIgnoreZero(rect: rect, dataPoints: dataPoints, minValue: minValue, range: range, isFilled: isFilled, ignoreValue: ignoreValue)
            case .line:
                return ignoreValue == -Double.infinity ? Path.straightLine(rect: rect, dataPoints: dataPoints, minValue: minValue, range: range, isFilled: isFilled) : Path.straightLineIgnoreZero(rect: rect, dataPoints: dataPoints, minValue: minValue, range: range, isFilled: isFilled, ignoreValue: ignoreValue)
            case .stepped:
                return ignoreValue == -Double.infinity ? Path.steppedLine(rect: rect, dataPoints: dataPoints, minValue: minValue, range: range, isFilled: isFilled) : Path.steppedLineIgnoreZero(rect: rect, dataPoints: dataPoints, minValue: minValue, range: range, isFilled: isFilled, ignoreValue: ignoreValue)
            }
    }
}

/**
 Background fill based on the upper and lower values
 for a Ranged Line Chart.
 */
internal struct RangedLineFillShape<DP>: Shape where DP: CTRangedLineDataPoint & IgnoreMe {
    
    private let dataPoints: [DP]
    private let lineType: LineType
    private let minValue: Double
    private let range: Double
    private let ignoreValue: Double
    
    internal init(
        dataPoints: [DP],
        lineType: LineType,
        minValue: Double,
        range: Double,
        ignoreValue: Double
    ) {
        self.dataPoints = dataPoints
        self.lineType = lineType
        self.minValue = minValue
        self.range = range
        self.ignoreValue = ignoreValue
    }
    
    internal func path(in rect: CGRect) -> Path {
        switch lineType {
            case .curvedLine:
                return ignoreValue == -Double.infinity ? Path.curvedLineBox(rect: rect, dataPoints: dataPoints, minValue: minValue, range: range) : Path.curvedLineBoxIgnoreZero(rect: rect, dataPoints: dataPoints, minValue: minValue, range: range, ignoreValue: ignoreValue)
            case .line:
                return ignoreValue == -Double.infinity ? Path.straightLineBox(rect: rect, dataPoints: dataPoints, minValue: minValue, range: range) : Path.straightLineBoxIgnoreZero(rect: rect, dataPoints: dataPoints, minValue: minValue, range: range, ignoreValue: ignoreValue)
            case .stepped:
                return ignoreValue == -Double.infinity ? Path.steppedLineBox(rect: rect, dataPoints: dataPoints, minValue: minValue, range: range) : Path.steppedLineBoxIgnoreZero(rect: rect, dataPoints: dataPoints, minValue: minValue, range: range, ignoreValue: ignoreValue)
            }
    }
}

