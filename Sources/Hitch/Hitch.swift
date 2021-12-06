// swiftlint:disable type_body_length

import Foundation
import bstrlib

func roundToPlaces(value: Double, places: Int) -> Double {
    let divisor = pow(10.0, Double(places))
    return round(value * divisor) / divisor
}

func intFromBinary(data: UnsafeRawBufferPointer,
                   count: Int) -> Int? {
    var value = 0
    var isNegative = false
    var endedOnlyAllowsWhitespace = false
    var idx = 0

    var skipping = true
    while skipping && idx < count {
        let char = data[idx]
        switch char {
        case UInt8.zero, UInt8.one, UInt8.two, UInt8.three, UInt8.four, UInt8.five, UInt8.six, UInt8.seven, UInt8.eight, UInt8.nine, UInt8.minus:
            skipping = false
            break
        default:
            idx += 1
            break
        }
    }

    while idx < count {
        let char = data[idx]
        if endedOnlyAllowsWhitespace == true {
            switch char {
            case UInt8.space, UInt8.tab, UInt8.newLine, UInt8.carriageReturn:
                break
            default:
                return nil
            }
        } else if char == .minus && value == 0 {
            isNegative = true
        } else if char >= .zero && char <= .nine {
            value = (value * 10) &+ Int(char - .zero)
        } else {
            endedOnlyAllowsWhitespace = true
        }
        idx += 1
    }
    if isNegative {
        value = -1 * value
    }
    return value
}

func doubleFromBinary(data: UnsafeRawBufferPointer,
                      count: Int) -> Double? {
    var value: Double = 0

    var isNegative = false
    var endedOnlyAllowsWhitespace = false
    var idx = 0

    // skip leading whitespace
    while idx < count {
        let char = data[idx]
        if char == UInt8.space || char == UInt8.tab || char == UInt8.newLine || char == UInt8.carriageReturn {
            idx += 1
        } else {
            break
        }
    }

    // part before the period
    while idx < count {
        let char = data[idx]
        if endedOnlyAllowsWhitespace == true {
            if char != UInt8.space && char != UInt8.tab && char != UInt8.newLine && char != UInt8.carriageReturn {
                return nil
            }
        } else if char == .minus && value == 0 {
            isNegative = true
        } else if char >= .zero && char <= .nine {
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
                if char != UInt8.space && char != UInt8.tab && char != UInt8.newLine && char != UInt8.carriageReturn {
                    return nil
                }
            } else if char >= .zero && char <= .nine {
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

    if isNegative {
        value = -1 * value
    }
    return value
}

private func hex(_ v: UInt8) -> UInt32? {
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

private func hex2(_ v: UInt32) -> UInt8 {
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

public let nullptr = UnsafeMutablePointer<UInt8>(bitPattern: 0)!

public extension String {
    func hitch() -> Hitch {
        return Hitch(stringLiteral: self)
    }
}

public struct HitchIterator: IteratorProtocol {
    @usableFromInline
    internal var ptr: UnsafeMutablePointer<UInt8>
    @usableFromInline
    internal let end: UnsafeMutablePointer<UInt8>

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
    public mutating func next() -> UInt8? {
        if ptr >= end { return nil }
        ptr += 1
        return ptr.pointee
    }
}

public final class Hitch: CustomStringConvertible, ExpressibleByStringLiteral, Sequence, Comparable, Codable, Hashable {
    public static func < (lhs: Hitch, rhs: Hitch) -> Bool {
        return bstrcmp(lhs.bstr, rhs.bstr) < 0
    }

    public static func < (lhs: String, rhs: Hitch) -> Bool {
        let hitch = lhs.hitch()
        return bstrcmp(hitch.bstr, rhs.bstr) < 0
    }

    public static func < (lhs: Hitch, rhs: String) -> Bool {
        let hitch = rhs.hitch()
        return bstrcmp(lhs.bstr, hitch.bstr) < 0
    }

    public static func == (lhs: Hitch, rhs: Hitch) -> Bool {
        if lhs === rhs {
            return true
        }
        return biseq(lhs.bstr, rhs.bstr) == 1
    }

    public static func == (lhs: String, rhs: Hitch) -> Bool {
        let hitch = lhs.hitch()
        return biseq(hitch.bstr, rhs.bstr) == 1
    }

    public static func == (lhs: Hitch, rhs: String) -> Bool {
        let hitch = rhs.hitch()
        return biseq(lhs.bstr, hitch.bstr) == 1
    }

    public func withBytes(_ callback: (UnsafeMutablePointer<UInt8>) -> Void) {
        if let bstr = bstr,
            let data = bstr.pointee.data {
            callback(data)
        }
    }

    public func raw() -> UnsafeMutablePointer<UInt8>? {
        return bstr?.pointee.data
    }

    public subscript (index: Int) -> UInt8 {
        get {
            if let bstr = bstr,
                let data = bstr.pointee.data,
                index < bstr.pointee.slen {
                return data[index]
            }
            return 0
        }
        set(newValue) {
            if let bstr = bstr,
                let data = bstr.pointee.data,
                index < bstr.pointee.slen {
                data[index] = newValue
            }
        }
    }

    public func hash(into hasher: inout Hasher) {
        if let bstr = bstr,
            let data = bstr.pointee.data {
            hasher.combine(bytes: UnsafeRawBufferPointer(start: data, count: Int(bstr.pointee.slen)))
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

    private var bstr: bstring?

    public var description: String {
        if let bstr = bstr,
            let data = bstr.pointee.data {
            return String(bytesNoCopy: data, length: Int(bstr.pointee.slen), encoding: .utf8, freeWhenDone: false) ?? ""
        }
        return ""
    }

    deinit {
        bdestroy(bstr)
    }

    public func makeIterator() -> HitchIterator {
       return HitchIterator(hitch: self)
    }

    required public init (stringLiteral: String) {
        stringLiteral.withCString { (bytes: UnsafePointer<Int8>) -> Void in
            self.bstr = bfromcstr(bytes)
        }
    }

    public init(hitch: Hitch) {
        if let other = hitch.bstr,
            let data = other.pointee.data {
            bstr = blk2bstr(data, Int32(other.pointee.slen))
        }
    }

    public init(data: Data) {
        data.withUnsafeBytes { bytes in
            bstr = blk2bstr(bytes, Int32(data.count))
        }
    }

    public func dataNoCopy() -> Data {
        if let bstr = bstr,
            let data = bstr.pointee.data {
            return Data(bytesNoCopy: data, count: Int(bstr.pointee.slen), deallocator: .none)
        }
        return Data()
    }

    public func dataCopy() -> Data {
        if let bstr = bstr,
            let data = bstr.pointee.data {
            return Data(bytes: data, count: Int(bstr.pointee.slen))
        }
        return Data()
    }

    public func dataNoCopy(start inStart: Int = -1,
                           end inEnd: Int = -1) -> Data {
        if let bstr = bstr,
            let data = bstr.pointee.data {

            let max = Int(bstr.pointee.slen)
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

    public func dataCopy(start inStart: Int,
                         end inEnd: Int) -> Data {
        if let bstr = bstr,
            let data = bstr.pointee.data {

            let max = Int(bstr.pointee.slen)
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

    public init(capacity: Int) {
        bstr = bempty()
        reserveCapacity(capacity)
    }

    public init() {
        bstr = bempty()
    }

    // @usableFromInline
    internal init(bstr: bstring) {
        self.bstr = bstr
    }

    public var count: Int {
        get {
            return Int(bstr?.pointee.slen ?? 0)
        }
        set {
            btrunc(bstr, Int32(newValue))
        }
    }

    public func compare(other: Hitch) -> Int {
        return Int(bstrcmp(bstr, other.bstr))
    }

    public func clear() {
        bdestroy(bstr)
        bstr = bempty()
    }

    public func replace(with string: String) {
        bdestroy(bstr)
        string.withCString { (bytes: UnsafePointer<Int8>) -> Void in
            self.bstr = bfromcstr(bytes)
        }
    }

    public func replace(with hitch: Hitch) {
        bdestroy(bstr)
        self.bstr = bstrcpy(hitch.bstr)
    }

    @discardableResult
    public func reserveCapacity(_ newCapacity: Int) -> Self {
        balloc(bstr, Int32(newCapacity))
        return self
    }

    @discardableResult
    public func lowercase() -> Self {
        btolower(bstr)
        return self
    }

    @discardableResult
    public func uppercase() -> Self {
        btoupper(bstr)
        return self
    }

    @discardableResult
    public func append(_ hitch: Hitch) -> Self {
        bconcat(bstr, hitch.bstr)
        return self
    }

    @discardableResult
    public func append(_ string: String) -> Self {
        let hitch = string.hitch()
        bconcat(bstr, hitch.bstr)
        return self
    }

    @discardableResult
    public func append<T: FixedWidthInteger>(_ char: T) -> Self {
        bconchar(bstr, UInt8(clamping: char))
        return self
    }

    @discardableResult
    public func append<T: FixedWidthInteger>(number: T) -> Self {
        return insert(number: number, index: count)
    }

    @discardableResult
    public func append(_ data: Data) -> Self {
        data.withUnsafeBytes { bytes in
            bcatblk(bstr, bytes, Int32(data.count))
        }
        return self
    }

    @discardableResult
    public func insert(_ hitch: Hitch, index: Int) -> Self {
        let position = Swift.max(Swift.min(index, 0), count)
        binsert(bstr, Int32(position), hitch.bstr, .space)
        return self
    }

    @discardableResult
    public func insert(_ string: String, index: Int) -> Self {
        let hitch = string.hitch()
        let position = Swift.max(Swift.min(index, 0), count)
        binsert(bstr, Int32(position), hitch.bstr, .space)
        return self
    }

    @discardableResult
    public func insert<T: FixedWidthInteger>(_ char: T, index: Int) -> Self {
        let position = Swift.max(Swift.min(index, count), 0)
        binsertch(bstr, Int32(position), 1, UInt8(clamping: char))
        return self
    }

    @discardableResult
    public func insert<T: FixedWidthInteger>(number: T, index: Int) -> Self {
        if number == 0 {
            insert(UInt8.zero, index: index)
        } else {
            let isNegative = number < 0

            var value = isNegative ? -1 * number : number
            while value > 0 {
                let digit = value % 10
                value /= 10
                insert(.zero + UInt8(digit), index: index)
            }

            if isNegative {
                insert(UInt8.minus, index: index)
            }
        }
        return self
    }

    @discardableResult
    public func insert(_ data: Data, index: Int) -> Self {
        let position = Swift.max(Swift.min(index, 0), count)
        data.withUnsafeBytes { bytes in
            binsertblk(bstr, Int32(position), bytes, Int32(data.count), .space)
        }
        return self
    }

    public func trim() {
        btrimws(bstr)
    }

    @discardableResult
    public func starts(with hitch: Hitch) -> Bool {
        return bstrncmp(bstr, hitch.bstr, Int32(hitch.count)) == BSTR_OK
    }

    @discardableResult
    public func starts(with string: String) -> Bool {
        let hitch = string.hitch()
        return bstrncmp(bstr, hitch.bstr, Int32(hitch.count)) == BSTR_OK
    }

    @discardableResult
    public func contains(_ hitch: Hitch) -> Bool {
        return binstr(bstr, 0, hitch.bstr) != BSTR_ERR
    }

    @discardableResult
    public func contains(_ string: String) -> Bool {
        let hitch = string.hitch()
        return binstr(bstr, 0, hitch.bstr) != BSTR_ERR
    }

    @discardableResult
    public func contains<T: FixedWidthInteger>(_ char: T) -> Bool {
        return bstrchrp(bstr, Int32(char), 0) != BSTR_ERR
    }

    @discardableResult
    public func firstIndex(of hitch: Hitch) -> Int? {
        let index = binstr(bstr, 0, hitch.bstr)
        return index != BSTR_ERR ? Int(index) : nil
    }

    @discardableResult
    public func firstIndex(of string: String) -> Int? {
        let hitch = string.hitch()
        let index = binstr(bstr, 0, hitch.bstr)
        return index != BSTR_ERR ? Int(index) : nil
    }

    @discardableResult
    public func firstIndex<T: FixedWidthInteger>(of char: T) -> Int? {
        let index = bstrchrp(bstr, Int32(char), 0)
        return index != BSTR_ERR ? Int(index) : nil
    }

    @discardableResult
    public func lastIndex(of hitch: Hitch) -> Int? {
        let index = binstrr(bstr, Int32(count-1), hitch.bstr)
        return index != BSTR_ERR ? Int(index) : nil
    }

    @discardableResult
    public func lastIndex(of string: String) -> Int? {
        let hitch = string.hitch()
        let index = binstrr(bstr, Int32(count-1), hitch.bstr)
        return index != BSTR_ERR ? Int(index) : nil
    }

    @discardableResult
    public func lastIndex<T: FixedWidthInteger>(of char: T) -> Int? {
        let index = bstrrchrp(bstr, Int32(char), Int32(count-1))
        return index != BSTR_ERR ? Int(index) : nil
    }

    @discardableResult
    public func substring(_ lhsPos: Int, _ rhsPos: Int) -> Hitch? {
        guard lhsPos >= 0 && lhsPos <= count else { return nil }
        guard rhsPos >= 0 && rhsPos <= count else { return nil }
        guard lhsPos < rhsPos else { return nil }
        return Hitch(bstr: bmidstr(bstr, Int32(lhsPos), Int32(rhsPos - lhsPos)))
    }

    public func escape(escapeSingleQuote: Bool = false) {
        guard let raw = raw() else { return }

        let writer = Hitch(capacity: count)

        // TODO: handle \u for unicode
        var read = raw
        let end = raw + count

        while read < end {
            let ch = read.pointee

            if ch > 0x7f {
                writer.append(UInt8.backSlash)
                writer.append(UInt8.u)

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
                    writer.append(UInt8.openBracket)
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
                    writer.append(UInt8.closeBracket)
                }

            } else {
                switch ch {
                case .bell:
                    writer.append(UInt8.backSlash)
                    writer.append(UInt8.b)
                case .newLine:
                    writer.append(UInt8.backSlash)
                    writer.append(UInt8.n)
                case .tab:
                    writer.append(UInt8.backSlash)
                    writer.append(UInt8.t)
                case .formFeed:
                    writer.append(UInt8.backSlash)
                    writer.append(UInt8.f)
                case .carriageReturn:
                    writer.append(UInt8.backSlash)
                    writer.append(UInt8.r)
                case .singleQuote:
                    if escapeSingleQuote {
                        writer.append(UInt8.backSlash)
                    }
                    writer.append(UInt8.singleQuote)
                case .doubleQuote:
                    writer.append(UInt8.backSlash)
                    writer.append(UInt8.doubleQuote)
                case .backSlash:
                    writer.append(UInt8.backSlash)
                    writer.append(UInt8.backSlash)
                case .forwardSlash:
                    writer.append(UInt8.backSlash)
                    writer.append(UInt8.forwardSlash)
                default:
                    writer.append(ch)
                }
            }

            read += 1
        }

        self.replace(with: writer)
    }

    public func unescape() {
        guard let raw = raw() else { return }

        var read = raw
        var write = raw
        let end = raw + count

        let append: (UInt8, Int) -> Void = { v, advance in
            write.pointee = v
            write += 1
            read += advance
        }

        while read < end {

            if read.pointee == UInt8.backSlash {
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

        count = (write - raw)
    }

    @discardableResult
    public func extract(_ lhs: Hitch, _ rhs: Hitch) -> Hitch? {
        guard let bstr = bstr else { return nil }
        var lhsPos = binstr(bstr, 0, lhs.bstr)
        guard lhsPos != BSTR_ERR else { return nil }

        lhsPos += Int32(lhs.count)
        let rhsPos = binstr(bstr, lhsPos, rhs.bstr)
        guard rhsPos != BSTR_ERR else { return Hitch(bstr: bmidstr(bstr, lhsPos, bstr.pointee.slen)) }
        return Hitch(bstr: bmidstr(bstr, lhsPos, (rhsPos - lhsPos)))
    }

    @discardableResult
    public func extract(_ lhs: String, _ rhs: String) -> Hitch? {
        return extract(lhs.hitch(), rhs.hitch())
    }

    @discardableResult
    public func extract(_ lhs: Hitch, _ rhs: String) -> Hitch? {
        return extract(lhs, rhs.hitch())
    }

    @discardableResult
    public func extract(_ lhs: String, _ rhs: Hitch) -> Hitch? {
        return extract(lhs.hitch(), rhs)
    }

    @discardableResult
    public func toInt() -> Int? {
        if let bstr = bstr,
            let data = bstr.pointee.data {
            let count = Int(bstr.pointee.slen)
            return intFromBinary(data: UnsafeRawBufferPointer(start: data, count: count),
                                 count: count)
        }
        return nil
    }

    @discardableResult
    public func toDouble() -> Double? {
        if let bstr = bstr,
            let data = bstr.pointee.data {
            let count = Int(bstr.pointee.slen)
            return doubleFromBinary(data: UnsafeRawBufferPointer(start: data, count: count),
                                    count: count)
        }
        return nil
    }

    @discardableResult
    public func toEpoch() -> Int {
        return Int(btoepoch(bstr))
    }
}
