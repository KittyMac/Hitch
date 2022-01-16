import Foundation

@usableFromInline
let trueHitch = Hitch("true")
@usableFromInline
let falseHitch = Hitch("false")
@usableFromInline
let errorHitch = Hitch("error")
@usableFromInline
let nullHitch = Hitch("null")

@usableFromInline
let defaultPrecision = 15

extension Hitch {

    @usableFromInline
    enum ValueType {
        case null
        case int
        case double
        case hitch
    }

    @usableFromInline
    struct TypedValue {
        @usableFromInline
        let type: ValueType

        @usableFromInline
        let hitch: Hitch?
        @usableFromInline
        let int: Int?
        @usableFromInline
        let double: Double?

        @inlinable @inline(__always)
        init() {
            self.type = .null
            self.hitch = nil
            self.int = nil
            self.double = nil
        }

        @inlinable @inline(__always)
        init(int: Int) {
            self.type = .int
            self.hitch = nil
            self.int = int
            self.double = nil
        }

        @inlinable @inline(__always)
        init(double: Double) {
            self.type = .double
            self.hitch = nil
            self.int = nil
            self.double = double
        }

        @inlinable @inline(__always)
        init(hitch: Hitch) {
            self.type = .hitch
            self.hitch = hitch
            self.int = nil
            self.double = nil
        }
    }

    @usableFromInline
    enum Alignment {
        case left
        case center
        case right
    }

    @inlinable @inline(__always)
    internal func getTypedValue(_ value: Any?) -> TypedValue {
        // Note: this is a slow path
        switch value {
        case let value as Int: return(TypedValue(int: value))
        case let value as Double: return(TypedValue(double: value))
        case let value as Float: return(TypedValue(double: Double(value)))
        case let value as NSNumber: return(TypedValue(double: Double(value.doubleValue)))
        case let value as Bool: return value ? TypedValue(hitch: trueHitch) : TypedValue(hitch: falseHitch)
        case let value as Hitch: return(TypedValue(hitch: value))
        case let value as HalfHitch: return(TypedValue(hitch: value.hitch()))
        case let value as String: return(TypedValue(hitch: Hitch(stringLiteral: value)))
        case let value as CustomStringConvertible: return(TypedValue(hitch: Hitch(stringLiteral: value.description)))
        default: return(TypedValue())
        }
    }

    @inlinable @inline(__always)
    convenience init(_ format: Hitch, _ values: Any?...) {
        self.init()
        self.insert(format: format, index: count, values: values)
    }

    @inlinable @inline(__always)
    @discardableResult
    public func append(format: Hitch, _ values: Any?...) -> Self {
        return insert(format: format, index: count, values: values)
    }

    @inlinable @inline(__always)
    @discardableResult
    public func append(format: Hitch, values: [Any?]) -> Self {
        return insert(format: format, index: count, values: values)
    }

    @inlinable @inline(__always)
    @discardableResult
    public func insert(format: Hitch, index: Int, _ values: Any?...) -> Self {
        return insert(format: format, index: index, values: values)
    }

    @inlinable @inline(__always)
    @discardableResult
    public func insert(format: Hitch, index: Int, values: [Any?]) -> Self {

        let scratch = index == count ? self : Hitch(capacity: format.count)
        let valueScratch = Hitch(capacity: format.count)

        let appendUnboundedValue: (Int, Int) -> Void = { valueIdx, fieldPrecision in
            let value = self.getTypedValue(values[valueIdx])
            switch value.type {
            case .null: scratch.append(nullHitch)
            case .int: scratch.append(number: value.int ?? 0)
            case .double: scratch.append(double: value.double ?? 0.0, precision: fieldPrecision)
            case .hitch: scratch.append(value.hitch ?? Hitch.empty)
            }
        }

        let appendBoundedValue: (Int, Int, Int, Alignment) -> Void = { valueIdx, fieldPrecision, fieldWidth, fieldAlignment in
            var valueAsHitch = Hitch.empty

            let value = self.getTypedValue(values[valueIdx])
            switch value.type {
            case .null:
                valueAsHitch = nullHitch
            case .int:
                valueScratch.clear()
                valueScratch.append(number: value.int ?? 0)
                valueAsHitch = valueScratch
            case .double:
                valueScratch.clear()
                valueScratch.append(double: value.double ?? 0.0, precision: fieldPrecision)
                valueAsHitch = valueScratch
            case .hitch:
                valueAsHitch = value.hitch ?? Hitch.empty
            }

            let valueWidth = valueAsHitch.count

            let extra = fieldWidth - valueWidth
            if extra > 0 {
                switch fieldAlignment {
                case .left:
                    scratch.append(valueAsHitch)
                    for _ in 0..<extra {
                        scratch.append(.space)
                    }
                case .right:
                    for _ in 0..<extra {
                        scratch.append(.space)
                    }
                    scratch.append(valueAsHitch)
                case .center:
                    let leftPadding = extra / 2
                    let rightPadding = extra - leftPadding
                    for _ in 0..<leftPadding {
                        scratch.append(.space)
                    }
                    scratch.append(valueAsHitch)
                    for _ in 0..<rightPadding {
                        scratch.append(.space)
                    }
                }
            } else {
                scratch.append(valueAsHitch.substring(0, fieldWidth) ?? Hitch.empty)
            }
        }

        format.using { startFormatPtr in
            var currentFormatPtr = startFormatPtr
            let endFormatPtr = startFormatPtr + format.count

            var questionMarkValueIdx = -1

            while currentFormatPtr < endFormatPtr {
                let formatChar = currentFormatPtr.pointee

                // if formatChar == .backSlash {
                //    currentFormatPtr += 2
                //    continue
                // }
                if formatChar == .openBracket {

                    // This possibly the start of a formatted block. Parse it out so we know what to do...
                    var isValid = true
                    var isUnbounded = true
                    var questionMarkOffset = -1
                    var formatterIndex = -1
                    var formatterPrecision = -1
                    var formatterIndexBeforePeriod = true
                    var alignment = Alignment.right

                    let startBracketPtr = currentFormatPtr + 1
                    var endBracketPtr = currentFormatPtr + 1
                    var currentBracketPtr = currentFormatPtr + 1

                    while currentBracketPtr < endFormatPtr {
                        let bracketChar = currentBracketPtr.pointee

                        if bracketChar == .space || bracketChar == .tab || bracketChar == .newLine || bracketChar == .carriageReturn {
                            isUnbounded = false
                        } else if bracketChar == .closeBracket {
                            endBracketPtr = currentBracketPtr
                            break
                        } else if bracketChar == .questionMark {
                            if questionMarkOffset < 0 {
                                questionMarkOffset = 0
                            }
                            questionMarkOffset += 1
                        } else if bracketChar == .minus {
                            alignment = .left
                        } else if bracketChar == .plus {
                            alignment = .right
                        } else if bracketChar == .tilde {
                            alignment = .center
                        } else if bracketChar >= .zero && bracketChar <= .nine {
                            if formatterIndexBeforePeriod {
                                if formatterIndex < 0 {
                                    formatterIndex = 0
                                }
                                formatterIndex = (formatterIndex * 10) + Int(bracketChar - .zero)
                            } else {
                                if formatterPrecision < 0 {
                                    formatterPrecision = 0
                                }
                                formatterPrecision = (formatterPrecision * 10) + Int(bracketChar - .zero)
                            }
                        } else if bracketChar == .dot {
                            formatterIndexBeforePeriod = false
                        } else {
                            // illegale character, this must not be a format block
                            isValid = false
                            break
                        }
                        currentBracketPtr += 1
                    }

                    if questionMarkOffset == -1 && formatterIndex == -1 {
                        isValid = false
                    }

                    // print("startBrackIdx: \(startBracketPtr - startFormatPtr)")
                    // print("endBrackIdx: \(endBracketPtr - startFormatPtr)")
                    // print("isValid: \(isValid)")
                    // print("isUnbounded: \(isUnbounded)")
                    // print("formatterIndex: \(formatterIndex)")
                    // print("formatterPrecision: \(formatterPrecision)")
                    // print("alignment: \(alignment)")
                    // print("")

                    guard isValid else {
                        scratch.append(formatChar)
                        currentFormatPtr += 1
                        continue
                    }

                    if questionMarkOffset >= 0 {
                        questionMarkValueIdx += questionMarkOffset
                        formatterIndex = Swift.min(questionMarkValueIdx, values.count - 1)
                    }

                    if formatterPrecision < 0 {
                        formatterPrecision = defaultPrecision
                    }

                    // Ok, we have a format block. If it's unbounded, then we
                    // can solve it using the fast path
                    guard isUnbounded == false else {
                        appendUnboundedValue(formatterIndex,
                                             formatterPrecision)
                        currentFormatPtr = endBracketPtr + 1
                        continue
                    }

                    // Since this is a bounded value, we have a little bit harder
                    // time solving it performantly
                    appendBoundedValue(formatterIndex,
                                       formatterPrecision,
                                       endBracketPtr - startBracketPtr + 2,
                                       alignment)
                    currentFormatPtr = endBracketPtr + 1

                    continue
                }

                scratch.append(formatChar)
                currentFormatPtr += 1
            }

            if scratch != self {
                insert(scratch, index: count)
            }
        }

        return self

        /*
        // let capacity = format.count + values.reduce(0, { $0 + $1?.count })
        let capacity = format.count

        reserveCapacity(capacity)

        let scratch = index == count ? self : Hitch(capacity: capacity)
        let bracesScratch = Hitch(capacity: format.count * 2)

        var inFormatter = false
        var inEscaped = false

        var variableIndex: Int = 0

        var beforePeriod = true
        var formatterPrecision: Int = 0
        var formatterHasIndex = false
        var formatterIndex: Int = 0
        var formatterIsUnbounded = true
        var formatterFieldWidth: Int = 0
        var formatterFieldAlignment: Alignment = .right

        let resetBraceStart = {
            inFormatter = true
            formatterHasIndex = false
            formatterIndex = 0
            formatterPrecision = 0
            formatterFieldWidth = 1
            formatterFieldAlignment = .right
            formatterIsUnbounded = true
            bracesScratch.clear()
            beforePeriod = true
        }

        for c in format {
            if inEscaped {
                inEscaped = false
                continue
            }
            if inFormatter {
                bracesScratch.append(c)

                formatterFieldWidth += 1
                if c == .closeBracket {
                    inFormatter = false
                    if formatterHasIndex == false {
                        // We hit something like {  }, not a real formatter
                        inFormatter = false
                        scratch.append(.openBracket)
                        scratch.append(bracesScratch)
                        bracesScratch.clear()
                    } else if formatterIndex >= 0 && formatterIndex < hitches.count {

                        var valueString = hitches[formatterIndex]

                        if beforePeriod == false && formatterPrecision >= 0 {
                            // find the first "."; include "formatterPrecision" number of digits after it and ignore the rest
                            let valueScratch = Hitch(capacity: valueString.count)
                            var waitingForFirstDot = true
                            var skippingDigits = false
                            var keepCount = 0

                            for c in valueString {
                                if waitingForFirstDot {
                                    if c == .dot {
                                        waitingForFirstDot = false
                                        keepCount = formatterPrecision
                                    }
                                    valueScratch.append(c)
                                    continue
                                } else {
                                    if keepCount > 0 {
                                        valueScratch.append(c)
                                        keepCount -= 1
                                        if keepCount <= 0 {
                                            skippingDigits = true
                                        }
                                        continue
                                    }

                                    if skippingDigits {
                                        if c >= UInt8.zero && c <= UInt8.nine {
                                            continue
                                        }
                                        skippingDigits = false
                                    }

                                    valueScratch.append(c)
                                }
                            }

                            valueString = valueScratch
                        }

                        if formatterIsUnbounded {
                            scratch.append(valueString)
                        } else {
                            let extra = formatterFieldWidth - valueString.count
                            if extra > 0 {
                                switch formatterFieldAlignment {
                                case .left:
                                    scratch.append(valueString)
                                    for _ in 0..<extra {
                                        scratch.append(.space)
                                    }
                                case .right:
                                    for _ in 0..<extra {
                                        scratch.append(.space)
                                    }
                                    scratch.append(valueString)
                                case .center:
                                    let leftPadding = extra / 2
                                    let rightPadding = extra - leftPadding
                                    for _ in 0..<leftPadding {
                                        scratch.append(.space)
                                    }
                                    scratch.append(valueString)
                                    for _ in 0..<rightPadding {
                                        scratch.append(.space)
                                    }
                                }
                            } else {
                                scratch.append(valueString.substring(0, formatterFieldWidth) ?? Hitch.empty)
                            }
                        }
                    } else if formatterIsUnbounded == false {
                        for _ in 0..<formatterFieldWidth {
                            scratch.append(.space)
                        }
                    }
                    continue
                }

                switch c {
                case .dot:
                    beforePeriod = false
                case .questionMark:
                    formatterHasIndex = true
                    formatterIndex = variableIndex
                    variableIndex += 1
                case .minus:
                    formatterFieldAlignment = .left
                    formatterIsUnbounded = false
                case .tilde:
                    formatterFieldAlignment = .center
                    formatterIsUnbounded = false
                case .plus:
                    formatterFieldAlignment = .right
                    formatterIsUnbounded = false
                case .zero:
                    formatterHasIndex = true
                    if beforePeriod {
                        formatterIndex = (formatterIndex * 10) + 0
                    } else {
                        formatterPrecision = (formatterPrecision * 10) + 0
                    }
                case .one:
                    formatterHasIndex = true
                    if beforePeriod {
                        formatterIndex = (formatterIndex * 10) + 1
                    } else {
                        formatterPrecision = (formatterPrecision * 10) + 1
                    }
                case .two:
                    formatterHasIndex = true
                    if beforePeriod {
                        formatterIndex = (formatterIndex * 10) + 2
                    } else {
                        formatterPrecision = (formatterPrecision * 10) + 2
                    }
                case .three:
                    formatterHasIndex = true
                    if beforePeriod {
                        formatterIndex = (formatterIndex * 10) + 3
                    } else {
                        formatterPrecision = (formatterPrecision * 10) + 3
                    }
                case .four:
                    formatterHasIndex = true
                    if beforePeriod {
                        formatterIndex = (formatterIndex * 10) + 4
                    } else {
                        formatterPrecision = (formatterPrecision * 10) + 4
                    }
                case .five:
                    formatterHasIndex = true
                    if beforePeriod {
                        formatterIndex = (formatterIndex * 10) + 5
                    } else {
                        formatterPrecision = (formatterPrecision * 10) + 5
                    }
                case .six:
                    formatterHasIndex = true
                    if beforePeriod {
                        formatterIndex = (formatterIndex * 10) + 6
                    } else {
                        formatterPrecision = (formatterPrecision * 10) + 6
                    }
                case .seven:
                    formatterHasIndex = true
                    if beforePeriod {
                        formatterIndex = (formatterIndex * 10) + 7
                    } else {
                        formatterPrecision = (formatterPrecision * 10) + 7
                    }
                case .eight:
                    formatterHasIndex = true
                    if beforePeriod {
                        formatterIndex = (formatterIndex * 10) + 8
                    } else {
                        formatterPrecision = (formatterPrecision * 10) + 8
                    }
                case .nine:
                    formatterHasIndex = true
                    if beforePeriod {
                        formatterIndex = (formatterIndex * 10) + 9
                    } else {
                        formatterPrecision = (formatterPrecision * 10) + 9
                    }
                case .space, .newLine, .carriageReturn, .tab:
                    formatterIsUnbounded = false
                case .openBracket:
                    // we encountered a "{   {" type deal. This could be a valid brace inside
                    // a brace to be ignored.  So we invalidate the outer brace, and start
                    // tracking the inner one as if it were real
                    bracesScratch.count = bracesScratch.count - 1
                    scratch.append(.openBracket)
                    scratch.append(bracesScratch)
                    bracesScratch.clear()

                    resetBraceStart()
                    break
                default:
                    inFormatter = false
                    scratch.append(.openBracket)
                    scratch.append(bracesScratch)
                    bracesScratch.clear()
                    break
                }

            } else {
                if c == .backSlash {
                    inEscaped = true
                    continue
                }
                if c == .openBracket {
                    resetBraceStart()
                    continue
                }

                scratch.append(c)
            }
        }

        if scratch != self {
            insert(scratch, index: count)
        }

        return self
 */
    }
}
