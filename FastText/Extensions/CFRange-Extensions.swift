import Foundation

extension CFRange {
    init(range: NSRange) {
        self = CFRangeMake(range.location == NSNotFound ? kCFNotFound : range.location, range.length)
    }

    var max: CFIndex {
        location + length
    }

    func union(range: CFRange) -> CFRange {
        let min = Swift.min(location, range.location)
        let max = Swift.max(self.max, range.max)
        return CFRange(location: min, length: max - min)
    }

    func intersection(range: CFRange) -> CFRange? {
        let r = NSIntersectionRange(NSRange(range: self), NSRange(range: range))
        if r.length == 0 {
            return nil
        } else {
            return CFRange(range: r)
        }
    }

    func contains(location: CFIndex) -> Bool {
        location >= self.location && location < max
    }
}

extension NSRange {
    init(range: CFRange) {
        self = NSMakeRange(range.location == kCFNotFound ? NSNotFound : range.location, range.length)
    }

    var max: Int {
        location + length
    }
}

extension CFRange: Equatable {}

public func == (lhs: CFRange, rhs: CFRange) -> Bool {
    lhs.location == rhs.location && lhs.length == rhs.length
}

func == <T: Equatable>(lhs: [T]?, rhs: [T]?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?): // shortcut for (.Some(l), .Some(r))
        return l == r
    case (.none, .none):
        return true
    default:
        return false
    }
}

func equalArrays<T: Equatable>(lhs: [T]?, rhs: [T]?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?): // shortcut for (.Some(l), .Some(r))
        return l == r
    case (.none, .none):
        return true
    default:
        return false
    }
}

func equalDictionaries<T: Equatable>(lhs: [String: T]?, rhs: [String: T]?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?): // shortcut for (.Some(l), .Some(r))
        return l == r
    case (.none, .none):
        return true
    default:
        return false
    }
}
