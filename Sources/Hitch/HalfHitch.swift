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
public struct HalfHitch: CustomStringConvertible, Comparable, Hashable {

    public var description: String {
        guard let source = source else { return "null" }
        return String(data: Data(bytesNoCopy: source + from, count: to - from, deallocator: .none), encoding: .utf8) ?? "null"
    }

    @usableFromInline
    let source: UnsafeMutablePointer<UInt8>?

    public let count: Int

    @usableFromInline
    var from: Int
    @usableFromInline
    var to: Int

    @inlinable @inline(__always)
    public static func using(data: Data, from: Int = 0, to: Int = 0, _ callback: (HalfHitch) -> Void) {
        var data2 = data
        data2.withUnsafeMutableBytes { unsafeRawBufferPointer in
            let unsafeBufferPointer = unsafeRawBufferPointer.bindMemory(to: UInt8.self)
            guard let bytes = unsafeBufferPointer.baseAddress else { return }
            callback(HalfHitch(raw: bytes,
                               count: data.count,
                               from: from,
                               to: to))
        }
    }

    @inlinable @inline(__always)
    init(raw: UnsafeMutablePointer<UInt8>, count: Int, from: Int, to: Int) {
        self.source = raw
        self.count = count
        self.from = from
        self.to = to
    }

    @inlinable @inline(__always)
    public init(source: Hitch, from: Int, to: Int) {
        self.source = source.raw()
        self.count = source.count
        self.from = from
        self.to = to
    }

    @inlinable @inline(__always)
    public init(source: HalfHitch, from: Int, to: Int) {
        self.source = source.source
        self.count = source.count
        self.from = from
        self.to = to
    }

    @inlinable @inline(__always)
    public init() {
        self.source = nil
        self.count = 0
        self.from = 0
        self.to = 0
    }

    @usableFromInline
    internal var tagbstr: tagbstring {
        guard let raw = source else { return tagbstring(mlen: 0, slen: 0, data: nil) }
        let mlen = Int32(count - from)
        let slen = Int32(to - from)
        return tagbstring(mlen: mlen, slen: slen, data: raw + from)
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
        var lhs = lhs.tagbstr
        var rhs = rhs.tagbstr
        return biseq(&lhs, &rhs) == 1
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
            guard index > 0 && index < count else { return 0 }
            return source?[index] ?? 0
        }
    }

    @inlinable @inline(__always)
    @discardableResult
    public func toInt(fuzzy: Bool = false) -> Int? {
        guard let raw = source else { return nil }
        let count = to - from
        if fuzzy {
            return intFromBinaryFuzzy(data: UnsafeRawBufferPointer(start: raw + from, count: count),
                                      count: count)
        }
        return intFromBinary(data: UnsafeRawBufferPointer(start: raw + from, count: count),
                             count: count)
    }

    @inlinable @inline(__always)
    @discardableResult
    public func toDouble(fuzzy: Bool = false) -> Double? {
        guard let raw = source else { return nil }
        let count = to - from
        if fuzzy {
            return doubleFromBinaryFuzzy(data: UnsafeRawBufferPointer(start: raw + from, count: count),
                                         count: count)
        }
        return doubleFromBinary(data: UnsafeRawBufferPointer(start: raw + from, count: count),
                                count: count)
    }
}
