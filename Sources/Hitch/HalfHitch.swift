// swiftlint:disable type_body_length

import Foundation
import bstrlib

public struct HalfHitchIterator: Sequence, IteratorProtocol {
    @usableFromInline
    internal var ptr: UnsafeMutablePointer<UInt8>
    @usableFromInline
    internal let end: UnsafeMutablePointer<UInt8>

    @inlinable @inline(__always)
    internal init(halfHitch: HalfHitch) {
        if let data = halfHitch.raw() {
            ptr = data - 1
            end = data + halfHitch.count - 1
        } else {
            ptr = nullptr
            end = ptr
        }
    }

    @inlinable @inline(__always)
    internal init(halfHitch: HalfHitch, from: Int, to: Int) {
        if let data = halfHitch.raw() {
            ptr = data + from - 1
            end = data + to - 1
        } else {
            ptr = nullptr
            end = ptr
        }
    }

    @inlinable @inline(__always)
    public mutating func next() -> UInt8? {
        if ptr >= end { return nil }
        ptr += 1
        return ptr.pointee
    }
}

/// HalfHitch is a Hitch-like view on raw data.  In other words, when you need to do string-like, read-only
/// processing on existing data without copies or allocations, then HalfHitch is your answer.
/// Note: as you can gather from the above, use HalfHitch carefully!
public struct HalfHitch: CustomStringConvertible, ExpressibleByStringLiteral, Sequence, Comparable, Hashable {

    public static let empty = HalfHitch()

    public var description: String {
        guard let source = source else { return "" }
        return String(bytesNoCopy: source, length: count, encoding: .utf8, freeWhenDone: false) ?? ""
    }

    @inlinable @inline(__always)
    public func toString() -> String {
        guard let source = source else { return "" }
        return String(data: Data(bytesNoCopy: source, count: count, deallocator: .none), encoding: .utf8) ?? ""
    }

    @usableFromInline
    let sourceHitch: Hitch

    @usableFromInline
    let source: UnsafeMutablePointer<UInt8>?

    public let count: Int

    @inlinable @inline(__always)
    public static func using<T>(data: Data, from: Int = 0, to: Int = -1, _ callback: (HalfHitch) -> T?) -> T? {
        var data2 = data
        return data2.withUnsafeMutableBytes { unsafeRawBufferPointer in
            let unsafeBufferPointer = unsafeRawBufferPointer.bindMemory(to: UInt8.self)
            guard let bytes = unsafeBufferPointer.baseAddress else { return nil }
            return callback(HalfHitch(raw: bytes,
                                      count: data.count,
                                      from: from,
                                      to: to >= 0 ? to : data.count))
        }
    }

    @inlinable @inline(__always)
    init(raw: UnsafeMutablePointer<UInt8>, count: Int, from: Int, to: Int) {
        self.sourceHitch = Hitch.empty
        self.source = raw + from
        self.count = to - from
    }

    @inlinable @inline(__always)
    public init(source: Hitch, from: Int, to: Int) {
        if let raw = source.raw() {
            self.sourceHitch = source
            self.source = raw + from
            self.count = to - from
        } else {
            self.sourceHitch = Hitch.empty
            self.source = nil
            self.count = 0
        }
    }

    @inlinable @inline(__always)
    public init(source: HalfHitch, from: Int, to: Int) {
        if let raw = source.source {
            self.sourceHitch = Hitch.empty
            self.source = raw + from
            self.count = to - from
        } else {
            self.sourceHitch = Hitch.empty
            self.source = nil
            self.count = 0
        }
    }

    @inlinable @inline(__always)
    public init() {
        self.sourceHitch = Hitch.empty
        self.source = nil
        self.count = 0
    }

    @inlinable @inline(__always)
    public init(stringLiteral: String) {
        self.sourceHitch = stringLiteral.hitch()
        if let raw = self.sourceHitch.raw() {
            self.source = raw
            self.count = self.sourceHitch.count
        } else {
            self.source = nil
            self.count = 0
        }
    }

    @inlinable @inline(__always)
    public func hitch() -> Hitch {
        if let raw = source {
            return Hitch(bytes: raw, offset: 0, count: count)
        }
        return Hitch()
    }

    @inlinable @inline(__always)
    public func hash(into hasher: inout Hasher) {
        hasher.combine(count)
        hasher.combine(bytes: UnsafeRawBufferPointer(start: source, count: Swift.min(count, 8)))
    }

    @usableFromInline
    internal var tagbstr: tagbstring {
        guard let raw = source else {
            return tagbstring(mlen: 0, slen: 0, data: nil)
        }
        let len = Int32(count)
        return tagbstring(mlen: len, slen: len, data: raw)
    }

    public static func < (lhs: HalfHitch, rhs: HalfHitch) -> Bool {
        var lhs = lhs.tagbstr
        var rhs = rhs.tagbstr
        return bstrcmp(&lhs, &rhs) < 0
    }

    public static func < (lhs: String, rhs: HalfHitch) -> Bool {
        let hitch = lhs.hitch()
        var rhs = rhs.tagbstr
        return bstrcmp(hitch.bstr, &rhs) < 0
    }

    public static func < (lhs: HalfHitch, rhs: String) -> Bool {
        let hitch = rhs.hitch()
        var lhs = lhs.tagbstr
        return bstrcmp(&lhs, hitch.bstr) < 0
    }

    public static func == (lhs: HalfHitch, rhs: HalfHitch) -> Bool {
        var lhsBstr = lhs.tagbstr
        var rhsBstr = rhs.tagbstr
        return biseq(&lhsBstr, &rhsBstr) == 1
    }

    public static func == (lhs: String, rhs: HalfHitch) -> Bool {
        let hitch = lhs.hitch()
        var rhs = rhs.tagbstr
        return biseq(hitch.bstr, &rhs) == 1
    }

    public static func == (lhs: HalfHitch, rhs: String) -> Bool {
        let hitch = rhs.hitch()
        var lhs = lhs.tagbstr
        return biseq(&lhs, hitch.bstr) == 1
    }

    public static func == (lhs: Hitch, rhs: HalfHitch) -> Bool {
        var rhs = rhs.tagbstr
        return biseq(lhs.bstr, &rhs) == 1
    }

    public static func == (lhs: HalfHitch, rhs: Hitch) -> Bool {
        var lhs = lhs.tagbstr
        return biseq(&lhs, rhs.bstr) == 1
    }

    @inlinable @inline(__always)
    public func makeIterator() -> HalfHitchIterator {
        return HalfHitchIterator(halfHitch: self)
    }

    @inlinable @inline(__always)
    public func stride(from: Int, to: Int) -> HalfHitchIterator {
        return HalfHitchIterator(halfHitch: self, from: from, to: to)
    }

    @inlinable @inline(__always)
    public func raw() -> UnsafeMutablePointer<UInt8>? {
        return source
    }

    @inlinable @inline(__always)
    public subscript (index: Int) -> UInt8 {
        get {
            guard index >= 0 && index < count else { return 0 }
            return source?[index] ?? 0
        }
    }

    @inlinable @inline(__always)
    public func canEscape(escapeSingleQuote: Bool) -> Bool {
        if escapeSingleQuote {
            for char in self where char > 0x7f ||
                char == .bell ||
                char == .newLine ||
                char == .tab ||
                char == .formFeed ||
                char == .carriageReturn ||
                char == .singleQuote ||
                char == .doubleQuote ||
                char == .backSlash ||
                char == .forwardSlash {
                return true
            }
        } else {
            for char in self where char > 0x7f ||
                char == .bell ||
                char == .newLine ||
                char == .tab ||
                char == .formFeed ||
                char == .carriageReturn ||
                char == .doubleQuote ||
                char == .backSlash ||
                char == .forwardSlash {
                return true
            }
        }
        return false
    }

    @inlinable @inline(__always)
    public func canUnescape() -> Bool {
        for char in self where char == .backSlash {
            return true
        }
        return false
    }

    @inlinable @inline(__always)
    public func escaped(escapeSingleQuote: Bool = false) -> HalfHitch {
        guard canEscape(escapeSingleQuote: escapeSingleQuote) else { return self }
        let clone = hitch()
        clone.escape(escapeSingleQuote: escapeSingleQuote)
        return clone.halfhitch()
    }

    @inlinable @inline(__always)
    public func unescaped() -> HalfHitch {
        guard canUnescape() else { return self }
        let clone = hitch()
        clone.unescape()
        return clone.halfhitch()
    }

    @inlinable @inline(__always)
    @discardableResult
    public func toInt(fuzzy: Bool = false) -> Int? {
        guard let raw = source else { return nil }
        if fuzzy {
            return intFromBinaryFuzzy(data: UnsafeRawBufferPointer(start: raw, count: count),
                                      count: count)
        }
        return intFromBinary(data: UnsafeRawBufferPointer(start: raw, count: count),
                             count: count)
    }

    @inlinable @inline(__always)
    @discardableResult
    public func toDouble(fuzzy: Bool = false) -> Double? {
        guard let raw = source else { return nil }
        if fuzzy {
            return doubleFromBinaryFuzzy(data: UnsafeRawBufferPointer(start: raw, count: count),
                                         count: count)
        }
        return doubleFromBinary(data: UnsafeRawBufferPointer(start: raw, count: count),
                                count: count)
    }
}
