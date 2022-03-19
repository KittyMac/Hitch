import Foundation

infix operator <<~: AdditionPrecedence
infix operator <<<: AdditionPrecedence

public protocol HitchFormattable {
    @inlinable @inline(__always)
    func formatToHalfHitch(using values: [Any?]) -> HalfHitch

    @inlinable @inline(__always)
    func formatToHitch(using values: [Any?]) -> Hitch
}

extension String: HitchFormattable {
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
public func << (left: HitchFormattable, right: [Any?]) -> HalfHitch {
    return left.formatToHalfHitch(using: right)
}

@inlinable @inline(__always)
public func <<< (left: HitchFormattable, right: [Any?]) -> Hitch {
    return left.formatToHitch(using: right)
}

@inlinable @inline(__always)
public func <<~ (left: HitchFormattable, right: [Any?]) -> String {
    return left.formatToHalfHitch(using: right).toString()
}
