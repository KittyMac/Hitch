import Foundation

infix operator <<<: AdditionPrecedence

public protocol HitchFormattable {
    associatedtype HitchType

    @inlinable @inline(__always)
    func formatToHalfHitch(using values: [Any?]) -> HalfHitch

    @inlinable @inline(__always)
    func formatToHitch(using values: [Any?]) -> Hitch
}

extension String: HitchFormattable {
    public typealias HitchType = String
    @inlinable @inline(__always)
    public func formatToHalfHitch(using values: [Any?]) -> HalfHitch {
        return formatToHitch(using: values).halfhitch()
    }
    @inlinable @inline(__always)
    public func formatToHitch(using values: [Any?]) -> Hitch {
        return Hitch(HalfHitch(string: self), values: values)
    }
}

extension StaticString: HitchFormattable {
    public typealias HitchType = StaticString
    @inlinable @inline(__always)
    public func formatToHalfHitch(using values: [Any?]) -> HalfHitch {
        return formatToHitch(using: values).halfhitch()
    }
    @inlinable @inline(__always)
    public func formatToHitch(using values: [Any?]) -> Hitch {
        return Hitch(HalfHitch(stringLiteral: self), values: values)
    }
}

extension Hitch: HitchFormattable {
    public typealias HitchType = Hitch
    @inlinable @inline(__always)
    public func formatToHalfHitch(using values: [Any?]) -> HalfHitch {
        return formatToHitch(using: values).halfhitch()
    }
    @inlinable @inline(__always)
    public func formatToHitch(using values: [Any?]) -> Hitch {
        return Hitch(halfhitch(), values: values)
    }
}

extension HalfHitch: HitchFormattable {
    public typealias HitchType = HalfHitch
    @inlinable @inline(__always)
    public func formatToHalfHitch(using values: [Any?]) -> HalfHitch {
        return Hitch(self, values: values).halfhitch()
    }
    @inlinable @inline(__always)
    public func formatToHitch(using values: [Any?]) -> Hitch {
        return Hitch(self, values: values)
    }
}

@inlinable @inline(__always)
public func <<<T: HitchFormattable> (left: T, right: [Any?]) -> HalfHitch {
    return left.formatToHalfHitch(using: right)
}

@inlinable @inline(__always)
public func <<<<T: HitchFormattable> (left: T, right: [Any?]) -> Hitch {
    return left.formatToHitch(using: right)
}
