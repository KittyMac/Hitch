import Foundation

infix operator ~==

// swiftlint:disable type_body_length

public let nullptr = UnsafePointer<UInt8>(bitPattern: 1)!

public extension ArraySlice where Element == UInt8 {

    @discardableResult
    @inline(__always)
    func toInt() -> Int? {
        return self.withUnsafeBytes { unsafeRawBufferPointer in
            let unsafeBufferPointer = unsafeRawBufferPointer.bindMemory(to: UInt8.self)
            guard let bytes = unsafeBufferPointer.baseAddress else { return nil }
            return intFromBinary(data: bytes,
                                 count: count)
        }
    }

    @discardableResult
    @inline(__always)
    func toDouble() -> Double? {
        return self.withUnsafeBytes { unsafeRawBufferPointer in
            let unsafeBufferPointer = unsafeRawBufferPointer.bindMemory(to: UInt8.self)
            guard let bytes = unsafeBufferPointer.baseAddress else { return nil }
            return doubleFromBinary(data: bytes,
                                    count: count)
        }
    }
}

public protocol Hitchable {
    @inlinable @inline(__always)
    func raw() -> UnsafePointer<UInt8>?

    @inlinable @inline(__always)
    func mutableRaw() -> UnsafeMutablePointer<UInt8>?

    @inlinable @inline(__always)
    var count: Int { get }

    @inlinable @inline(__always)
    func using<T>(_ block: (UnsafePointer<UInt8>?, Int) -> T?) -> T?
    
    @inlinable @inline(__always)
    func mutableUsing<T>(_ block: (UnsafeMutablePointer<UInt8>?, Int) -> T?) -> T?
}

public struct HitchableIterator: Sequence, IteratorProtocol {
    @usableFromInline
    internal var ptr: UnsafePointer<UInt8> = nullptr
    @usableFromInline
    internal var end: UnsafePointer<UInt8> = nullptr
    
    public init() { }

    @inlinable @inline(__always)
    public mutating func next() -> UInt8? {
        if ptr >= end { return nil }
        ptr += 1
        return ptr.pointee
    }
}

typealias HitchArray = [Hitch]
extension HitchArray {
    @inlinable @inline(__always)
    func joined(separator: HalfHitch) -> Hitch {
        var count = 0
        for part in self {
            count += separator.count
            count += part.count
        }
        let hitch = Hitch(capacity: count + 1)
        for part in self {
            hitch.append(part)
            hitch.append(separator)
        }
        hitch.count -= separator.count
        return hitch
    }
}

typealias HalfHitchArray = [HalfHitch]
extension HalfHitchArray {
    @inlinable @inline(__always)
    func joined(separator: HalfHitch) -> Hitch {
        var count = 0
        for part in self {
            count += separator.count
            count += part.count
        }
        let hitch = Hitch(capacity: count + 1)
        for part in self {
            hitch.append(part)
            hitch.append(separator)
        }
        hitch.count -= separator.count
        return hitch
    }
}

public extension Hitchable {
    
    @inlinable @inline(__always)
    var first: UInt8 {
        guard count > 0 else { return 0 }
        return self[0]
    }
    
    @inlinable @inline(__always)
    var last: UInt8 {
        guard count > 0 else { return 0 }
        return self[count-1]
    }

    @inlinable @inline(__always)
    func toTempString() -> String {
        if let raw = raw() {
            return String(bytesNoCopy: UnsafeMutableRawPointer(mutating: raw), length: count, encoding: .utf8, freeWhenDone: false) ?? ""
        }
        if let raw = mutableRaw() {
            return String(bytesNoCopy: raw, length: count, encoding: .utf8, freeWhenDone: false) ?? ""
        }
        return ""
    }

    @inlinable @inline(__always)
    func toString() -> String {
        if let raw = raw() {
            return String(data: Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: raw), count: count, deallocator: .none), encoding: .utf8) ?? ""
        }
        if let raw = mutableRaw() {
            return String(data: Data(bytesNoCopy: raw, count: count, deallocator: .none), encoding: .utf8) ?? ""
        }
        return ""
    }

    @inlinable @inline(__always)
    func using<T>(_ block: (UnsafePointer<UInt8>?, Int) -> T?) -> T? {
        if let raw = raw() {
            return block(raw, count)
        }
        return nil
    }
    
    @inlinable @inline(__always)
    func mutableUsing<T>(_ block: (UnsafeMutablePointer<UInt8>?, Int) -> T?) -> T? {
        if let raw = mutableRaw() {
            return block(raw, count)
        }
        return nil
    }

    @inlinable @inline(__always)
    static func < (lhs: Self, rhs: Self) -> Bool {
        return chitch_cmp_raw(lhs.raw(), lhs.count, rhs.raw(), rhs.count) < 0
    }

    @inlinable @inline(__always)
    static func == (lhs: Self, rhs: Self) -> Bool {
        return chitch_equal_raw(lhs.raw(), lhs.count, rhs.raw(), rhs.count)
    }
    
    @inlinable @inline(__always)
    static func ~== (lhs: Self, rhs: Self) -> Bool {
        return chitch_equal_caseless_raw(lhs.raw(), lhs.count, rhs.raw(), rhs.count)
    }

    @inlinable @inline(__always)
    func using<T>(_ callback: (UnsafePointer<UInt8>) -> T?) -> T? {
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
        var iterator = HitchableIterator()
        if let data = raw() {
            iterator.ptr = data - 1
            iterator.end = data + count - 1
        }
        return iterator
    }

    @inlinable @inline(__always)
    func stride(from: Int, to: Int) -> HitchableIterator {
        var iterator = HitchableIterator()
        if let data = raw() {
            iterator.ptr = data + from - 1
            iterator.end = data + to - 1
        }
        return iterator
    }

    @inlinable @inline(__always)
    func dataNoCopy() -> Data {
        if let raw = raw() {
            return Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: raw), count: count, deallocator: .none)
        }
        if let raw = mutableRaw() {
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

        if let raw = raw() {
            return Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: raw + start), count: end - start, deallocator: .none)
        }
        if let raw = mutableRaw() {
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
    func equals(exact other: Hitchable) -> Bool {
        return chitch_equal_raw(raw(), count, other.raw(), other.count)
    }
    
    @inlinable @inline(__always)
    func equals(caseless other: Hitchable) -> Bool {
        return chitch_equal_caseless_raw(raw(), count, other.raw(), other.count)
    }
    
    @inlinable @inline(__always)
    func startsAt(raw otherRaw: UnsafePointer<UInt8>, count otherCount: Int, caseless: Bool = false) -> Bool {
        if otherCount < count { return false }
        if caseless {
            return chitch_equal_caseless_raw(raw(), count, otherRaw, count)
        }
        return chitch_equal_raw(raw(), count, otherRaw, count)
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
                        char == .backSlash ||
                        char == .forwardSlash {
                return true
            }
            ptr += 1
        }
        return false
    }

    @inlinable @inline(__always)
    func escaped(unicode: Bool,
                 singleQuotes: Bool) -> Hitch {
        if let raw = mutableRaw() {
            return escapeBinary(unicode: raw,
                                count: count,
                                unicode: unicode,
                                singleQuotes: singleQuotes)
        } else if let raw = raw() {
            return escapeBinary(unicode: raw,
                                count: count,
                                unicode: unicode,
                                singleQuotes: singleQuotes)
        }
        return Hitch.empty
    }

    @inlinable @inline(__always)
    @discardableResult
    func starts(with hitch: Hitchable) -> Bool {
        guard count >= hitch.count else { return false }
        return chitch_equal_raw(raw(), hitch.count, hitch.raw(), hitch.count)
    }

    @inlinable @inline(__always)
    @discardableResult
    func starts(with hitch: HalfHitch) -> Bool {
        guard count >= hitch.count else { return false }
        return chitch_equal_raw(raw(), hitch.count, hitch.raw(), hitch.count)
    }

    @inlinable @inline(__always)
    @discardableResult
    func ends(with hitch: Hitchable) -> Bool {
        return lastIndex(of: hitch) == count - hitch.count
    }

    @inlinable @inline(__always)
    @discardableResult
    func ends(with hitch: HalfHitch) -> Bool {
        return lastIndex(of: hitch) == count - hitch.count
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
    func firstIndex(of hitch: HalfHitch, offset: Int = 0) -> Int? {
        let index = chitch_firstof_raw_offset(raw(), offset, count, hitch.raw(), hitch.count)
        return index >= 0 ? index : nil
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
    func lastIndex(of hitch: HalfHitch) -> Int? {
        let index = chitch_lastof_raw(raw(), count, hitch.raw(), hitch.count)
        return index >= 0 ? index : nil
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
    func extract(_ lhs: Hitchable, _ rhs: Hitchable) -> Hitch? {
        guard let lhsPos = firstIndex(of: lhs) else { return nil }
        guard let rhsPos = firstIndex(of: rhs, offset: lhsPos + lhs.count) else {
            return substring(lhsPos + lhs.count, count)
        }
        return substring(lhsPos + lhs.count, rhsPos)
    }

    @inlinable @inline(__always)
    @discardableResult
    func extract(_ lhs: HalfHitch, _ rhs: HalfHitch) -> Hitch? {
        guard let lhsPos = firstIndex(of: lhs) else { return nil }
        guard let rhsPos = firstIndex(of: rhs, offset: lhsPos + lhs.count) else {
            return substring(lhsPos + lhs.count, count)
        }
        return substring(lhsPos + lhs.count, rhsPos)
    }

    @inlinable @inline(__always)
    @discardableResult
    func toInt(fuzzy: Bool = false) -> Int? {
        if let data = raw() {
            if fuzzy {
                return intFromBinaryFuzzy(data: data,
                                          count: count)
            }
            return intFromBinary(data: data,
                                 count: count)
        }
        return nil
    }

    @inlinable @inline(__always)
    @discardableResult
    func toDouble(fuzzy: Bool = false) -> Double? {
        if let data = raw() {
            if fuzzy {
                return doubleFromBinaryFuzzy(data: data,
                                             count: count)
            }
            return doubleFromBinary(data: data,
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
func intFromBinary(data: UnsafePointer<UInt8>,
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
func doubleFromBinary(data: UnsafePointer<UInt8>,
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
func intFromBinaryFuzzy(data: UnsafePointer<UInt8>,
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
func doubleFromBinaryFuzzy(data: UnsafePointer<UInt8>,
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
func unescapeBinary(unicode data: UnsafeMutablePointer<UInt8>,
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
            case .forwardSlash: append(.forwardSlash, 2); continue
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

    write.pointee = 0
    return (write - data)
}

@inlinable @inline(__always)
func escapeBinary(unicode data: UnsafePointer<UInt8>,
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
func unescapeBinary(ampersand data: UnsafeMutablePointer<UInt8>,
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
        // &amp;&lt;&gt;&quot;&apos;&#038;
        if read.pointee == .ampersand && read < end - 2 {
            let endCount = end - read
            
            let char1 = read[1]
            if char1 == .hashTag {

                var tmpRead = read + 2
                var value: UInt32 = 0
                while tmpRead < end &&
                        tmpRead.pointee >= .zero &&
                        tmpRead.pointee <= .nine &&
                        tmpRead - read < 10 {
                    value &*= 10
                    value &+= UInt32(tmpRead.pointee - .zero)
                    tmpRead += 1
                }
                if tmpRead.pointee == .semiColon {
                    if let scalar = UnicodeScalar(value) {
                        for v in Character(scalar).utf8 {
                            append(v, 0)
                        }
                    }
                    read = tmpRead + 1
                    continue
                }
            } else if endCount >= 5 &&
                        char1 == .a &&
                        read[2] == .m &&
                        read[3] == .p &&
                        read[4] == .semiColon {
                append(.ampersand, 5)
                continue
            } else if endCount >= 6 &&
                        char1 == .a &&
                        read[2] == .p &&
                        read[3] == .o &&
                        read[4] == .s &&
                        read[5] == .semiColon {
                append(.singleQuote, 6)
                continue
            } else if endCount >= 4 &&
                        char1 == .l &&
                        read[2] == .t &&
                        read[3] == .semiColon {
                append(.lessThan, 4)
                continue
            } else if endCount >= 4 &&
                        char1 == .g &&
                        read[2] == .t &&
                        read[3] == .semiColon {
                append(.greaterThan, 4)
                continue
            } else if endCount >= 6 &&
                        char1 == .q &&
                        read[2] == .u &&
                        read[3] == .o &&
                        read[4] == .t &&
                        read[5] == .semiColon {
                append(.doubleQuote, 6)
                continue
            } else if endCount >= 5 &&
                        char1 == .t &&
                        read[2] == .a &&
                        read[3] == .b &&
                        read[4] == .semiColon {
                append(.tab, 5)
                continue
            } else if endCount >= 9 &&
                        char1 == .n &&
                        read[2] == .e &&
                        read[3] == .w &&
                        read[4] == .l &&
                        read[5] == .i &&
                        read[6] == .n &&
                        read[7] == .e &&
                        read[8] == .semiColon {
                append(.newLine, 9)
                continue
            } else if endCount >= 6 &&
                        char1 == .n &&
                        read[2] == .b &&
                        read[3] == .s &&
                        read[4] == .p &&
                        read[5] == .semiColon {
                append(.space, 6)
                continue
            }
        }

        append(read.pointee, 1)
    }

    write.pointee = 0
    return (write - data)
}

@inlinable @inline(__always)
func unescapeBinary(mime data: UnsafeMutablePointer<UInt8>,
                    count: Int) -> Int {
    var read = data
    var write = data
    let end = data + count

    let append: (UInt8, Int) -> Void = { v, advance in
        if v == .carriageReturn {
            read += advance
            return
        }
        
        write.pointee = v
        write += 1
        read += advance
    }

    while read < end {
        if read.pointee == .equal && read < end-2 {
            
            // =\r\n where it is not =\r\n\r\n should be skipped
            if read[1] == .carriageReturn &&
                read[2] == .newLine &&
                read[3] != .carriageReturn {
                read += 3
                continue
            }
            
            // =C2=A0
            let char1 = read[1]
            let char2 = read[2]
            
            var value1: UInt8 = 0
            if char1 >= .zero && char1 <= .nine {
                value1 += char1 - .zero
            } else if char1 >= .a && char1 <= .f {
                value1 += (char1 - .a) + 10
            } else if char1 >= .A && char1 <= .F {
                value1 += (char1 - .A) + 10
            } else {
                append(read.pointee, 1)
                continue
            }
            
            var value2: UInt8 = 0
            if char2 >= .zero && char2 <= .nine {
                value2 += char2 - .zero
            } else if char2 >= .a && char2 <= .f {
                value2 += (char2 - .a) + 10
            } else if char2 >= .A && char2 <= .F {
                value2 += (char2 - .A) + 10
            } else {
                append(read.pointee, 1)
                continue
            }
            
            let ascii: UInt8 = value1 * 16 + value2
            append(ascii, 3)
            continue
        }

        append(read.pointee, 1)
    }
    
    write.pointee = 0
    return (write - data)
}

@inlinable @inline(__always)
func unescapeBinary(percent data: UnsafeMutablePointer<UInt8>,
                    count: Int) -> Int {
    // https:\/\/www.google.com\/url?q=https%3A%2F%2Fsardelkitchen.com&amp;sa=D&amp;sntz=1&amp;usg=AOvVaw1T4EtLqdGmEYA-MilAqQIc"
    var read = data
    var write = data
    let end = data + count

    let append: (UInt8, Int) -> Void = { v, advance in
        write.pointee = v
        write += 1
        read += advance
    }

    while read < end {

        if read.pointee == .percentSign && read < end-2 {
            
            let char1 = read[1]
            let char2 = read[2]
            
            var value1: UInt8 = 0
            if char1 >= .zero && char1 <= .nine {
                value1 += char1 - .zero
            } else if char1 >= .a && char1 <= .f {
                value1 += (char1 - .a) + 10
            } else if char1 >= .A && char1 <= .F {
                value1 += (char1 - .A) + 10
            } else {
                append(read.pointee, 1)
                continue
            }
            
            var value2: UInt8 = 0
            if char2 >= .zero && char2 <= .nine {
                value2 += char2 - .zero
            } else if char2 >= .a && char2 <= .f {
                value2 += (char2 - .a) + 10
            } else if char2 >= .A && char2 <= .F {
                value2 += (char2 - .A) + 10
            } else {
                append(read.pointee, 1)
                continue
            }
            
            let ascii: UInt8 = value1 * 16 + value2
            append(ascii, 3); continue
        }

        append(read.pointee, 1)
    }

    write.pointee = 0
    return (write - data)
}

@inlinable @inline(__always)
func decimal(_ v: UInt8) -> UInt32? {
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
    default: return nil
    }
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
