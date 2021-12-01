import Foundation

public extension ArraySlice where Element == UInt8 {

    @discardableResult
    @inline(__always)
    func toInt(_ fuzzy: Bool = true) -> Int? {
        var value = 0
        var isNegative = false
        for char in self {
            if char == .minus && value == 0 {
                isNegative = true
            } else if char >= .zero && char <= .nine {
                value = (value * 10) &+ Int(char - .zero)
            } else if fuzzy == false {
                return nil
            }
        }
        if isNegative {
            value = -1 * value
        }
        return value
    }
}
