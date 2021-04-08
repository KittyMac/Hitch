import Foundation

public extension String {
    var hitch: Hitch {
        return Hitch(stringLiteral: self)
    }
}

public class Hitch: CustomStringConvertible, ExpressibleByStringLiteral {

    fileprivate var storage = UnsafeMutablePointer<CChar>.allocate(capacity: 1)
    fileprivate var capacity: Int = 1
    fileprivate var size: Int = 0

    public var count: Int {
        return size
    }

    public var description: String {
        return String(utf8String: storage) ?? "failed to convert to string"
    }

    required public init (stringLiteral: String) {
        let utf8 = stringLiteral.utf8
        reserveCapacity(utf8.count)
        size = utf8.count
        stringLiteral.withCString { (bytes: UnsafePointer<Int8>) -> Void in
            memcpy(storage, bytes, capacity)
        }
    }

    public init (capacity newCapacity: Int) {
        reserveCapacity(newCapacity)
        storage.initialize(to: 0)
    }

    @inline(__always)
    public func reserveCapacity(_ newCapacity: Int,
                                process: (() -> Void)? = nil) {
        if capacity >= newCapacity {
            if let process = process {
                process()
            }
        } else {
            capacity = newCapacity * 2
            let oldStorage = storage
            storage = UnsafeMutablePointer<CChar>.allocate(capacity: capacity + 1)
            storage.initialize(from: oldStorage, count: size)
            storage[capacity] = 0

            if let process = process {
                process()
            }

            oldStorage.deallocate()
        }
    }

    @inline(__always)
    public func append(_ character: CChar) {
        size += 1
        reserveCapacity(size)
        storage[size] = character
    }

    @inline(__always)
    public func append(_ hitch: Hitch) {
        reserveCapacity(size + hitch.size) {
            memcpy(self.storage + self.size, hitch.storage, hitch.size)
            self.size += hitch.size
        }
    }

    @inline(__always)
    public func append(_ string: String) {
        let utf8 = string.utf8
        let currentSize = size
        size += utf8.count
        reserveCapacity(size)
        string.withCString { (bytes: UnsafePointer<Int8>) -> Void in
            memcpy(storage + currentSize, bytes, utf8.count)
        }
    }

    @inline(__always)
    public func lowercase() {
        var ptr: UnsafeMutablePointer<CChar> = storage
        while ptr.pointee != 0 {
            if ptr.pointee >= 0x41 && ptr.pointee <= 0x5a {
                ptr.pointee -= 0x20
            }
            ptr += 1
        }
    }

    @inline(__always)
    public func uppercase() {
        var ptr: UnsafeMutablePointer<CChar> = storage
        while ptr.pointee != 0 {
            if ptr.pointee >= 0x41 && ptr.pointee <= 0x5a {
                ptr.pointee += 0x20
            }
            ptr += 1
        }
    }
}
