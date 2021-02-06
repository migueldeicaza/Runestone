//
//  LineTextInputProxy.swift
//  
//
//  Created by Simon Støvring on 02/02/2021.
//

import CoreGraphics
import CoreText
import Foundation

final class LineTextInputProxy {
    var defaultLineHeight: CGFloat = 12

    private let lineTypesetter: LineTypesetter
    private var typesetLines: [TypesetLine] {
        return lineTypesetter.typesetLines
    }

    init(lineTypesetter: LineTypesetter) {
        self.lineTypesetter = lineTypesetter
    }

    func caretRect(atIndex index: Int) -> CGRect {
        for typesetLine in typesetLines {
            let lineRange = CTLineGetStringRange(typesetLine.line)
            let localIndex = index - lineRange.location
            if localIndex >= 0 && localIndex <= lineRange.length {
                let xPos = CTLineGetOffsetForStringIndex(typesetLine.line, index, nil)
                return CGRect(x: xPos, y: typesetLine.yPosition, width: Caret.width, height: typesetLine.size.height)
            }
        }
        return CGRect(x: 0, y: 0, width: Caret.width, height: defaultLineHeight)
    }

    func selectionRects(in range: NSRange) -> [TypesetLineSelectionRect] {
        guard !typesetLines.isEmpty else {
            let rect = CGRect(x: 0, y: 0, width: 0, height: defaultLineHeight)
            return [TypesetLineSelectionRect(rect: rect, range: range)]
        }
        var selectionRects: [TypesetLineSelectionRect] = []
        for typesetLine in typesetLines {
            let line = typesetLine.line
            let cfLineRange = CTLineGetStringRange(line)
            let lineRange = NSRange(location: cfLineRange.location, length: cfLineRange.length)
            let selectionIntersection = range.intersection(lineRange)
            if let selectionIntersection = selectionIntersection {
                let xStart = CTLineGetOffsetForStringIndex(line, selectionIntersection.location, nil)
                let xEnd = CTLineGetOffsetForStringIndex(line, selectionIntersection.location + selectionIntersection.length, nil)
                let yPosition = typesetLine.yPosition
                let rect = CGRect(x: xStart, y: yPosition, width: xEnd - xStart, height: typesetLine.size.height)
                let selectionRect = TypesetLineSelectionRect(rect: rect, range: selectionIntersection)
                selectionRects.append(selectionRect)
            }
        }
        return selectionRects
    }

    func firstRect(for range: NSRange) -> CGRect {
        for typesetLine in typesetLines {
            let line = typesetLine.line
            let lineRange = CTLineGetStringRange(line)
            let index = range.location
            if index >= 0 && index <= lineRange.length {
                let finalIndex = min(lineRange.location + lineRange.length, range.location + range.length)
                let xStart = CTLineGetOffsetForStringIndex(line, index, nil)
                let xEnd = CTLineGetOffsetForStringIndex(line, finalIndex, nil)
                return CGRect(x: xStart, y: typesetLine.yPosition, width: xEnd - xStart, height: typesetLine.size.height)
            }
        }
        return CGRect(x: 0, y: 0, width: 0, height: defaultLineHeight)
    }

    func closestIndex(to point: CGPoint) -> Int {
        var closestTypesetLine = typesetLines.last
        for typesetLine in typesetLines {
            let lineMaxY = typesetLine.yPosition + typesetLine.size.height
            if point.y <= lineMaxY {
                closestTypesetLine = typesetLine
                break
            }
        }
        if let closestTypesetLine = closestTypesetLine {
            return CTLineGetStringIndexForPosition(closestTypesetLine.line, point)
        } else {
            return 0
        }
    }
}