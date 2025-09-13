import Foundation

infix operator <<~: AdditionPrecedence
infix operator <<<: AdditionPrecedence

public protocol HitchFormattable {

    func formatToHalfHitch(using values: [Any?]) -> HalfHitch


    func formatToHitch(using values: [Any?]) -> Hitch
}

extension String: HitchFormattable {

    public func formatToHalfHitch(using values: [Any?]) -> HalfHitch {
        return formatToHitch(using: values).halfhitch()
    }

    public func formatToHitch(using values: [Any?]) -> Hitch {
        return Hitch(HalfHitch(string: self), values: values)
    }
}

extension StaticString: HitchFormattable {

    public func formatToHalfHitch(using values: [Any?]) -> HalfHitch {
        return formatToHitch(using: values).halfhitch()
    }

    public func formatToHitch(using values: [Any?]) -> Hitch {
        return Hitch(HalfHitch(stringLiteral: self), values: values)
    }
}

extension Hitch: HitchFormattable {

    public func formatToHalfHitch(using values: [Any?]) -> HalfHitch {
        return formatToHitch(using: values).halfhitch()
    }

    public func formatToHitch(using values: [Any?]) -> Hitch {
        return Hitch(halfhitch(), values: values)
    }
}

extension HalfHitch: HitchFormattable {

    public func formatToHalfHitch(using values: [Any?]) -> HalfHitch {
        return Hitch(self, values: values).halfhitch()
    }

    public func formatToHitch(using values: [Any?]) -> Hitch {
        return Hitch(self, values: values)
    }
}


public func << (left: HitchFormattable, right: [Any?]) -> HalfHitch {
    return left.formatToHalfHitch(using: right)
}


public func <<< (left: HitchFormattable, right: [Any?]) -> Hitch {
    return left.formatToHitch(using: right)
}


public func <<~ (left: HitchFormattable, right: [Any?]) -> String {
    return left.formatToHalfHitch(using: right).toString()
}
