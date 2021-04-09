import Foundation
import bstrlib

public extension String {
    func hitch() -> Hitch {
        return Hitch(stringLiteral: self)
    }
}

/*
public struct HitchIterator: Sequence, IteratorProtocol {
    var startPtr: UnsafeMutablePointer<CChar>
    var endPtr: UnsafeMutablePointer<CChar>

    public init(hitch: Hitch) {
        startPtr = hitch.storage
        endPtr = hitch.storage + hitch.size
    }

    @inline(__always)
    public mutating func next() -> CChar? {
        defer { startPtr += 1 }
        return startPtr < endPtr ? startPtr.pointee : nil
    }
}
 */

public final class Hitch: CustomStringConvertible, ExpressibleByStringLiteral {
    fileprivate var bstr: bstring?

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
        bconcat(bstr, string.hitch().bstr)
        return self
    }
}
