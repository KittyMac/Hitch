// swiftlint:disable type_body_length

import Foundation

/// HalfHitch is a Hitch-like view on raw data.  In other words, when you need to do string-like
/// processing on existing data without copies or allocations, then HalfHitch is your answer.
/// Note: as you can gather from the above, use HalfHitch carefully!
public struct HalfHitch: Hitchable, CustomStringConvertible, ExpressibleByStringLiteral, Sequence, Comparable, Hashable {

    public static let empty = HalfHitch()

    @usableFromInline
    let sourceObject: AnyObject?

    @usableFromInline
    let source: UnsafeMutablePointer<UInt8>?

    public var count: Int

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
    public init(raw: UnsafeMutablePointer<UInt8>, count: Int, from: Int, to: Int) {
        self.sourceObject = nil
        self.source = raw + from
        self.count = to - from
    }

    @inlinable @inline(__always)
    public init(raw: UnsafeMutableRawPointer, count: Int, from: Int, to: Int) {
        let tempRaw = raw.bindMemory(to: UInt8.self, capacity: count)
        self.sourceObject = nil
        self.source = tempRaw + from
        self.count = to - from
    }

    @inlinable @inline(__always)
    public init(source: Hitch, from: Int, to: Int) {
        if let raw = source.raw() {
            self.sourceObject = source
            self.source = raw + from
            self.count = to - from
        } else {
            self.sourceObject = nil
            self.source = nil
            self.count = 0
        }
    }

    @inlinable @inline(__always)
    public init(source: HalfHitch, from: Int, to: Int) {
        self.sourceObject = nil
        if let raw = source.source {
            self.source = raw + from
            self.count = to - from
        } else {
            self.source = nil
            self.count = 0
        }
    }

    @inlinable @inline(__always)
    public init() {
        self.sourceObject = nil
        self.source = nil
        self.count = 0
    }

    @inlinable @inline(__always)
    public init(stringLiteral: String) {
        let source = stringLiteral.hitch()
        if let raw = source.raw() {
            self.sourceObject = source
            self.source = raw
            self.count = source.count
        } else {
            self.sourceObject = nil
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
    public func raw() -> UnsafeMutablePointer<UInt8>? {
        return source
    }

    @inlinable @inline(__always)
    @discardableResult
    public mutating func unescape() -> Self {
        guard let raw = raw() else { return self }
        count = unescapeBinary(data: raw,
                               count: count)
        return self
    }
}
