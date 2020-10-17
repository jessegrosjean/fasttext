import CoreText
import Foundation

struct FragmentBounds {
    var width: CGFloat
    var ascent: CGFloat
    var descent: CGFloat
    var height: CGFloat {
        ascent + descent
    }
    var leading: CGFloat
}

extension CTFrame {
    final var lines: [CTLine] {
        CTFrameGetLines(self) as! [CTLine]
    }
}

extension CTLine {
    var stringRange: CFRange {
        CTLineGetStringRange(self)
    }

    final func stringIndex(for position: CGPoint) -> Int {
        CTLineGetStringIndexForPosition(self, position)
    }

    final func fractionOfDistanceThroughGlyph(for point: CGPoint) -> CGFloat {
        guard point.x > 0 else {
            return 0
        }

        var runStart: CGFloat = 0
        var result: CGFloat = 1
        withGlyphRuns { run, stop in
            let runEnd = runStart + run.typographicBounds(for: CFRange(location: 0, length: run.glyphCount)).width
            if point.x < runEnd {
                result = run.fractionOfDistanceThroughGlyph(for: point)
                stop = true
            }
            runStart = runEnd
        }
        return result
    }

    final var typographicBounds: FragmentBounds {
        var bounds = FragmentBounds(width: 0, ascent: 0, descent: 0, leading: 0)
        bounds.width = CGFloat(CTLineGetTypographicBounds(self, &bounds.ascent, &bounds.descent, &bounds.leading))
        return bounds
    }

    final func offset(for stringIndex: Int, secondaryOffset: UnsafeMutablePointer<CGFloat>? = nil) -> CGFloat {
        CTLineGetOffsetForStringIndex(self, stringIndex, secondaryOffset)
    }

    final var glyphRuns: [CTRun] {
        CTLineGetGlyphRuns(self) as! [CTRun]
    }

    final func rect(forCharacterRange characterRange: CFRange, top: CGFloat? = nil, bottom: CGFloat? = nil, actualRange: NSRangePointer? = nil) -> CGRect {
        let top = top ?? 0
        let bottom = bottom ?? top + typographicBounds.height
        var runsRange: CFRange?
        var unionRect = CGRect.null

        withGlyphRuns { run, stop in
            let runRange = run.stringRange
            if let runIntersection = characterRange.intersection(range: runRange) {
                let runIntersectionRect = run.rect(forCharacterRange: runIntersection, top: top, bottom: bottom)
                runsRange = runsRange?.union(range: runRange) ?? runRange
                if unionRect.isNull {
                    unionRect = runIntersectionRect
                } else {
                    unionRect = unionRect.union(runIntersectionRect)
                }
            }
        }

        if let actualRange = actualRange {
            if let runsRange = runsRange {
                actualRange.pointee = NSRange(range: runsRange)
            } else {
                actualRange.pointee = NSMakeRange(NSNotFound, 0)
            }
        }
        
        return unionRect
    }

    final func withGlyphRuns(_ callback: (_ glyphRun: CTRun, _ stop: inout Bool) -> Void) {
        let glyphRuns = CTLineGetGlyphRuns(self) as! [CTRun]
        var stop = false
        for each in glyphRuns {
            callback(each, &stop)
            if stop {
                return
            }
        }
    }
}

extension CTRun {
    final func isVisuallyEqual(to run: CTRun) -> Bool {
        if glyphCount != run.glyphCount {
            return false
        }

        if !(attributes as NSDictionary).isEqual(to: run.attributes as! [AnyHashable: Any]) {
            return false
        }

        var result = true
        withGlyphsPointer { glyphsPointer in
            run.withGlyphsPointer { otherGlyphsPointer in
                for each in 0 ..< glyphCount {
                    if glyphsPointer[each] != otherGlyphsPointer[each] {
                        result = false
                        return
                    }
                }
            }
        }

        return result
    }

    final var attributes: CFDictionary {
        CTRunGetAttributes(self)
    }

    final var stringRange: CFRange {
        CTRunGetStringRange(self)
    }

    final var status: CTRunStatus {
        CTRunGetStatus(self)
    }

    final func typographicBounds(for range: CFRange? = CFRange(location: 0, length: 0)) -> FragmentBounds {
        let range = range ?? CFRange(location: 0, length: 0)
        var bounds = FragmentBounds(width: 0, ascent: 0, descent: 0, leading: 0)
        bounds.width = CGFloat(CTRunGetTypographicBounds(self, range, &bounds.ascent, &bounds.descent, &bounds.leading))
        return bounds
    }

    final func fractionOfDistanceThroughGlyph(for point: CGPoint) -> CGFloat {
        guard point.x > 0 else {
            return 0
        }

        var glyphStart: CGFloat = 0
        for each in 0 ..< glyphCount {
            let glyphEnd = glyphStart + typographicBounds(for: CFRange(location: each, length: 1)).width
            if point.x < glyphEnd {
                return (point.x - glyphStart) / (glyphEnd - glyphStart)
            }
            glyphStart = glyphEnd
        }

        return 1
    }

    final var glyphCount: Int {
        CTRunGetGlyphCount(self)
    }

    final func withGlyphsPointer(_ callback: (_ pointer: UnsafePointer<CGGlyph>) -> Void) {
        if let glyphsPointer = CTRunGetGlyphsPtr(self) {
            callback(glyphsPointer)
        } else {
            var glyphs = [CGGlyph](repeating: 0, count: glyphCount)
            CTRunGetGlyphs(self, CFRangeMake(0, 0), &glyphs)
            callback(glyphs)
        }
    }

    final func withStringIndicesPointer(_ callback: (_ pointer: UnsafePointer<CFIndex>) -> Void) {
        if let stringIndicesPointer = CTRunGetStringIndicesPtr(self) {
            callback(stringIndicesPointer)
        } else {
            let glyphCount = self.glyphCount
            var stringIndices = [Int](repeating: 0, count: glyphCount)
            CTRunGetStringIndices(self, CFRangeMake(0, 0), &stringIndices)
            callback(stringIndices)
        }
    }

    final func withGlyphPositionsPointer(_ callback: (_ pointer: UnsafePointer<CGPoint>) -> Void) {
        if let glyphPositionsPointer = CTRunGetPositionsPtr(self) {
            callback(glyphPositionsPointer)
        } else {
            let glyphCount = self.glyphCount
            var glyphPositions = [CGPoint](repeating: CGPoint.zero, count: glyphCount)
            CTRunGetPositions(self, CFRangeMake(0, 0), &glyphPositions)
            callback(glyphPositions)
        }
    }

    final func glyphIndex(forCharacterIndex characterIndex: CFIndex) -> CFIndex {
        let glyphCount = self.glyphCount
        let status = self.status
        var result = glyphCount - 1

        withStringIndicesPointer { pointer in
            if status.contains(.nonMonotonic) {
                for glyphIndex in 0 ..< glyphCount {
                    if pointer[glyphIndex] == characterIndex {
                        result = glyphIndex
                        return
                    }
                }
            } else if status.contains(.rightToLeft) {
                for glyphIndex in 0 ..< glyphCount {
                    if pointer[glyphIndex] == characterIndex {
                        result = glyphIndex
                        return
                    } else if pointer[glyphIndex] < characterIndex {
                        result = glyphIndex + 1
                        return
                    }
                }
                result = 0
            } else {
                for glyphIndex in 0 ..< glyphCount {
                    if pointer[glyphIndex] == characterIndex {
                        result = glyphIndex
                        return
                    } else if pointer[glyphIndex] > characterIndex {
                        result = glyphIndex - 1
                        return
                    }
                }
                result = glyphCount - 1
            }
        }

        return result
    }

    final func glyphRange(forCharacterRange characterRange: CFRange) -> CFRange {
        let startGlyphIndex = glyphIndex(forCharacterIndex: characterRange.location)
        let endGlyphIndex = glyphIndex(forCharacterIndex: max(0, characterRange.max - 1))
        return CFRange(location: min(startGlyphIndex, endGlyphIndex), length: abs(endGlyphIndex - startGlyphIndex))
    }

    final func rect(forCharacterRange characterRange: CFRange, top: CGFloat, bottom: CGFloat) -> CGRect {
        let glyphRange = self.glyphRange(forCharacterRange: characterRange)
        let startGlyphIndex = glyphRange.location
        let endGlyphIndex = glyphRange.max
        var startPosition = CGPoint.zero
        var endPosition = CGPoint.zero
        withGlyphPositionsPointer { pointer in
            startPosition = pointer[startGlyphIndex]
            endPosition = pointer[endGlyphIndex]
        }
        let start = min(startPosition.x, endPosition.x)
        let bounds = typographicBounds(for: CFRangeMake(startGlyphIndex, (endGlyphIndex - startGlyphIndex) + 1))
        return CGRect(x: start, y: top, width: bounds.width, height: bottom)
    }
}

extension CTTypesetter {
    final func createLine(from range: CFRange) -> CTLine {
        CTTypesetterCreateLine(self, range)
    }

    final func suggestedLineBreak(startIndex: Int, width: Double) -> Int {
        CTTypesetterSuggestLineBreak(self, startIndex, width)
    }
}
