import Foundation

public extension ArraySlice where Element == UInt8 {

    @discardableResult
    @inline(__always)
    func toInt(_ fuzzy: Bool = true) -> Int? {
        var value = 0
        for char in self {
            if char >= 48 && char <= 57 {
                value = (value * 10) &+ Int(char - 48)
            } else if fuzzy == false {
                return nil
            }
        }
        return value
    }
}
