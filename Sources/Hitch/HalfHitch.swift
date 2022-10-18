// swiftlint:disable type_body_length

import Foundation

/// HalfHitch is a Hitch-like view on raw data.  In other words, when you need to do string-like
/// processing on existing data without copies or allocations, then HalfHitch is your answer.
/// Note: as you can gather from the above, use HalfHitch carefully!
public struct HalfHitch: Hitchable, CustomStringConvertible, ExpressibleByStringLiteral, Sequence, Comparable, Hashable, Codable {
    
    public static let empty: HalfHitch = ""

    @inlinable @inline(__always)
    public static func == (lhs: HalfHitch, rhs: HalfHitch) -> Bool {
        return lhs.count == rhs.count &&
                lhs.lastHash1 == rhs.lastHash1 &&
                lhs.lastHash2 == rhs.lastHash2 &&
                lhs.lastHash3 == rhs.lastHash3
    }

    @inlinable @inline(__always)
    public static func == (lhs: HalfHitch, rhs: StaticString) -> Bool {
        guard lhs.count == rhs.utf8CodeUnitCount else { return false }
        let halfhitch = HalfHitch(hashOnly: rhs)
        return lhs.lastHash1 == halfhitch.lastHash1 &&
                lhs.lastHash2 == halfhitch.lastHash2 &&
                lhs.lastHash3 == halfhitch.lastHash3
    }

    @inlinable @inline(__always)
    public static func == (lhs: StaticString, rhs: HalfHitch) -> Bool {
        guard lhs.utf8CodeUnitCount == rhs.count else { return false }
        let halfhitch = HalfHitch(stringLiteral: lhs)
        return halfhitch.lastHash1 == rhs.lastHash1 &&
                halfhitch.lastHash2 == rhs.lastHash2 &&
                halfhitch.lastHash3 == rhs.lastHash3
    }
    
    @inlinable @inline(__always)
    public static func ~== (lhs: HalfHitch, rhs: HalfHitch) -> Bool {
        return chitch_equal_caseless_raw(lhs.raw(), lhs.count, rhs.raw(), rhs.count)
    }

    @inlinable @inline(__always)
    public static func ~== (lhs: HalfHitch, rhs: StaticString) -> Bool {
        guard lhs.count == rhs.utf8CodeUnitCount else { return false }
        let halfhitch = HalfHitch(hashOnly: rhs)
        return chitch_equal_caseless_raw(lhs.raw(), lhs.count, halfhitch.raw(), halfhitch.count)
    }

    @inlinable @inline(__always)
    public static func ~== (lhs: StaticString, rhs: HalfHitch) -> Bool {
        guard lhs.utf8CodeUnitCount == rhs.count else { return false }
        let halfhitch = HalfHitch(stringLiteral: lhs)
        return chitch_equal_caseless_raw(halfhitch.raw(), halfhitch.count, rhs.raw(), rhs.count)
    }

    @usableFromInline
    let sourceObject: AnyObject?

    @usableFromInline
    let source: UnsafePointer<UInt8>?

    @usableFromInline
    let maybeMutable: Bool

    public var count: Int

    @usableFromInline
    let lastHash1: Int
    @usableFromInline
    let lastHash2: Int
    @usableFromInline
    let lastHash3: Int

    @inlinable @inline(__always)
    public static func using<T>(data: Data, from: Int = 0, to: Int = -1, _ callback: (HalfHitch) -> T?) -> T? {
        return data.withUnsafeBytes { unsafeRawBufferPointer in
            let unsafeBufferPointer = unsafeRawBufferPointer.bindMemory(to: UInt8.self)
            guard let bytes = unsafeBufferPointer.baseAddress else { return nil }
            return callback(HalfHitch(sourceObject: nil,
                                      raw: bytes,
                                      count: data.count,
                                      from: from,
                                      to: to >= 0 ? to : data.count))
        }
    }
    
    @inlinable @inline(__always)
    public var description: String {
        return toTempString()
    }

    public init?(contentsOfFile path: String) {
        guard let source = Hitch(contentsOfFile: path) else { return nil }
        if let raw = source.mutableRaw() {
            self.sourceObject = source
            self.source = UnsafePointer(raw)
            self.count = source.count
            self.maybeMutable = true
        } else if let raw = source.raw() {
            self.sourceObject = source
            self.source = raw
            self.count = source.count
            self.maybeMutable = false
        } else {
            self.sourceObject = nil
            self.source = nil
            self.count = 0
            self.maybeMutable = false
        }
        (lastHash1, lastHash2, lastHash3) = chitch_multihash_raw(self.source, self.count)
    }
    
    public init(utf8 raw: UnsafePointer<UInt8>) {
        self.sourceObject = nil
        self.source = raw
        self.count = strlen(raw)
        self.maybeMutable = true
        (lastHash1, lastHash2, lastHash3) = chitch_multihash_raw(self.source, self.count)
    }

    public init(sourceObject: AnyObject?, raw: UnsafePointer<UInt8>, count: Int, from: Int, to: Int) {
        self.sourceObject = sourceObject
        self.source = raw + from
        self.count = to - from
        self.maybeMutable = true
        (lastHash1, lastHash2, lastHash3) = chitch_multihash_raw(self.source, self.count)
    }

    public init(source: Hitch, from: Int, to: Int) {
        if let raw = source.mutableRaw() {
            self.sourceObject = source
            self.source = UnsafePointer(raw) + from
            self.count = to - from
            self.maybeMutable = true
        } else if let raw = source.raw() {
            self.sourceObject = source
            self.source = raw + from
            self.count = to - from
            self.maybeMutable = false
        } else {
            self.sourceObject = nil
            self.source = nil
            self.count = 0
            self.maybeMutable = false
        }
        (lastHash1, lastHash2, lastHash3) = chitch_multihash_raw(self.source, self.count)
    }

    public init(source: HalfHitch, from: Int, to: Int) {
        self.sourceObject = source.sourceObject
        if let raw = source.source {
            self.source = raw + from
            self.count = to - from
            self.maybeMutable = source.maybeMutable
        } else {
            self.source = nil
            self.count = 0
            self.maybeMutable = false
        }
        (lastHash1, lastHash2, lastHash3) = chitch_multihash_raw(self.source, self.count)
    }

    public init() {
        self.sourceObject = nil
        self.source = nil
        self.count = 0
        self.maybeMutable = false
        (lastHash1, lastHash2, lastHash3) = chitch_multihash_raw(self.source, self.count)
    }

    public init(stringLiteral: StaticString) {
        if stringLiteral.hasPointerRepresentation {
            self.sourceObject = nil
            self.source = stringLiteral.utf8Start
            self.count = stringLiteral.utf8CodeUnitCount
            self.maybeMutable = false
        } else {
            let source = Hitch(stringLiteral: stringLiteral)
            if let raw = source.raw() {
                self.sourceObject = source
                self.source = raw
                self.count = source.count
                self.maybeMutable = false
            } else {
                self.sourceObject = nil
                self.source = nil
                self.count = 0
                self.maybeMutable = false
            }
        }
        (lastHash1, lastHash2, lastHash3) = chitch_multihash_raw(self.source, self.count)
    }

    public init(string: String) {
        let source = Hitch(string: string)
        if let raw = source.mutableRaw() {
            self.sourceObject = source
            self.source = UnsafePointer(raw)
            self.count = source.count
            self.maybeMutable = true
        } else if let raw = source.raw() {
            self.sourceObject = source
            self.source = raw
            self.count = source.count
            self.maybeMutable = false
        } else {
            self.sourceObject = nil
            self.source = nil
            self.count = 0
            self.maybeMutable = false
        }
        (lastHash1, lastHash2, lastHash3) = chitch_multihash_raw(self.source, self.count)
    }
    
    public init(hashOnly: String) {
        self.sourceObject = nil
        self.source = nil
        self.maybeMutable = false
        
        var tempHash1: Int = 0
        var tempHash2: Int = 0
        var tempHash3: Int = 0
        var tempCount: Int = 0
        chitch_using(hashOnly) { bytes, count in
            tempCount = count
            (tempHash1, tempHash2, tempHash3) = chitch_multihash_raw(bytes, count)
        }
        self.lastHash1 = tempHash1
        self.lastHash2 = tempHash2
        self.lastHash3 = tempHash3
        self.count = tempCount
    }
    
    public init(hashOnly: StaticString) {
        self.sourceObject = nil
        self.source = nil
        self.maybeMutable = false
        
        (lastHash1, lastHash2, lastHash3) = chitch_multihash_raw(hashOnly.utf8Start, hashOnly.utf8CodeUnitCount)
        self.count = hashOnly.utf8CodeUnitCount
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        
        let source = Hitch(string: string)
        if let raw = source.mutableRaw() {
            self.sourceObject = source
            self.source = UnsafePointer(raw)
            self.count = source.count
            self.maybeMutable = true
        } else if let raw = source.raw() {
            self.sourceObject = source
            self.source = raw
            self.count = source.count
            self.maybeMutable = false
        } else {
            self.sourceObject = nil
            self.source = nil
            self.count = 0
            self.maybeMutable = false
        }
        (lastHash1, lastHash2, lastHash3) = chitch_multihash_raw(self.source, self.count)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }

    @inlinable @inline(__always)
    public func hitch() -> Hitch {
        if let raw = source {
            return Hitch(bytes: raw, offset: 0, count: count)
        }
        return Hitch()
    }

    @inlinable @inline(__always)
    public func raw() -> UnsafePointer<UInt8>? {
        return source
    }

    @inlinable @inline(__always)
    public func mutableRaw() -> UnsafeMutablePointer<UInt8>? {
        return nil
    }

    @inlinable @inline(__always)
    public func hash(into hasher: inout Hasher) {
        hasher.combine(lastHash1)
        hasher.combine(lastHash2)
        hasher.combine(lastHash3)
    }
    
    public var hashValue: Int {
        return lastHash1 ^ lastHash2 ^ lastHash3
    }

    @inlinable @inline(__always)
    @discardableResult
    public mutating func unicodeUnescape() -> HalfHitch {
        guard maybeMutable else {
            #if DEBUG
            fatalError("unescape() called on HalfHitch pointing at immutable data")
            #else
            print("warning: unescape() called on HalfHitch pointing at immutable data")
            return self
            #endif
        }
        guard let raw = raw() else { return self }
        count = unescapeBinary(unicode: UnsafeMutablePointer(mutating: raw),
                               count: count)
        return self
    }

    @inlinable @inline(__always)
    @discardableResult
    public func unicodeUnescaped() -> HalfHitch {
        // returns self if there was nothing to unescape, or silo'd halfhitch if there was
        guard let raw = raw() else { return self }

        var local: UInt8 = .backSlash
        guard chitch_contains_raw(raw, count, &local, 1) == true else { return self }

        return hitch().unicodeUnescape().halfhitch()
    }

    @inlinable @inline(__always)
    func escaped(unicode: Bool,
                 singleQuotes: Bool) -> Hitch {
        guard let raw = raw() else { return Hitch() }
        return escapeBinary(unicode: UnsafeMutablePointer(mutating: raw),
                            count: count,
                            unicode: unicode,
                            singleQuotes: singleQuotes)
    }
    
    @inlinable @inline(__always)
    @discardableResult
    public mutating func percentUnescape() -> HalfHitch {
        guard maybeMutable else {
            #if DEBUG
            fatalError("unescape() called on HalfHitch pointing at immutable data")
            #else
            print("warning: unescape() called on HalfHitch pointing at immutable data")
            return self
            #endif
        }
        guard let raw = raw() else { return self }
        count = unescapeBinary(percent: UnsafeMutablePointer(mutating: raw),
                               count: count)
        return self
    }

    @inlinable @inline(__always)
    @discardableResult
    public func percentUnescaped() -> HalfHitch {
        // returns self if there was nothing to unescape, or silo'd halfhitch if there was
        guard let raw = raw() else { return self }

        var local: UInt8 = .percentSign
        guard chitch_contains_raw(raw, count, &local, 1) == true else { return self }

        return hitch().percentUnescape().halfhitch()
    }
    
    @inlinable @inline(__always)
    @discardableResult
    public mutating func ampersandUnescape() -> HalfHitch {
        guard maybeMutable else {
            #if DEBUG
            fatalError("unescape() called on HalfHitch pointing at immutable data")
            #else
            print("warning: unescape() called on HalfHitch pointing at immutable data")
            return self
            #endif
        }
        guard let raw = raw() else { return self }
        count = unescapeBinary(ampersand: UnsafeMutablePointer(mutating: raw),
                               count: count)
        return self
    }

    @inlinable @inline(__always)
    @discardableResult
    public func ampersandUnescaped() -> HalfHitch {
        // returns self if there was nothing to unescape, or silo'd halfhitch if there was
        guard let raw = raw() else { return self }

        var local: UInt8 = .ampersand
        guard chitch_contains_raw(raw, count, &local, 1) == true else { return self }

        return hitch().ampersandUnescape().halfhitch()
    }
    
    @inlinable @inline(__always)
    @discardableResult
    public mutating func mimeUnescape() -> HalfHitch {
        guard maybeMutable else {
            #if DEBUG
            fatalError("unescape() called on HalfHitch pointing at immutable data")
            #else
            print("warning: unescape() called on HalfHitch pointing at immutable data")
            return self
            #endif
        }
        guard let raw = raw() else { return self }
        count = unescapeBinary(mime: UnsafeMutablePointer(mutating: raw),
                               count: count)
        return self
    }

    @inlinable @inline(__always)
    @discardableResult
    public func mimeUnescaped() -> HalfHitch {
        // returns self if there was nothing to unescape, or silo'd halfhitch if there was
        guard let raw = raw() else { return self }

        var local: UInt8 = .equal
        guard chitch_contains_raw(raw, count, &local, 1) == true else { return self }

        return hitch().mimeUnescape().halfhitch()
    }

    @inlinable @inline(__always)
    public func components(separatedBy separator: HalfHitch) -> [HalfHitch] {
        guard let raw = raw() else { return [] }
        guard let separatorRaw = separator.raw() else { return [] }
        let rawCount = count
        let separatorCount = separator.count

        var components = [HalfHitch]()
        var currentIdx = 0

        while true {
            let nextIdx = chitch_firstof_raw_offset(raw, currentIdx, rawCount, separatorRaw, separatorCount)
            if nextIdx < 0 {
                break
            }

            if currentIdx != nextIdx {
                components.append(
                    HalfHitch(sourceObject: sourceObject, raw: raw, count: rawCount, from: currentIdx, to: nextIdx)
                )
            }
            currentIdx = nextIdx + separatorCount
        }

        if currentIdx != rawCount {
            components.append(
                HalfHitch(sourceObject: sourceObject, raw: raw, count: rawCount, from: currentIdx, to: rawCount)
            )
        }

        return components
    }

    @inlinable @inline(__always)
    public func components(separatedBy separator: HalfHitch) -> [Hitch] {
        let hhcomponents: [HalfHitch] = components(separatedBy: separator)
        return hhcomponents.map { $0.hitch() }
    }
    
    @inlinable @inline(__always)
    public func trimmed() -> HalfHitch {
        guard let start = raw() else { return self }
        let end = start + count
        var ptr = start
        
        var trimmedStart = start
        var trimmedEnd = end
        
        // advance the start past all whitespace
        while ptr < end {
            trimmedStart = ptr
            if isWhitespace(ptr.pointee) == false {
                break
            }
            ptr += 1
        }
        
        // advance the start past all whitespace
        ptr = end - 1
        while ptr >= start {
            if isWhitespace(ptr.pointee) == false {
                break
            }
            trimmedEnd = ptr
            ptr -= 1
        }
        
        if trimmedEnd < trimmedStart {
            trimmedEnd = trimmedStart
        }
        
        return HalfHitch(source: self, from: trimmedStart - start, to: trimmedEnd - start)
    }
}
