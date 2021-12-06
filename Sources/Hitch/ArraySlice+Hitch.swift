import Foundation

public extension ArraySlice where Element == UInt8 {

    @discardableResult
    @inline(__always)
    func toInt() -> Int? {
        return self.withUnsafeBytes { ptr in
            return intFromBinary(data: ptr,
                                 count: count)
        }
    }

    @discardableResult
    @inline(__always)
    func toDouble() -> Double? {
        return self.withUnsafeBytes { ptr in
            return doubleFromBinary(data: ptr,
                                    count: count)
        }
    }
}
