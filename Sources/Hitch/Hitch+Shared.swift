import Foundation

// swiftlint:disable type_body_length

public protocol Hitchable {
    @inlinable @inline(__always)
    func raw() -> UnsafeMutablePointer<UInt8>?

    @inlinable @inline(__always)
    var count: Int { get }
}

public struct HitchableIterator: Sequence, IteratorProtocol {
    @usableFromInline
    internal var ptr: UnsafeMutablePointer<UInt8>
    @usableFromInline
    internal let end: UnsafeMutablePointer<UInt8>

    @inlinable @inline(__always)
    internal init(hitch: Hitchable) {
        if let data = hitch.raw() {
            ptr = data - 1
            end = data + hitch.count - 1
        } else {
            ptr = nullptr
            end = ptr
        }
    }

    @inlinable @inline(__always)
    internal init(hitch: Hitchable, from: Int, to: Int) {
        if let data = hitch.raw() {
            ptr = data + from - 1
            end = data + to - 1
        } else {
            ptr = nullptr
            end = ptr
        }
    }

    @inlinable @inline(__always)
    public mutating func next() -> UInt8? {
        if ptr >= end { return nil }
        ptr += 1
        return ptr.pointee
    }
}

public extension Hitchable {

    var description: String {
        guard let raw = raw() else { return "" }
        return String(bytesNoCopy: raw, length: count, encoding: .utf8, freeWhenDone: false) ?? ""
    }

    @inlinable @inline(__always)
    func toString() -> String {
        guard let raw = raw() else { return "" }
        return String(data: Data(bytesNoCopy: raw, count: count, deallocator: .none), encoding: .utf8) ?? ""
    }

    @inlinable @inline(__always)
    func hash(into hasher: inout Hasher) {
        hasher.combine(count)
        hasher.combine(bytes: UnsafeRawBufferPointer(start: raw(), count: Swift.min(count, 8)))
    }

    @inlinable @inline(__always)
    static func < (lhs: Self, rhs: Self) -> Bool {
        return chitch_cmp_raw(lhs.raw(), lhs.count, rhs.raw(), rhs.count) < 0
    }

    @inlinable @inline(__always)
    static func < (lhs: String, rhs: Self) -> Bool {
        return chitch_using(lhs) { string_raw, string_count in
            return chitch_cmp_raw(string_raw, string_count, rhs.raw(), rhs.count) < 0
        }
    }

    @inlinable @inline(__always)
    static func < (lhs: Self, rhs: String) -> Bool {
        return chitch_using(rhs) { string_raw, string_count in
            return chitch_cmp_raw(lhs.raw(), lhs.count, string_raw, string_count) < 0
        }
    }

    @inlinable @inline(__always)
    static func == (lhs: Self, rhs: Self) -> Bool {
        return chitch_equal_raw(lhs.raw(), lhs.count, rhs.raw(), rhs.count)
    }

    @inlinable @inline(__always)
    static func == (lhs: String, rhs: Self) -> Bool {
        return chitch_using(lhs) { string_raw, string_count in
            return chitch_equal_raw(string_raw, string_count, rhs.raw(), rhs.count)
        }
    }

    @inlinable @inline(__always)
    static func == (lhs: Self, rhs: String) -> Bool {
        return chitch_using(rhs) { string_raw, string_count in
            return chitch_equal_raw(lhs.raw(), lhs.count, string_raw, string_count)
        }
    }

    @inlinable @inline(__always)
    func using<T>(_ callback: (UnsafeMutablePointer<UInt8>) -> T?) -> T? {
        if let raw = raw() {
            return callback(raw)
        }
        return nil
    }

    @inlinable @inline(__always)
    subscript (index: Int) -> UInt8 {
        get {
            guard let raw = raw() else { return 0 }
            guard index >= 0 && index < count else { return 0 }
            return raw[index]
        }
    }

    @inlinable @inline(__always)
    func makeIterator() -> HitchableIterator {
        return HitchableIterator(hitch: self)
    }

    @inlinable @inline(__always)
    func stride(from: Int, to: Int) -> HitchableIterator {
        return HitchableIterator(hitch: self, from: from, to: to)
    }

    @inlinable @inline(__always)
    func dataNoCopy() -> Data {
        if let raw = raw() {
            return Data(bytesNoCopy: raw, count: count, deallocator: .none)
        }
        return Data()
    }

    @inlinable @inline(__always)
    func dataCopy() -> Data {
        if let raw = raw() {
            return Data(bytes: raw, count: count)
        }
        return Data()
    }

    @inlinable @inline(__always)
    func dataNoCopy(start inStart: Int = -1,
                    end inEnd: Int = -1) -> Data {
        if let raw = raw() {

            let max = count
            var start = inStart
            var end = inEnd

            if start < 0 || start > max {
                start = 0
            }
            if end < 0 || start > max {
                end = max
            }
            if start > end {
                end = start
            }

            return Data(bytesNoCopy: raw + start, count: end - start, deallocator: .none)
        }
        return Data()
    }

    @inlinable @inline(__always)
    func dataCopy(start inStart: Int,
                  end inEnd: Int) -> Data {
        if let data = raw() {

            let max = count
            var start = inStart
            var end = inEnd

            if start < 0 || start > max {
                start = 0
            }
            if end < 0 || start > max {
                end = max
            }
            if start > end {
                end = start
            }

            return Data(bytes: data + start, count: end - start)
        }
        return Data()
    }

    @inlinable @inline(__always)
    func compare(other: Hitchable) -> Int {
        return chitch_cmp_raw(raw(), count, other.raw(), other.count)
    }

    @inlinable @inline(__always)
    func canEscape(unicode: Bool,
                   singleQuotes: Bool) -> Bool {
        guard var ptr = raw() else { return false }
        let end = ptr + count
        while ptr < end {
            let char = ptr.pointee
            if unicode && char > 0x7f {
                return true
            } else if singleQuotes && char == .singleQuote {
                return true
            } else if char == .bell ||
                        char == .newLine ||
                        char == .tab ||
                        char == .formFeed ||
                        char == .carriageReturn ||
                        char == .doubleQuote ||
                        char == .backSlash {
                return true
            }
            ptr += 1
        }
        return false
    }

    @inlinable @inline(__always)
    func escaped(unicode: Bool,
                        singleQuotes: Bool) -> Hitch {
        guard let raw = raw() else { return Hitch() }
        return escapeBinary(data: raw,
                            count: count,
                            unicode: unicode,
                            singleQuotes: singleQuotes)
    }

    @inlinable @inline(__always)
    @discardableResult
    func starts(with hitch: Hitchable) -> Bool {
        guard count > hitch.count else { return false }
        return chitch_equal_raw(raw(), hitch.count, hitch.raw(), hitch.count)
    }

    @inlinable @inline(__always)
    @discardableResult
    func starts(with string: String) -> Bool {
        return chitch_using(string) { string_raw, string_count in
            guard count > string_count else { return false }
            return chitch_equal_raw(raw(), string_count, string_raw, string_count)
        }
    }

    @inlinable @inline(__always)
    @discardableResult
    func contains(_ hitch: Hitchable) -> Bool {
        return chitch_contains_raw(raw(), count, hitch.raw(), hitch.count)
    }

    @inlinable @inline(__always)
    @discardableResult
    func contains(_ halfHitch: HalfHitch) -> Bool {
        return chitch_contains_raw(raw(), count, halfHitch.source, halfHitch.count)
    }

    @inlinable @inline(__always)
    @discardableResult
    func contains(_ string: String) -> Bool {
        return chitch_using(string) { string_raw, string_count in
            return chitch_contains_raw(raw(), count, string_raw, string_count)
        }
    }

    @inlinable @inline(__always)
    @discardableResult
    func contains(char: UInt8) -> Bool {
        var local = char
        return chitch_contains_raw(raw(), count, &local, 1)
    }

    @inlinable @inline(__always)
    @discardableResult
    func firstIndex(of hitch: Hitchable, offset: Int = 0) -> Int? {
        let index = chitch_firstof_raw_offset(raw(), offset, count, hitch.raw(), hitch.count)
        return index >= 0 ? index : nil
    }

    @inlinable @inline(__always)
    @discardableResult
    func firstIndex(of string: String, offset: Int = 0) -> Int? {
        return chitch_using(string) { string_raw, string_count in
            let index = chitch_firstof_raw_offset(raw(), offset, count, string_raw, string_count)
            return index >= 0 ? index : nil
        }
    }

    @inlinable @inline(__always)
    @discardableResult
    func firstIndex(of char: UInt8, offset: Int = 0) -> Int? {
        var local = char
        let index = chitch_firstof_raw_offset(raw(), offset, count, &local, 1)
        return index >= 0 ? index : nil
    }

    @inlinable @inline(__always)
    @discardableResult
    func lastIndex(of hitch: Hitchable) -> Int? {
        let index = chitch_lastof_raw(raw(), count, hitch.raw(), hitch.count)
        return index >= 0 ? index : nil
    }

    @inlinable @inline(__always)
    @discardableResult
    func lastIndex(of string: String) -> Int? {
        return chitch_using(string) { string_raw, string_count in
            let index = chitch_lastof_raw(raw(), count, string_raw, string_count)
            return index >= 0 ? index : nil
        }
    }

    @inlinable @inline(__always)
    @discardableResult
    func lastIndex(of char: UInt8) -> Int? {
        var local = char
        let index = chitch_lastof_raw(raw(), count, &local, 1)
        return index >= 0 ? index : nil
    }

    @inlinable @inline(__always)
    @discardableResult
    func substring(_ lhsPos: Int, _ rhsPos: Int) -> Hitch? {
        guard lhsPos >= 0 && lhsPos <= count else { return nil }
        guard rhsPos >= 0 && rhsPos <= count else { return nil }
        guard lhsPos <= rhsPos else { return nil }
        return Hitch(chitch: chitch_init_substring_raw(raw(), count, lhsPos, rhsPos))
    }

    @inlinable @inline(__always)
    @discardableResult
    func extract(_ lhs: Hitch, _ rhs: Hitch) -> Hitch? {
        guard let lhsPos = firstIndex(of: lhs) else { return nil }
        guard let rhsPos = firstIndex(of: rhs, offset: lhsPos + lhs.count) else {
            return substring(lhsPos + lhs.count, count)
        }
        return substring(lhsPos + lhs.count, rhsPos)
    }

    @inlinable @inline(__always)
    @discardableResult
    func extract(_ lhs: String, _ rhs: String) -> Hitch? {
        return extract(lhs.hitch(), rhs.hitch())
    }

    @inlinable @inline(__always)
    @discardableResult
    func extract(_ lhs: Hitch, _ rhs: String) -> Hitch? {
        return extract(lhs, rhs.hitch())
    }

    @inlinable @inline(__always)
    @discardableResult
    func extract(_ lhs: String, _ rhs: Hitch) -> Hitch? {
        return extract(lhs.hitch(), rhs)
    }

    @inlinable @inline(__always)
    @discardableResult
    func toInt(fuzzy: Bool = false) -> Int? {
        if let data = raw() {
            if fuzzy {
                return intFromBinaryFuzzy(data: UnsafeRawBufferPointer(start: data, count: count),
                                          count: count)
            }
            return intFromBinary(data: UnsafeRawBufferPointer(start: data, count: count),
                                 count: count)
        }
        return nil
    }

    @inlinable @inline(__always)
    @discardableResult
    func toDouble(fuzzy: Bool = false) -> Double? {
        if let data = raw() {
            if fuzzy {
                return doubleFromBinaryFuzzy(data: UnsafeRawBufferPointer(start: data, count: count),
                                             count: count)
            }
            return doubleFromBinary(data: UnsafeRawBufferPointer(start: data, count: count),
                                    count: count)
        }
        return nil
    }

    @inlinable @inline(__always)
    @discardableResult
    func toEpoch() -> Int {
        return chitch_toepoch_raw(raw(), count)
    }
}

@inlinable @inline(__always)
func roundToPlaces(value: Double, places: Int) -> Double {
    let divisor = pow(10.0, Double(places))
    return round(value * divisor) / divisor
}

@inlinable @inline(__always)
func intFromBinary(data: UnsafeRawBufferPointer,
                   count: Int) -> Int? {
    var value = 0
    var hasValue = false
    var isNegative = false
    var endedOnlyAllowsWhitespace = false
    var idx = 0

    var skipping = true
    while skipping && idx < count {
        let char = UInt8(data[idx])
        switch char {
        case .zero, .one, .two, .three, .four, .five, .six, .seven, .eight, .nine, .minus:
            skipping = false
            break
        default:
            idx += 1
            break
        }
    }

    while idx < count {
        let char = UInt8(data[idx])
        if endedOnlyAllowsWhitespace == true {
            switch char {
            case .space, .tab, .newLine, .carriageReturn:
                break
            default:
                return nil
            }
        } else if char == .minus && value == 0 {
            isNegative = true
        } else if char >= .zero && char <= .nine {
            hasValue = true
            value = (value &* 10) &+ Int(char - .zero)
        } else {
            endedOnlyAllowsWhitespace = true
        }
        idx += 1
    }
    if hasValue == false {
        return nil
    }
    if isNegative {
        value = -1 * value
    }
    return value
}

@inlinable @inline(__always)
func doubleFromBinary(data: UnsafeRawBufferPointer,
                      count: Int) -> Double? {
    var value: Double = 0
    var hasValue = false
    var isNegative = false
    var endedOnlyAllowsWhitespace = false
    var idx = 0

    // skip leading whitespace
    while idx < count {
        let char = data[idx]
        if char == .space || char == .tab || char == .newLine || char == .carriageReturn {
            idx += 1
        } else {
            break
        }
    }

    // part before the period
    while idx < count {
        let char = data[idx]
        if endedOnlyAllowsWhitespace == true {
            if char != .space && char != .tab && char != .newLine && char != .carriageReturn {
                return nil
            }
        } else if char == .minus && value == 0 {
            isNegative = true
        } else if char >= .zero && char <= .nine {
            hasValue = true
            value = (value * 10) + Double(char - .zero)
        } else if char == .dot {
            break
        } else {
            endedOnlyAllowsWhitespace = true
        }
        idx += 1
    }

    // part after the period
    if idx < count && data[idx] == .dot {
        idx += 1

        var precision = 0
        var divider: Double = 10.0
        while idx < count {
            let char = data[idx]
            if endedOnlyAllowsWhitespace == true {
                if char != .space && char != .tab && char != .newLine && char != .carriageReturn {
                    return nil
                }
            } else if char >= .zero && char <= .nine {
                hasValue = true
                value = value + Double(char - .zero) / divider
                divider *= 10.0
            } else {
                endedOnlyAllowsWhitespace = true
            }
            precision += 1
            idx += 1
        }

        if precision > 0 {
            value = roundToPlaces(value: value, places: precision)
        }
    }

    if hasValue == false {
        return nil
    }
    if isNegative {
        value = -1 * value
    }
    return value
}

@inlinable @inline(__always)
func intFromBinaryFuzzy(data: UnsafeRawBufferPointer,
                        count: Int) -> Int? {
    var value = 0
    var hasValue = false
    var isNegative = false
    var idx = 0

    while idx < count {
        let char = data[idx]
        if char == .minus && value == 0 {
            isNegative = true
        } else if char >= .zero && char <= .nine {
            hasValue = true
            value = (value &* 10) &+ Int(char - .zero)
        }
        idx += 1
    }
    if hasValue == false {
        return nil
    }
    if isNegative {
        value = -1 * value
    }
    return value
}

@inlinable @inline(__always)
func doubleFromBinaryFuzzy(data: UnsafeRawBufferPointer,
                           count: Int) -> Double? {
    var value: Double = 0
    var hasValue = false
    var isNegative = false
    var idx = 0

    // part before the period
    while idx < count {
        let char = data[idx]
        if char == .minus && value == 0 {
            isNegative = true
        } else if char >= .zero && char <= .nine {
            hasValue = true
            value = (value * 10) + Double(char - .zero)
        } else if char == .dot {
            break
        }
        idx += 1
    }

    // part after the period
    if idx < count && data[idx] == .dot {
        idx += 1

        var precision = 0
        var divider: Double = 10.0
        while idx < count {
            let char = data[idx]
            if char >= .zero && char <= .nine {
                hasValue = true
                value = value + Double(char - .zero) / divider
                divider *= 10.0
            }
            precision += 1
            idx += 1
        }

        if precision > 0 {
            value = roundToPlaces(value: value, places: precision)
        }
    }

    if hasValue == false {
        return nil
    }
    if isNegative {
        value = -1 * value
    }
    return value
}

@inlinable @inline(__always)
func unescapeBinary(data: UnsafeMutablePointer<UInt8>,
                    count: Int) -> Int {
    var read = data
    var write = data
    let end = data + count

    let append: (UInt8, Int) -> Void = { v, advance in
        write.pointee = v
        write += 1
        read += advance
    }

    while read < end {

        if read.pointee == .backSlash {
            switch read[1] {
            case .backSlash: append(.backSlash, 2); continue
            case .singleQuote: append(.singleQuote, 2); continue
            case .doubleQuote: append(.doubleQuote, 2); continue
            case .r: append(.carriageReturn, 2); continue
            case .f: append(.formFeed, 2); continue
            case .t: append(.tab, 2); continue
            case .n: append(.newLine, 2); continue
            case .b: append(.bell, 2); continue
            case .u:
                let convert: (() -> Bool) -> Void = { endCondition in
                    var value: UInt32 = 0
                    while read < end && endCondition() == false {
                        guard let byte = hex(read.pointee) else { break }
                        value &*= 16
                        value &+= byte
                        read += 1
                    }
                    if let scalar = UnicodeScalar(value) {
                        for v in Character(scalar).utf8 {
                            append(v, 0)
                        }
                    }
                }

                if read[2] == .openBracket {
                    // like: \u{1D11E}
                    read += 3
                    convert {
                        return read.pointee == .closeBracket
                    }
                    if read.pointee == .closeBracket {
                        read += 1
                    }
                } else {
                    // like: \u20AC
                    read += 2
                    let start = read
                    convert {
                        return read - start >= 4
                    }
                }
                continue
            default:
                break
            }
        }

        append(read.pointee, 1)
    }

    return (write - data)
}

@inlinable @inline(__always)
func escapeBinary(data: UnsafeMutablePointer<UInt8>,
                  count: Int,
                  unicode: Bool,
                  singleQuotes: Bool) -> Hitch {
    let writer = Hitch(capacity: count)

    var read = data
    let end = data + count

    while read < end {
        let ch = read.pointee

        if unicode && ch > 0x7f {
            writer.append(.backSlash)
            writer.append(.u)

            var value: UInt32 = 0
            if ch & 0b11100000 == 0b11000000 {
                value |= (UInt32(read[0]) & 0b00011111) << 6
                value |= (UInt32(read[1]) & 0b00111111) << 0
                read += 1
            } else if ch & 0b11110000 == 0b11100000 {
                value |= (UInt32(read[0]) & 0b00001111) << 12
                value |= (UInt32(read[1]) & 0b00111111) << 6
                value |= (UInt32(read[2]) & 0b00111111) << 0
                read += 2
            } else if ch & 0b11111000 == 0b11110000 {
                value |= (UInt32(read[0]) & 0b00000111) << 18
                value |= (UInt32(read[1]) & 0b00111111) << 12
                value |= (UInt32(read[2]) & 0b00111111) << 6
                value |= (UInt32(read[3]) & 0b00111111) << 0
                read += 3
            }

            if value > 0xFFFF {
                writer.append(.openBracket)
            }

            var hasFoundBits = false
            for shift in [28, 24, 20, 16, 12, 8, 4, 0] {
                let hex = hex2((value >> shift) & 0xF)
                if hex != .zero || shift <= 12 {
                    hasFoundBits = true
                }
                guard hasFoundBits else { continue }

                writer.append(hex)
            }

            if value > 0xFFFF {
                writer.append(.closeBracket)
            }

        } else {
            switch ch {
            case .bell:
                writer.append(.backSlash)
                writer.append(.b)
            case .newLine:
                writer.append(.backSlash)
                writer.append(.n)
            case .tab:
                writer.append(.backSlash)
                writer.append(.t)
            case .formFeed:
                writer.append(.backSlash)
                writer.append(.f)
            case .carriageReturn:
                writer.append(.backSlash)
                writer.append(.r)
            case .singleQuote:
                if singleQuotes {
                    writer.append(.backSlash)
                }
                writer.append(.singleQuote)
            case .doubleQuote:
                writer.append(.backSlash)
                writer.append(.doubleQuote)
            case .backSlash:
                writer.append(.backSlash)
                writer.append(.backSlash)
            default:
                writer.append(ch)
            }
        }

        read += 1
    }

    return writer
}

@inlinable @inline(__always)
func hex(_ v: UInt8) -> UInt32? {
    switch v {
    case .zero: return 0
    case .one: return 1
    case .two: return 2
    case .three: return 3
    case .four: return 4
    case .five: return 5
    case .six: return 6
    case .seven: return 7
    case .eight: return 8
    case .nine: return 9
    case .a, .A: return 10
    case .b, .B: return 11
    case .c, .C: return 12
    case .d, .D: return 13
    case .e, .E: return 14
    case .f, .F: return 15
    default: return nil
    }
}

@inlinable @inline(__always)
func hex2(_ v: UInt32) -> UInt8 {
    switch v {
    case 0: return .zero
    case 1: return .one
    case 2: return .two
    case 3: return .three
    case 4: return .four
    case 5: return .five
    case 6: return .six
    case 7: return .seven
    case 8: return .eight
    case 9: return .nine
    case 10: return .A
    case 11: return .B
    case 12: return .C
    case 13: return .D
    case 14: return .E
    case 15: return .F
    default: return .questionMark
    }
}

public let nullptr = UnsafeMutablePointer<UInt8>(bitPattern: 1)!
