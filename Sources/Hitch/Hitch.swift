// swiftlint:disable type_body_length

import Foundation
import cHitch

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
        let char = Int8(data[idx])
        switch char {
        case Int8.zero, Int8.one, Int8.two, Int8.three, Int8.four, Int8.five, Int8.six, Int8.seven, Int8.eight, Int8.nine, Int8.minus:
            skipping = false
            break
        default:
            idx += 1
            break
        }
    }

    while idx < count {
        let char = Int8(data[idx])
        if endedOnlyAllowsWhitespace == true {
            switch char {
            case Int8.space, Int8.tab, Int8.newLine, Int8.carriageReturn:
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
        if char == Int8.space || char == Int8.tab || char == Int8.newLine || char == Int8.carriageReturn {
            idx += 1
        } else {
            break
        }
    }

    // part before the period
    while idx < count {
        let char = data[idx]
        if endedOnlyAllowsWhitespace == true {
            if char != Int8.space && char != Int8.tab && char != Int8.newLine && char != Int8.carriageReturn {
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
                if char != Int8.space && char != Int8.tab && char != Int8.newLine && char != Int8.carriageReturn {
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
func unescapeBinary(data: UnsafeMutablePointer<Int8>,
                    count: Int) -> Int {
    var read = data
    var write = data
    let end = data + count

    let append: (Int8, Int) -> Void = { v, advance in
        write.pointee = v
        write += 1
        read += advance
    }

    while read < end {

        if read.pointee == Int8.backSlash {
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
                            append(Int8(v), 0)
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
func escapeBinary(data: UnsafeMutablePointer<Int8>,
                  count: Int,
                  unicode: Bool,
                  singleQuotes: Bool) -> Hitch {
    let writer = Hitch(capacity: count)

    var read = data
    let end = data + count

    while read < end {
        let ch = read.pointee
        let uch = UInt8(ch)

        if unicode && ch > 0x7f {
            writer.append(Int8.backSlash)
            writer.append(Int8.u)

            var value: UInt32 = 0
            if uch & 0b11100000 == 0b11000000 {
                value |= (UInt32(read[0]) & 0b00011111) << 6
                value |= (UInt32(read[1]) & 0b00111111) << 0
                read += 1
            } else if uch & 0b11110000 == 0b11100000 {
                value |= (UInt32(read[0]) & 0b00001111) << 12
                value |= (UInt32(read[1]) & 0b00111111) << 6
                value |= (UInt32(read[2]) & 0b00111111) << 0
                read += 2
            } else if uch & 0b11111000 == 0b11110000 {
                value |= (UInt32(read[0]) & 0b00000111) << 18
                value |= (UInt32(read[1]) & 0b00111111) << 12
                value |= (UInt32(read[2]) & 0b00111111) << 6
                value |= (UInt32(read[3]) & 0b00111111) << 0
                read += 3
            }

            if value > 0xFFFF {
                writer.append(Int8.openBracket)
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
                writer.append(Int8.closeBracket)
            }

        } else {
            switch ch {
            case .bell:
                writer.append(Int8.backSlash)
                writer.append(Int8.b)
            case .newLine:
                writer.append(Int8.backSlash)
                writer.append(Int8.n)
            case .tab:
                writer.append(Int8.backSlash)
                writer.append(Int8.t)
            case .formFeed:
                writer.append(Int8.backSlash)
                writer.append(Int8.f)
            case .carriageReturn:
                writer.append(Int8.backSlash)
                writer.append(Int8.r)
            case .singleQuote:
                if singleQuotes {
                    writer.append(Int8.backSlash)
                }
                writer.append(Int8.singleQuote)
            case .doubleQuote:
                writer.append(Int8.backSlash)
                writer.append(Int8.doubleQuote)
            case .backSlash:
                writer.append(Int8.backSlash)
                writer.append(Int8.backSlash)
            default:
                writer.append(Int8(ch))
            }
        }

        read += 1
    }

    return writer
}

@inlinable @inline(__always)
func hex(_ v: Int8) -> UInt32? {
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
func hex2(_ v: UInt32) -> Int8 {
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

public let nullptr = UnsafeMutablePointer<Int8>(bitPattern: 1)!

public extension String {
    func hitch() -> Hitch {
        return Hitch(stringLiteral: self)
    }
}

public struct HitchIterator: Sequence, IteratorProtocol {
    @usableFromInline
    internal var ptr: UnsafeMutablePointer<Int8>
    @usableFromInline
    internal let end: UnsafeMutablePointer<Int8>

    @inlinable @inline(__always)
    internal init(hitch: Hitch) {
        if let data = hitch.raw() {
            ptr = data - 1
            end = data + hitch.count - 1
        } else {
            ptr = nullptr
            end = ptr
        }
    }

    @inlinable @inline(__always)
    internal init(hitch: Hitch, from: Int, to: Int) {
        if let data = hitch.raw() {
            ptr = data + from - 1
            end = data + to - 1
        } else {
            ptr = nullptr
            end = ptr
        }
    }

    @inlinable @inline(__always)
    public mutating func next() -> Int8? {
        if ptr >= end { return nil }
        ptr += 1
        return ptr.pointee
    }
}

@usableFromInline
struct HitchOutputStream: TextOutputStream {
    @usableFromInline
    let hitch: Hitch

    @usableFromInline
    let index: Int?

    @usableFromInline
    let precision: Int?

    @usableFromInline
    init(hitch: Hitch, index: Int? = nil, precision: Int? = nil) {
        self.hitch = hitch
        self.index = index
        self.precision = precision
    }

    @inlinable @inline(__always)
    mutating func write(_ string: String) {
        if let index = index {
            hitch.insert(string, index: index, precision: precision)
        } else {
            hitch.append(string, precision: precision)
        }
    }
}

public final class Hitch: CustomStringConvertible, ExpressibleByStringLiteral, Sequence, Comparable, Codable, Hashable {
    public static let empty = Hitch()

    @inlinable @inline(__always)
    public static func < (lhs: Hitch, rhs: Hitch) -> Bool {
        return chitch_cmp_raw(lhs.raw(), lhs.count, rhs.raw(), rhs.count) < 0
    }

    @inlinable @inline(__always)
    public static func < (lhs: String, rhs: Hitch) -> Bool {
        lhs.withCString { bytes in
            return chitch_cmp_raw(bytes, lhs.count, rhs.raw(), rhs.count) < 0
        }
    }

    @inlinable @inline(__always)
    public static func < (lhs: Hitch, rhs: String) -> Bool {
        rhs.withCString { bytes in
            return chitch_cmp_raw(lhs.raw(), lhs.count, bytes, rhs.count) < 0
        }
    }

    @inlinable @inline(__always)
    public static func == (lhs: Hitch, rhs: Hitch) -> Bool {
        if lhs === rhs {
            return true
        }
        return chitch_equal(&lhs.chitch, &rhs.chitch)
    }

    @inlinable @inline(__always)
    public static func == (lhs: String, rhs: Hitch) -> Bool {
        return lhs.withCString { bytes in
            return chitch_equal_raw(bytes, strlen(bytes), rhs.raw(), rhs.count)
        }
    }

    @inlinable @inline(__always)
    public static func == (lhs: Hitch, rhs: String) -> Bool {
        return rhs.withCString { bytes in
            return chitch_equal_raw(lhs.raw(), lhs.count, bytes, strlen(bytes))
        }
    }

    @inlinable @inline(__always)
    public func withBytes(_ callback: (UnsafeMutablePointer<Int8>) -> Void) {
        if let bytes = chitch.data {
            callback(bytes)
        }
    }

    @inlinable @inline(__always)
    public func raw() -> UnsafeMutablePointer<Int8>? {
        return chitch.data
    }

    @inlinable @inline(__always)
    public func using<T>(_ callback: (UnsafeMutablePointer<Int8>) -> T?) -> T? {
        if let raw = chitch.data {
            return callback(raw)
        }
        return nil
    }

    @inlinable @inline(__always)
    public subscript (index: Int) -> Int8 {
        get {
            if let data = chitch.data,
               index < chitch.count {
                return data[index]
            }
            return 0
        }
        set(newValue) {
            if let data = chitch.data,
               index < chitch.count {
                data[index] = newValue
            }
        }
    }

    @inlinable @inline(__always)
    public func hash(into hasher: inout Hasher) {
        if let data = chitch.data {
            hasher.combine(chitch.count)
            hasher.combine(bytes: UnsafeRawBufferPointer(start: data, count: Swift.min(chitch.count, 8)))
        } else {
            hasher.combine(0)
        }
    }

    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stringLiteral = try container.decode(String.self)
        self.init(stringLiteral: stringLiteral)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.description)
    }

    @usableFromInline
    var chitch: CHitch

    @inlinable @inline(__always)
    public var description: String {
        if let data = chitch.data {
            return String(bytesNoCopy: data, length: chitch.count, encoding: .utf8, freeWhenDone: false) ?? ""
        }
        return ""
    }

    @inlinable @inline(__always)
    public func toString() -> String {
        return String(data: dataNoCopy(), encoding: .utf8) ?? ""
    }

    deinit {
        chitch_dealloc(&chitch)
    }

    @inlinable @inline(__always)
    public func makeIterator() -> HitchIterator {
        return HitchIterator(hitch: self)
    }

    @inlinable @inline(__always)
    public func stride(from: Int, to: Int) -> HitchIterator {
        return HitchIterator(hitch: self, from: from, to: to)
    }

    required public init (stringLiteral: String) {
        chitch = chitch_empty()
        stringLiteral.withCString { (bytes: UnsafePointer<Int8>) -> Void in
            chitch = chitch_init_cstring(bytes)
        }
    }

    @inlinable @inline(__always)
    public init(hitch: Hitch) {
        chitch = chitch_init_raw(hitch.raw(), hitch.count, hitch.capacity)
    }

    @inlinable @inline(__always)
    public init(bytes: UnsafePointer<Int8>, offset: Int, count: Int) {
        chitch = chitch_init_raw(bytes + offset, count, count)
    }

    @inlinable @inline(__always)
    public init(bytes: UnsafeMutablePointer<Int8>, offset: Int, count: Int) {
        chitch = chitch_init_raw(bytes + offset, count, count)
    }

    @inlinable @inline(__always)
    public init(data: Data) {
        chitch = chitch_empty()
        data.withUnsafeBytes { unsafeRawBufferPointer in
            let unsafeBufferPointer = unsafeRawBufferPointer.bindMemory(to: Int8.self)
            guard let bytes = unsafeBufferPointer.baseAddress else { return }
            chitch = chitch_init_raw(bytes, data.count, data.count)
        }
    }

    @inlinable @inline(__always)
    public func dataNoCopy() -> Data {
        if let data = chitch.data {
            return Data(bytesNoCopy: data, count: count, deallocator: .none)
        }
        return Data()
    }

    @inlinable @inline(__always)
    public func dataCopy() -> Data {
        if let data = chitch.data {
            return Data(bytes: data, count: count)
        }
        return Data()
    }

    @inlinable @inline(__always)
    public func dataNoCopy(start inStart: Int = -1,
                           end inEnd: Int = -1) -> Data {
        if let data = chitch.data {

            let max = chitch.count
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

            return Data(bytesNoCopy: data + start, count: end - start, deallocator: .none)
        }
        return Data()
    }

    @inlinable @inline(__always)
    public func dataCopy(start inStart: Int,
                         end inEnd: Int) -> Data {
        if let data = chitch.data {

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
    public init(capacity: Int) {
        chitch = chitch_init_capacity(capacity)
    }

    @inlinable @inline(__always)
    public init() {
        chitch = chitch_init_capacity(0)
    }

    @usableFromInline
    internal init(chitch: CHitch) {
        self.chitch = chitch
    }

    @inlinable @inline(__always)
    public var count: Int {
        get {
            return chitch.count
        }
        set {
            chitch_resize(&chitch, newValue)
        }
    }

    @inlinable @inline(__always)
    public var capacity: Int {
        get {
            return chitch.capacity
        }
    }

    @inlinable @inline(__always)
    public func compare(other: Hitch) -> Int {
        return chitch_cmp(&chitch, &other.chitch)
    }

    @inlinable @inline(__always)
    public func clear() {
        chitch_resize(&chitch, 0)
    }

    @inlinable @inline(__always)
    public func release() {
        chitch_dealloc(&chitch)
        chitch = chitch_init_capacity(0)
    }

    @inlinable @inline(__always)
    public func replace(with string: String) {
        count = 0
        append(string)
    }

    @inlinable @inline(__always)
    public func replace(with hitch: Hitch) {
        count = 0
        append(hitch)
    }

    @inlinable @inline(__always)
    @discardableResult
    public func replace(occurencesOf hitch: Hitch, with: Hitch, ignoreCase: Bool = false) -> Self {
        chitch_replace(&chitch, &hitch.chitch, &with.chitch, ignoreCase)
        return self
    }

    @inlinable @inline(__always)
    @discardableResult
    public func reserveCapacity(_ newCapacity: Int) -> Self {
        if newCapacity > chitch.capacity {
            chitch_resize(&chitch, newCapacity)
        }
        return self
    }

    @inlinable @inline(__always)
    @discardableResult
    public func lowercase() -> Self {
        chitch_tolower(&chitch)
        return self
    }

    @inlinable @inline(__always)
    @discardableResult
    public func uppercase() -> Self {
        chitch_toupper(&chitch)
        return self
    }

    @inlinable @inline(__always)
    @discardableResult
    public func append(_ hitch: Hitch) -> Self {
        chitch_concat(&chitch, &hitch.chitch)
        return self
    }

    @inlinable @inline(__always)
    @discardableResult
    public func append(_ hitch: HalfHitch) -> Self {
        chitch_concat_raw(&chitch, hitch.source, hitch.count)
        return self
    }

    @inlinable @inline(__always)
    @discardableResult
    public func append(_ string: String) -> Self {
        string.withCString { (bytes: UnsafePointer<Int8>) -> Void in
            chitch_concat_cstring(&chitch, bytes)
        }
        return self
    }

    @inlinable @inline(__always)
    @discardableResult
    public func append(_ string: String, precision: Int?) -> Self {
        string.withCString { (bytes: UnsafePointer<Int8>) -> Void in
            var length = string.count
            if let precision = precision {
                var ptr = bytes
                while ptr.pointee != 0 {
                    let c = Int8(ptr.pointee)
                    if c == .dot {
                        length = Swift.min(length, ptr - bytes + precision + 1)
                        break
                    }
                    ptr += 1
                }
            }

            chitch_concat_raw(&chitch, bytes, length)
        }
        return self
    }

    @inlinable @inline(__always)
    @discardableResult
    public func append(_ char: Int8) -> Self {
        chitch_concat_char(&chitch, char)
        return self
    }

    @inlinable @inline(__always)
    @discardableResult
    public func append<T: FixedWidthInteger>(number: T) -> Self {
        return insert(number: number, index: count)
    }

    @inlinable @inline(__always)
    @discardableResult
    public func append(double: Double, precision: Int? = nil) -> Self {
        var output = HitchOutputStream(hitch: self, precision: precision)
        double.write(to: &output)
        return self
    }

    @inlinable @inline(__always)
    @discardableResult
    public func append(_ data: Data) -> Self {
        data.withUnsafeBytes { unsafeRawBufferPointer in
            let unsafeBufferPointer = unsafeRawBufferPointer.bindMemory(to: Int8.self)
            guard let bytes = unsafeBufferPointer.baseAddress else { return }
            chitch_concat_raw(&chitch, bytes, data.count)
        }
        return self
    }

    @inlinable @inline(__always)
    @discardableResult
    public func insert(_ hitch: Hitch, index: Int) -> Self {
        chitch_insert_raw(&chitch, index, hitch.raw(), hitch.count)
        return self
    }

    @inlinable @inline(__always)
    @discardableResult
    public func insert(_ string: String, index: Int) -> Self {
        chitch_insert_cstring(&chitch, index, string)
        return self
    }

    @inlinable @inline(__always)
    @discardableResult
    public func insert(_ string: String, index: Int, precision: Int?) -> Self {
        return string.withCString { bytes in

            var length = string.count
            if let precision = precision {
                var ptr = bytes
                while ptr.pointee != 0 {
                    let c = Int8(ptr.pointee)
                    if c == .dot {
                        length = Swift.min(length, ptr - bytes + precision + 1)
                        break
                    }
                    ptr += 1
                }
            }

            chitch_insert_cstring(&chitch, index, bytes)
            return self
        }
    }

    @inlinable @inline(__always)
    @discardableResult
    public func insert(_ char: Int8, index: Int) -> Self {
        chitch_insert_char(&chitch, index, char)
        return self
    }

    @inlinable @inline(__always)
    @discardableResult
    public func insert<T: FixedWidthInteger>(number: T, index: Int) -> Self {
        chitch_insert_int(&chitch, index, Int(number))
        return self
    }

    @inlinable @inline(__always)
    @discardableResult
    public func insert(double: Double, index: Int, precision: Int? = nil) -> Self {
        var output = HitchOutputStream(hitch: self, index: index, precision: precision)
        double.write(to: &output)
        return self
    }

    @inlinable @inline(__always)
    @discardableResult
    public func insert(_ data: Data, index: Int) -> Self {
        data.withUnsafeBytes { unsafeRawBufferPointer in
            let unsafeBufferPointer = unsafeRawBufferPointer.bindMemory(to: Int8.self)
            guard let bytes = unsafeBufferPointer.baseAddress else { return }
            chitch_insert_raw(&chitch, index, bytes, data.count)
        }
        return self
    }

    @inlinable @inline(__always)
    @discardableResult
    public func trim() -> Self {
        chitch_trim(&chitch)
        return self
    }

    @inlinable @inline(__always)
    @discardableResult
    public func starts(with hitch: Hitch) -> Bool {
        guard chitch.count > hitch.count else { return false }
        return chitch_equal_raw(raw(), hitch.count, hitch.raw(), hitch.count)
    }

    @inlinable @inline(__always)
    @discardableResult
    public func starts(with string: String) -> Bool {
        return string.withCString { bytes in
            let bytes_count = strlen(bytes)
            guard chitch.count > string.count else { return false }
            return chitch_equal_raw(raw(), bytes_count, bytes, bytes_count)
        }
    }

    @inlinable @inline(__always)
    @discardableResult
    public func contains(_ hitch: Hitch) -> Bool {
        return chitch_contains_raw(raw(), count, hitch.raw(), hitch.count)
    }

    @inlinable @inline(__always)
    @discardableResult
    public func contains(_ halfHitch: HalfHitch) -> Bool {
        return chitch_contains_raw(raw(), count, halfHitch.source, halfHitch.count)
    }

    @inlinable @inline(__always)
    @discardableResult
    public func contains(_ string: String) -> Bool {
        return string.withCString { bytes in
            let bytes_count = strlen(bytes)
            return chitch_contains_raw(raw(), count, bytes, bytes_count)
        }
    }

    @inlinable @inline(__always)
    @discardableResult
    public func contains(char: Int8) -> Bool {
        var local = char
        return chitch_contains_raw(raw(), count, &local, 1)
    }

    @inlinable @inline(__always)
    @discardableResult
    public func firstIndex(of hitch: Hitch, offset: Int = 0) -> Int? {
        let index = chitch_firstof_raw(raw(), count, hitch.raw(), hitch.count)
        return index >= 0 ? index : nil
    }

    @inlinable @inline(__always)
    @discardableResult
    public func firstIndex(of string: String, offset: Int = 0) -> Int? {
        return string.withCString { bytes in
            let bytes_count = strlen(bytes)
            let index = chitch_firstof_raw(raw(), count, bytes, bytes_count)
            return index >= 0 ? index : nil
        }
    }

    @inlinable @inline(__always)
    @discardableResult
    public func firstIndex(of char: Int8, offset: Int = 0) -> Int? {
        var local = char
        let index = chitch_firstof_raw(raw(), count, &local, 1)
        return index >= 0 ? index : nil
    }

    @inlinable @inline(__always)
    @discardableResult
    public func lastIndex(of hitch: Hitch) -> Int? {
        let index = chitch_lastof_raw(raw(), count, hitch.raw(), hitch.count)
        return index >= 0 ? index : nil
    }

    @inlinable @inline(__always)
    @discardableResult
    public func lastIndex(of string: String) -> Int? {
        return string.withCString { bytes in
            let bytes_count = strlen(bytes)
            let index = chitch_lastof_raw(raw(), count, bytes, bytes_count)
            return index >= 0 ? index : nil
        }
    }

    @inlinable @inline(__always)
    @discardableResult
    public func lastIndex(of char: Int8) -> Int? {
        var local = char
        let index = chitch_lastof_raw(raw(), count, &local, 1)
        return index >= 0 ? index : nil
    }

    @inlinable @inline(__always)
    @discardableResult
    public func substring(_ lhsPos: Int, _ rhsPos: Int) -> Hitch? {
        guard lhsPos >= 0 && lhsPos <= count else { return nil }
        guard rhsPos >= 0 && rhsPos <= count else { return nil }
        guard lhsPos <= rhsPos else { return nil }
        return Hitch(chitch: chitch_init_substring(&chitch, lhsPos, rhsPos))
    }

    @inlinable @inline(__always)
    @discardableResult
    public func halfhitch(_ lhsPos: Int, _ rhsPos: Int) -> HalfHitch {
        guard lhsPos >= 0 && lhsPos <= count else { return HalfHitch() }
        guard rhsPos >= 0 && rhsPos <= count else { return HalfHitch() }
        guard lhsPos <= rhsPos else { return HalfHitch() }
        return HalfHitch(source: self, from: lhsPos, to: rhsPos)
    }

    @inlinable @inline(__always)
    @discardableResult
    public func halfhitch() -> HalfHitch {
        return HalfHitch(source: self, from: 0, to: count)
    }

    @inlinable @inline(__always)
    public func canEscape(unicode: Bool,
                          singleQuotes: Bool) -> Bool {
        for char in self {
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
        }
        return false
    }

    @inlinable @inline(__always)
    public func escaped(unicode: Bool,
                        singleQuotes: Bool) -> Hitch {
        guard let raw = raw() else { return self }
        return escapeBinary(data: raw,
                            count: count,
                            unicode: unicode,
                            singleQuotes: singleQuotes)
    }

    @inlinable @inline(__always)
    @discardableResult
    public func unescape() -> Hitch {
        guard let raw = raw() else { return self }
        count = unescapeBinary(data: raw,
                               count: count)
        return self
    }

    @inlinable @inline(__always)
    @discardableResult
    public func extract(_ lhs: Hitch, _ rhs: Hitch) -> Hitch? {
        guard let lhsPos = firstIndex(of: lhs) else { return nil }
        guard let rhsPos = firstIndex(of: rhs, offset: lhsPos) else {
            return substring(lhsPos, count)
        }
        return substring(lhsPos, rhsPos)
    }

    @inlinable @inline(__always)
    @discardableResult
    public func extract(_ lhs: String, _ rhs: String) -> Hitch? {
        return extract(lhs.hitch(), rhs.hitch())
    }

    @inlinable @inline(__always)
    @discardableResult
    public func extract(_ lhs: Hitch, _ rhs: String) -> Hitch? {
        return extract(lhs, rhs.hitch())
    }

    @inlinable @inline(__always)
    @discardableResult
    public func extract(_ lhs: String, _ rhs: Hitch) -> Hitch? {
        return extract(lhs.hitch(), rhs)
    }

    @inlinable @inline(__always)
    @discardableResult
    public func toInt(fuzzy: Bool = false) -> Int? {
        if let data = chitch.data {
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
    public func toDouble(fuzzy: Bool = false) -> Double? {
        if let data = chitch.data {
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
    public func toEpoch() -> Int {
        return chitch_toepoch(&chitch)
    }
}
