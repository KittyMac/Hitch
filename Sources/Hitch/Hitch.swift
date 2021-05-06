import Foundation
import bstrlib

let nullptr = UnsafeMutablePointer<UInt8>(bitPattern: 0)!

public extension String {
    func hitch() -> Hitch {
        return Hitch(stringLiteral: self)
    }
}

public struct HitchIterator: IteratorProtocol {
    private var index = 0
    private var max = 0
    private let storage: UnsafeMutablePointer<UInt8>

    init(hitch: Hitch) {
        max = hitch.count
        storage = hitch.bstr?.pointee.data ?? nullptr
    }

    public mutating func next() -> UInt8? {
        guard index < max else { return nil }
        let value = storage[index]
        index += 1
        return value
    }
}

public final class Hitch: CustomStringConvertible, ExpressibleByStringLiteral, Sequence, Equatable {
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

    fileprivate var bstr: bstring?
    private var iterIndex: Int32 = 0

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

    public var count: Int {
        return Int(bstr?.pointee.slen ?? 0)
    }

    @discardableResult
    @inline(__always)
    public func reserveCapacity(_ newCapacity: Int) -> Self {
        balloc(bstr, Int32(newCapacity))
        return self
    }

    @discardableResult
    @inline(__always)
    public func lowercase() -> Self {
        btolower(bstr)
        return self
    }

    @discardableResult
    @inline(__always)
    public func uppercase() -> Self {
        btoupper(bstr)
        return self
    }

    @discardableResult
    @inline(__always)
    public func append(_ character: CChar) -> Self {
        bconchar(bstr, character)
        return self
    }

    @discardableResult
    @inline(__always)
    public func append(_ hitch: Hitch) -> Self {
        bconcat(bstr, hitch.bstr)
        return self
    }

    @discardableResult
    @inline(__always)
    public func append(_ string: String) -> Self {
        let hitch = string.hitch()
        bconcat(bstr, hitch.bstr)
        return self
    }

    @discardableResult
    @inline(__always)
    public func contains(_ hitch: Hitch) -> Bool {
        return binstr(bstr, 0, hitch.bstr) != BSTR_ERR
    }

    @discardableResult
    @inline(__always)
    public func contains(_ string: String) -> Bool {
        let hitch = string.hitch()
        return binstr(bstr, 0, hitch.bstr) != BSTR_ERR
    }
}
