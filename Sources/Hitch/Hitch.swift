// swiftlint:disable type_body_length

import Foundation
import bstrlib

public let nullptr = UnsafeMutablePointer<UInt8>(bitPattern: 0)!

public extension String {
    func hitch() -> Hitch {
        return Hitch(stringLiteral: self)
    }
}

public struct HitchIterator: IteratorProtocol {
    @usableFromInline
    internal var ptr: UnsafeMutablePointer<UInt8>
    @usableFromInline
    internal let end: UnsafeMutablePointer<UInt8>

    @inlinable @inline(__always)
    internal init(hitch: Hitch) {
        if let data = hitch.raw() {
            ptr = data - 1
            end = data + hitch.count - 1
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

public final class Hitch: CustomStringConvertible, ExpressibleByStringLiteral, Sequence, Equatable, Codable, Hashable {
    public static func == (lhs: Hitch, rhs: Hitch) -> Bool {
        if lhs === rhs {
            return true
        }
        return biseq(lhs.bstr, rhs.bstr) == 1
    }

    public static func == (lhs: String, rhs: Hitch) -> Bool {
        let hitch = lhs.hitch()
        return biseq(hitch.bstr, rhs.bstr) == 1
    }

    public static func == (lhs: Hitch, rhs: String) -> Bool {
        let hitch = rhs.hitch()
        return biseq(lhs.bstr, hitch.bstr) == 1
    }

    public func withBytes(_ callback: (UnsafeMutablePointer<UInt8>) -> Void) {
        if let bstr = bstr,
            let data = bstr.pointee.data {
            callback(data)
        }
    }

    public func raw() -> UnsafeMutablePointer<UInt8>? {
        return bstr?.pointee.data
    }

    public subscript (index: Int) -> UInt8 {
        get {
            if let bstr = bstr,
                let data = bstr.pointee.data,
                index < bstr.pointee.slen {
                return data[index]
            }
            return 0
        }
        set(newValue) {
            if let bstr = bstr,
                let data = bstr.pointee.data,
                index < bstr.pointee.slen {
                data[index] = newValue
            }
        }
    }

    public func hash(into hasher: inout Hasher) {
        if let bstr = bstr,
            let data = bstr.pointee.data {
            hasher.combine(bytes: UnsafeRawBufferPointer(start: data, count: Int(bstr.pointee.slen)))
        } else {
            hasher.combine(0)
        }
    }

    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stringLiteral = try container.decode(String.self)
        self.init(stringLiteral: stringLiteral)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.description)
    }

    private var bstr: bstring?

    public var description: String {
        if let bstr = bstr,
            let data = bstr.pointee.data {
            return String(bytesNoCopy: data, length: Int(bstr.pointee.slen), encoding: .utf8, freeWhenDone: false) ?? ""
        }
        return ""
    }

    deinit {
        bdestroy(bstr)
    }

    public func makeIterator() -> HitchIterator {
       return HitchIterator(hitch: self)
    }

    required public init (stringLiteral: String) {
        stringLiteral.withCString { (bytes: UnsafePointer<Int8>) -> Void in
            self.bstr = bfromcstr(bytes)
        }
    }

    public init(hitch: Hitch) {
        if let other = hitch.bstr,
            let data = other.pointee.data {
            bstr = blk2bstr(data, Int32(other.pointee.slen))
        }
    }

    public init(data: Data) {
        data.withUnsafeBytes { bytes in
            bstr = blk2bstr(bytes, Int32(data.count))
        }
    }

    public func dataNoCopy() -> Data {
        if let bstr = bstr,
            let data = bstr.pointee.data {
            return Data(bytesNoCopy: data, count: Int(bstr.pointee.slen), deallocator: .none)
        }
        return Data()
    }

    public func dataCopy() -> Data {
        if let bstr = bstr,
            let data = bstr.pointee.data {
            return Data(bytes: data, count: Int(bstr.pointee.slen))
        }
        return Data()
    }

    public func dataNoCopy(start inStart: Int = -1,
                           end inEnd: Int = -1) -> Data {
        if let bstr = bstr,
            let data = bstr.pointee.data {

            let max = Int(bstr.pointee.slen)
            var start = inStart
            var end = inEnd

            if start < 0 || start > max {
                start = 0
            }
            if end < 0 || start > max {
                end = max
            }
            if start > end {
                end = start
            }

            return Data(bytesNoCopy: data + start, count: end - start, deallocator: .none)
        }
        return Data()
    }

    public func dataCopy(start inStart: Int,
                         end inEnd: Int) -> Data {
        if let bstr = bstr,
            let data = bstr.pointee.data {

            let max = Int(bstr.pointee.slen)
            var start = inStart
            var end = inEnd

            if start < 0 || start > max {
                start = 0
            }
            if end < 0 || start > max {
                end = max
            }
            if start > end {
                end = start
            }

            return Data(bytes: data + start, count: end - start)
        }
        return Data()
    }

    public init(capacity: Int) {
        bstr = bempty()
        reserveCapacity(capacity)
    }

    public init() {
        bstr = bempty()
    }

    // @usableFromInline
    internal init(bstr: bstring) {
        self.bstr = bstr
    }

    public var count: Int {
        get {
            return Int(bstr?.pointee.slen ?? 0)
        }
        set {
            btrunc(bstr, Int32(newValue))
        }
    }

    public func clear() {
        bdestroy(bstr)
        bstr = bempty()
    }

    public func replace(with string: String) {
        bdestroy(bstr)
        string.withCString { (bytes: UnsafePointer<Int8>) -> Void in
            self.bstr = bfromcstr(bytes)
        }
    }

    @discardableResult
    public func reserveCapacity(_ newCapacity: Int) -> Self {
        balloc(bstr, Int32(newCapacity))
        return self
    }

    @discardableResult
    public func lowercase() -> Self {
        btolower(bstr)
        return self
    }

    @discardableResult
    public func uppercase() -> Self {
        btoupper(bstr)
        return self
    }

    @discardableResult
    public func append(_ hitch: Hitch) -> Self {
        bconcat(bstr, hitch.bstr)
        return self
    }

    @discardableResult
    public func append(_ string: String) -> Self {
        let hitch = string.hitch()
        bconcat(bstr, hitch.bstr)
        return self
    }

    @discardableResult
    public func append<T: FixedWidthInteger>(_ char: T) -> Self {
        bconchar(bstr, UInt8(clamping: char))
        return self
    }

    @discardableResult
    public func append<T: FixedWidthInteger>(number: T) -> Self {
        return insert(number: number, index: count)
    }

    @discardableResult
    public func append(_ data: Data) -> Self {
        data.withUnsafeBytes { bytes in
            bcatblk(bstr, bytes, Int32(data.count))
        }
        return self
    }

    @discardableResult
    public func insert(_ hitch: Hitch, index: Int) -> Self {
        let position = Swift.max(Swift.min(index, 0), count)
        binsert(bstr, Int32(position), hitch.bstr, 32)
        return self
    }

    @discardableResult
    public func insert(_ string: String, index: Int) -> Self {
        let hitch = string.hitch()
        let position = Swift.max(Swift.min(index, 0), count)
        binsert(bstr, Int32(position), hitch.bstr, 32)
        return self
    }

    @discardableResult
    public func insert<T: FixedWidthInteger>(_ char: T, index: Int) -> Self {
        let position = Swift.max(Swift.min(index, count), 0)
        binsertch(bstr, Int32(position), 1, UInt8(clamping: char))
        return self
    }

    @discardableResult
    public func insert<T: FixedWidthInteger>(number: T, index: Int) -> Self {
        let zero: UInt8 = 48
        let minus: UInt8 = 45
        if number == 0 {
            insert(zero, index: index)
        } else {
            let isNegative = number < 0

            var value = isNegative ? -1 * number : number
            while value > 0 {
                let digit = value % 10
                value /= 10
                insert(zero + UInt8(digit), index: index)
            }

            if isNegative {
                insert(minus, index: index)
            }
        }
        return self
    }

    @discardableResult
    public func insert(_ data: Data, index: Int) -> Self {
        let position = Swift.max(Swift.min(index, 0), count)
        data.withUnsafeBytes { bytes in
            binsertblk(bstr, Int32(position), bytes, Int32(data.count), 32)
        }
        return self
    }

    public func trim() {
        btrimws(bstr)
    }

    @discardableResult
    public func contains(_ hitch: Hitch) -> Bool {
        return binstr(bstr, 0, hitch.bstr) != BSTR_ERR
    }

    @discardableResult
    public func contains(_ string: String) -> Bool {
        let hitch = string.hitch()
        return binstr(bstr, 0, hitch.bstr) != BSTR_ERR
    }

    @discardableResult
    public func contains<T: FixedWidthInteger>(_ char: T) -> Bool {
        return bstrchrp(bstr, Int32(char), 0) != BSTR_ERR
    }

    @discardableResult
    public func firstIndex(of hitch: Hitch) -> Int? {
        let index = binstr(bstr, 0, hitch.bstr)
        return index != BSTR_ERR ? Int(index) : nil
    }

    @discardableResult
    public func firstIndex(of string: String) -> Int? {
        let hitch = string.hitch()
        let index = binstr(bstr, 0, hitch.bstr)
        return index != BSTR_ERR ? Int(index) : nil
    }

    @discardableResult
    public func firstIndex<T: FixedWidthInteger>(of char: T) -> Int? {
        let index = bstrchrp(bstr, Int32(char), 0)
        return index != BSTR_ERR ? Int(index) : nil
    }

    @discardableResult
    public func substring(_ lhsPos: Int, _ rhsPos: Int) -> Hitch? {
        guard lhsPos >= 0 && lhsPos <= count else { return nil }
        guard rhsPos >= 0 && rhsPos <= count else { return nil }
        guard lhsPos < rhsPos else { return nil }
        return Hitch(bstr: bmidstr(bstr, Int32(lhsPos), Int32(rhsPos - lhsPos)))
    }

    @discardableResult
    public func extract(_ lhs: Hitch, _ rhs: Hitch) -> Hitch? {
        guard let bstr = bstr else { return nil }
        var lhsPos = binstr(bstr, 0, lhs.bstr)
        guard lhsPos != BSTR_ERR else { return nil }

        lhsPos += Int32(lhs.count)
        let rhsPos = binstr(bstr, lhsPos, rhs.bstr)
        guard rhsPos != BSTR_ERR else { return Hitch(bstr: bmidstr(bstr, lhsPos, bstr.pointee.slen)) }
        return Hitch(bstr: bmidstr(bstr, lhsPos, (rhsPos - lhsPos)))
    }

    @discardableResult
    public func extract(_ lhs: String, _ rhs: String) -> Hitch? {
        return extract(lhs.hitch(), rhs.hitch())
    }

    @discardableResult
    public func extract(_ lhs: Hitch, _ rhs: String) -> Hitch? {
        return extract(lhs, rhs.hitch())
    }

    @discardableResult
    public func extract(_ lhs: String, _ rhs: Hitch) -> Hitch? {
        return extract(lhs.hitch(), rhs)
    }

    @discardableResult
    public func toInt(_ fuzzy: Bool = true) -> Int? {
        if let bstr = bstr,
            let data = bstr.pointee.data {
            var value = 0
            for idx in 0..<Int(bstr.pointee.slen) {
                let char = data[idx]
                if char >= 48 && char <= 57 {
                    value = (value * 10) &+ Int(char - 48)
                } else if fuzzy == false {
                    return nil
                }
            }
            return value
        }
        return nil
    }

    @discardableResult
    public func toEpoch() -> Int {
        return Int(btoepoch(bstr))
    }
}
