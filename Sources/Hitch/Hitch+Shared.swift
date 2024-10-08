import Foundation

infix operator ~==

// swiftlint:disable type_body_length

@inlinable
func replaceDanglingControlChars(start: UnsafeMutablePointer<UInt8>,
                                 end: UnsafeMutablePointer<UInt8>) {
    // Run back over the data and raplace odd control characters with spaces
    var ptr = start
    
    let isControlChar: (UInt8) -> Bool = { ascii in
        switch ascii {
        case 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x0B, 0x0C, 0x0E,
            0x0F, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1A,
            0x1B, 0x1C, 0x1D, 0x1E, 0x1F, 0x7F, 0x80, 0x81, 0x82, 0x83, 0x84, 0x85,
            0x86, 0x87, 0x88, 0x89, 0x8A, 0x8B, 0x8C, 0x8D, 0x8E, 0x8F, 0x90, 0x91,
            0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9A, 0x9B, 0x9C, 0x9D,
            0x9E, 0x9F, 0xAD:
            return true
        default:
            return false
        }
    }
    
    while ptr < end {
        // skip over utf8 code points
        let ch = ptr[0]
        if ch > 0x7f {
            var value: UInt32 = 0
            if ch & 0b11100000 == 0b11000000 {
                value |= (UInt32(ptr[0]) & 0b00011111) << 6
                value |= (UInt32(ptr[1]) & 0b00111111) << 0
                if let ascii = UInt8(exactly: value),
                   isControlChar(ascii) {
                    ptr[0] = .space
                    ptr[1] = .space
                }
                ptr += 1
            } else if ch & 0b11110000 == 0b11100000 {
                value |= (UInt32(ptr[0]) & 0b00001111) << 12
                value |= (UInt32(ptr[1]) & 0b00111111) << 6
                value |= (UInt32(ptr[2]) & 0b00111111) << 0
                if let ascii = UInt8(exactly: value),
                   isControlChar(ascii) {
                    ptr[0] = .space
                    ptr[1] = .space
                    ptr[2] = .space
                }
                ptr += 2
            } else if ch & 0b11111000 == 0b11110000 {
                value |= (UInt32(ptr[0]) & 0b00000111) << 18
                value |= (UInt32(ptr[1]) & 0b00111111) << 12
                value |= (UInt32(ptr[2]) & 0b00111111) << 6
                value |= (UInt32(ptr[3]) & 0b00111111) << 0
                if let ascii = UInt8(exactly: value),
                   isControlChar(ascii) {
                    ptr[0] = .space
                    ptr[1] = .space
                    ptr[2] = .space
                    ptr[3] = .space
                }
                ptr += 3
            }
        } else {
            // control character which is not part of a utf8 code point; fix it.
            if isControlChar(ptr[0]) {
                ptr[0] = .space
            }
        }
        
        ptr += 1
    }
}

@inlinable
func reduceToPrintableAscii(start: UnsafeMutablePointer<UInt8>,
                            end: UnsafeMutablePointer<UInt8>) -> Int {
    // Run back over the data and raplace odd control characters with spaces
    var ptr = start
    var writePtr = start
    
    let isAscii: (UInt8) -> Bool = { ascii in
        return ascii >= 32 && ascii <= 126
    }
    
    while ptr < end {
        // skip over utf8 code points
        let ch = ptr[0]
        if ch > 0x7f {
            var value: UInt32 = 0
            if ch & 0b11100000 == 0b11000000 {
                value |= (UInt32(ptr[0]) & 0b00011111) << 6
                value |= (UInt32(ptr[1]) & 0b00111111) << 0
                if let ascii = UInt8(exactly: value),
                   isAscii(ascii) == true {
                    writePtr[0] = ascii
                    writePtr += 1
                }
                ptr += 1
            } else if ch & 0b11110000 == 0b11100000 {
                value |= (UInt32(ptr[0]) & 0b00001111) << 12
                value |= (UInt32(ptr[1]) & 0b00111111) << 6
                value |= (UInt32(ptr[2]) & 0b00111111) << 0
                if let ascii = UInt8(exactly: value),
                   isAscii(ascii) == true {
                    writePtr[0] = ascii
                    writePtr += 1
                }
                ptr += 2
            } else if ch & 0b11111000 == 0b11110000 {
                value |= (UInt32(ptr[0]) & 0b00000111) << 18
                value |= (UInt32(ptr[1]) & 0b00111111) << 12
                value |= (UInt32(ptr[2]) & 0b00111111) << 6
                value |= (UInt32(ptr[3]) & 0b00111111) << 0
                if let ascii = UInt8(exactly: value),
                   isAscii(ascii) == true {
                    writePtr[0] = ascii
                    writePtr += 1
                }
                ptr += 3
            }
        } else {
            // control character which is not part of a utf8 code point; fix it.
            if isAscii(ptr[0]) {
                writePtr[0] = ptr[0]
                writePtr += 1
            }
        }
        
        ptr += 1
    }
    
    return writePtr - start
}

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
    @inlinable
    func raw() -> UnsafePointer<UInt8>?

    @inlinable
    func mutableRaw() -> UnsafeMutablePointer<UInt8>?

    @inlinable
    var count: Int { get }

    @inlinable
    func using<T>(_ block: (UnsafePointer<UInt8>?, Int) -> T?) -> T?
    
    @inlinable
    func mutableUsing<T>(_ block: (UnsafeMutablePointer<UInt8>?, Int) -> T?) -> T?
    
    @inlinable
    func getSourceObject() -> Any?
}

public struct HitchableIterator: Sequence, IteratorProtocol {
    @usableFromInline
    internal var ptr: UnsafePointer<UInt8> = nullptr
    @usableFromInline
    internal var end: UnsafePointer<UInt8> = nullptr
    
    public init() { }

    @inlinable
    public mutating func next() -> UInt8? {
        if ptr >= end { return nil }
        ptr += 1
        return ptr[0]
    }
}

typealias HitchArray = [Hitch]
extension HitchArray {
    @inlinable
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
    @inlinable
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
    
    @inlinable
    var first: UInt8 {
        guard count > 0 else { return 0 }
        return self[0]
    }
    
    @inlinable
    var last: UInt8 {
        guard count > 0 else { return 0 }
        return self[count-1]
    }

    @inlinable
    func toTempString() -> String {
        if let raw = raw() {
            return String(bytesNoCopy: UnsafeMutableRawPointer(mutating: raw), length: count, encoding: .utf8, freeWhenDone: false) ??
            String(bytesNoCopy: UnsafeMutableRawPointer(mutating: raw), length: count, encoding: .ascii, freeWhenDone: false) ??
            String(bytesNoCopy: UnsafeMutableRawPointer(mutating: raw), length: count, encoding: .isoLatin1, freeWhenDone: false) ??
            String(bytesNoCopy: UnsafeMutableRawPointer(mutating: raw), length: count, encoding: .nonLossyASCII, freeWhenDone: false) ??
            ""
        }
        if let raw = mutableRaw() {
            return String(bytesNoCopy: UnsafeMutableRawPointer(mutating: raw), length: count, encoding: .utf8, freeWhenDone: false) ??
            String(bytesNoCopy: UnsafeMutableRawPointer(mutating: raw), length: count, encoding: .ascii, freeWhenDone: false) ??
            String(bytesNoCopy: UnsafeMutableRawPointer(mutating: raw), length: count, encoding: .isoLatin1, freeWhenDone: false) ??
            String(bytesNoCopy: UnsafeMutableRawPointer(mutating: raw), length: count, encoding: .nonLossyASCII, freeWhenDone: false) ??
            ""
        }
        return ""
    }

    @inlinable
    func toString() -> String {
        if let raw = raw() {
            return String(data: Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: raw), count: count, deallocator: .none), encoding: .utf8) ??
            String(data: Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: raw), count: count, deallocator: .none), encoding: .ascii) ??
            String(data: Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: raw), count: count, deallocator: .none), encoding: .isoLatin1) ??
            String(data: Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: raw), count: count, deallocator: .none), encoding: .nonLossyASCII) ??
            ""
        }
        if let raw = mutableRaw() {
            return String(data: Data(bytesNoCopy: raw, count: count, deallocator: .none), encoding: .utf8) ??
            String(data: Data(bytesNoCopy: raw, count: count, deallocator: .none), encoding: .ascii) ??
            String(data: Data(bytesNoCopy: raw, count: count, deallocator: .none), encoding: .isoLatin1) ??
            String(data: Data(bytesNoCopy: raw, count: count, deallocator: .none), encoding: .nonLossyASCII) ??
            ""
        }
        return ""
    }

    @inlinable
    func using<T>(_ block: (UnsafePointer<UInt8>?, Int) -> T?) -> T? {
        if let raw = raw() {
            return block(raw, count)
        }
        return nil
    }
    
    @inlinable
    func mutableUsing<T>(_ block: (UnsafeMutablePointer<UInt8>?, Int) -> T?) -> T? {
        if let raw = mutableRaw() {
            return block(raw, count)
        }
        return nil
    }

    @inlinable
    static func < (lhs: Self, rhs: Self) -> Bool {
        return chitch_cmp_raw(lhs.raw(), lhs.count, rhs.raw(), rhs.count) < 0
    }

    @inlinable
    static func == (lhs: Self, rhs: Self) -> Bool {
        return chitch_equal_raw(lhs.raw(), lhs.count, rhs.raw(), rhs.count)
    }
    
    @inlinable
    static func ~== (lhs: Self, rhs: Self) -> Bool {
        return chitch_equal_caseless_raw(lhs.raw(), lhs.count, rhs.raw(), rhs.count)
    }

    @inlinable
    func using<T>(_ callback: (UnsafePointer<UInt8>) -> T?) -> T? {
        if let raw = raw() {
            return callback(raw)
        }
        return nil
    }

    @inlinable
    subscript (index: Int) -> UInt8 {
        get {
            guard let raw = raw() else { return 0 }
            guard index >= 0 && index < count else { return 0 }
            return raw[index]
        }
    }

    @inlinable
    func makeIterator() -> HitchableIterator {
        var iterator = HitchableIterator()
        if let data = raw() {
            iterator.ptr = data - 1
            iterator.end = data + count - 1
        }
        return iterator
    }

    @inlinable
    func stride(from: Int, to: Int) -> HitchableIterator {
        var iterator = HitchableIterator()
        if let data = raw() {
            iterator.ptr = data + from - 1
            iterator.end = data + to - 1
        }
        return iterator
    }
    
    @inlinable
    func md5() -> Hitch? {
        if let raw = raw() {
            return hex_md5(raw: raw, count: count)
        }
        if let raw = mutableRaw() {
            return hex_md5(raw: raw, count: count)
        }
        return nil
    }

    @inlinable
    func dataNoCopy() -> Data {
        if let raw = raw() {
            return Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: raw), count: count, deallocator: .none)
        }
        if let raw = mutableRaw() {
            return Data(bytesNoCopy: raw, count: count, deallocator: .none)
        }
        return Data()
    }

    @inlinable
    func dataCopy() -> Data {
        if let raw = raw() {
            return Data(bytes: raw, count: count)
        }
        return Data()
    }

    @inlinable
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

    @inlinable
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

    @inlinable
    func compare(other: Hitchable) -> Int {
        return chitch_cmp_raw(raw(), count, other.raw(), other.count)
    }
    
    @inlinable
    func equals(exact other: Hitchable) -> Bool {
        return chitch_equal_raw(raw(), count, other.raw(), other.count)
    }
    
    @inlinable
    func equals(caseless other: Hitchable) -> Bool {
        return chitch_equal_caseless_raw(raw(), count, other.raw(), other.count)
    }
    
    @inlinable
    func startsAt(raw otherRaw: UnsafePointer<UInt8>, count otherCount: Int, caseless: Bool = false) -> Bool {
        if otherCount < count { return false }
        if caseless {
            return chitch_equal_caseless_raw(raw(), count, otherRaw, count)
        }
        return chitch_equal_raw(raw(), count, otherRaw, count)
    }

    @inlinable
    func canEscape(unicode: Bool,
                   singleQuotes: Bool) -> Bool {
        guard var ptr = raw() else { return false }
        let end = ptr + count
        while ptr < end {
            let char = ptr[0]
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

    @inlinable
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

    @inlinable
    @discardableResult
    func starts(with hitch: Hitchable) -> Bool {
        guard count >= hitch.count else { return false }
        return chitch_equal_raw(raw(), hitch.count, hitch.raw(), hitch.count)
    }

    @inlinable
    @discardableResult
    func starts(with hitch: HalfHitch) -> Bool {
        guard count >= hitch.count else { return false }
        return chitch_equal_raw(raw(), hitch.count, hitch.raw(), hitch.count)
    }

    @inlinable
    @discardableResult
    func ends(with hitch: Hitchable) -> Bool {
        return lastIndex(of: hitch) == count - hitch.count
    }

    @inlinable
    @discardableResult
    func ends(with hitch: HalfHitch) -> Bool {
        return lastIndex(of: hitch) == count - hitch.count
    }
    
    @inlinable
    @discardableResult
    func contains(_ hitch: Hitchable) -> Bool {
        return chitch_contains_raw(raw(), count, hitch.raw(), hitch.count)
    }

    @inlinable
    @discardableResult
    func contains(_ halfHitch: HalfHitch) -> Bool {
        return chitch_contains_raw(raw(), count, halfHitch.source, halfHitch.count)
    }

    @inlinable
    @discardableResult
    func contains(char: UInt8) -> Bool {
        var local = char
        return chitch_contains_raw(raw(), count, &local, 1)
    }

    @inlinable
    @discardableResult
    func firstIndex(of hitch: Hitchable, offset: Int = 0) -> Int? {
        let index = chitch_firstof_raw_offset(raw(), offset, count, hitch.raw(), hitch.count)
        return index >= 0 ? index : nil
    }

    @inlinable
    @discardableResult
    func firstIndex(of hitch: HalfHitch, offset: Int = 0) -> Int? {
        let index = chitch_firstof_raw_offset(raw(), offset, count, hitch.raw(), hitch.count)
        return index >= 0 ? index : nil
    }

    @inlinable
    @discardableResult
    func firstIndex(of char: UInt8, offset: Int = 0) -> Int? {
        var local = char
        let index = chitch_firstof_raw_offset(raw(), offset, count, &local, 1)
        return index >= 0 ? index : nil
    }

    @inlinable
    @discardableResult
    func lastIndex(of hitch: Hitchable) -> Int? {
        let index = chitch_lastof_raw(raw(), count, hitch.raw(), hitch.count)
        return index >= 0 ? index : nil
    }

    @inlinable
    @discardableResult
    func lastIndex(of hitch: HalfHitch) -> Int? {
        let index = chitch_lastof_raw(raw(), count, hitch.raw(), hitch.count)
        return index >= 0 ? index : nil
    }

    @inlinable
    @discardableResult
    func lastIndex(of char: UInt8) -> Int? {
        var local = char
        let index = chitch_lastof_raw(raw(), count, &local, 1)
        return index >= 0 ? index : nil
    }

    @inlinable
    @discardableResult
    func substring(_ lhsPos: Int, _ rhsPos: Int) -> Hitch? {
        guard lhsPos >= 0 && lhsPos <= count else { return nil }
        guard rhsPos >= 0 && rhsPos <= count else { return nil }
        guard lhsPos <= rhsPos else { return nil }
        return Hitch(chitch: chitch_init_substring_raw(raw(), count, lhsPos, rhsPos))
    }
    
    @inlinable
    @discardableResult
    func extract(_ lhs: Hitchable, _ rhs: Hitchable) -> Hitch? {
        return extract(lhs, [rhs])
    }

    @inlinable
    @discardableResult
    func extract(_ lhs: HalfHitch, _ rhs: HalfHitch) -> Hitch? {
        return extract(lhs, [rhs])
    }

    @inlinable
    @discardableResult
    func extract(_ lhs: Hitchable, _ rhs: [Hitchable]) -> Hitch? {
        guard let lhsPos = firstIndex(of: lhs) else { return nil }
        guard let rhsPos = rhs.compactMap({ firstIndex(of: $0, offset: lhsPos + lhs.count) }).min() else { return nil }
        return substring(lhsPos + lhs.count, rhsPos)
    }

    @inlinable
    @discardableResult
    func extract(_ lhs: HalfHitch, _ rhs: [HalfHitch]) -> Hitch? {
        guard let lhsPos = firstIndex(of: lhs) else { return nil }
        guard let rhsPos = rhs.compactMap({ firstIndex(of: $0, offset: lhsPos + lhs.count) }).min() else { return nil }
        return substring(lhsPos + lhs.count, rhsPos)
    }

    @inlinable
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

    @inlinable
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

    @inlinable
    @discardableResult
    func toEpoch() -> Int {
        return chitch_toepoch_raw(raw(), count)
    }
    
    @inlinable
    @discardableResult
    func toEpoch2() -> Int {
        return chitch_toepoch2_raw(raw(), count)
    }
    
    @inlinable
    @discardableResult
    func toEpochISO8601() -> Int {
        return chitch_toepochISO8601_raw(raw(), count)
    }
    
    @inlinable
    func components(inTwain separators: [UInt8],
                    minWidth: Int = 2) -> [HalfHitch] {
        // Splits strings into multiple which are separated by at least minWidth separators
        guard let raw = raw() else { return [] }
        
        let sourceObject = getSourceObject()
        
        let start = raw
        let end = raw + count
        var ptr = start
        
        var parts: [HalfHitch] = []
        
        var separatorStartPtr = ptr
        var textStartPtr = ptr
        while ptr < end {
            
            separatorStartPtr = ptr
            while separators.contains(ptr[0]) {
                // advance to see if this is a breaking point
                ptr += 1
            }
            
            if ptr - separatorStartPtr >= minWidth {
                let part = HalfHitch(sourceObject: sourceObject,
                                     raw: raw,
                                     count: count,
                                     from: textStartPtr - start,
                                     to: separatorStartPtr - start).trimmed()
                if part.count > 0 {
                    parts.append(part)
                }
                textStartPtr = ptr
            }
            
            ptr += 1
        }
        
        if ptr - textStartPtr > 0 {
            parts.append(HalfHitch(sourceObject: sourceObject,
                                   raw: raw,
                                   count: count,
                                   from: textStartPtr - start,
                                   to: end - start))
        }
        
        return parts
    }
}

 @inlinable
func roundToPlaces(value: Double, places: Int) -> Double {
    let divisor = pow(10.0, Double(places))
    return round(value * divisor) / divisor
}

 @inlinable
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

 @inlinable
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

 @inlinable
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

 @inlinable
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

@inlinable
func append(_ v: UInt8,
            _ advance: Int,
            _ write: inout UnsafeMutablePointer<UInt8>,
            _ read: inout UnsafeMutablePointer<UInt8>) {
    write[0] = v
    write += 1
    read += advance
}

@inlinable
func append2(_ v: UInt8,
             _ advance: Int,
             _ write: inout UnsafeMutablePointer<UInt8>,
             _ read: inout UnsafeMutablePointer<UInt8>) {
    if v == .carriageReturn {
        read += advance
        return
    }

    write[0] = v
    write += 1
    read += advance
}

@inlinable
func convert(_ write: inout UnsafeMutablePointer<UInt8>,
             _ read: inout UnsafeMutablePointer<UInt8>,
             _ end: UnsafeMutablePointer<UInt8>,
             _ endCondition: (UnsafeMutablePointer<UInt8>) -> Bool) -> Void {
    var value: UInt32 = 0
    while read < end && endCondition(read) == false {
        guard let byte: UInt32 = hex(read[0]) else { break }
        value &*= 16
        value &+= byte
        read += 1
    }
    if let scalar = UnicodeScalar(value) {
        for v in Character(scalar).utf8 {
            append(v, 0, &write, &read)
        }
    }
}

@inlinable
func unescapeBinary(unicode data: UnsafeMutablePointer<UInt8>,
                    count: Int) -> Int {
    var read = data
    var write = data
    let end = data + count

    while read < end {

        if read[0] == .backSlash {
            switch read[1] {
            case .backSlash: append(.backSlash, 2, &write, &read); continue
            case .forwardSlash: append(.forwardSlash, 2, &write, &read); continue
            case .singleQuote: append(.singleQuote, 2, &write, &read); continue
            case .doubleQuote: append(.doubleQuote, 2, &write, &read); continue
            case .r: append(.carriageReturn, 2, &write, &read); continue
            case .f: append(.formFeed, 2, &write, &read); continue
            case .t: append(.tab, 2, &write, &read); continue
            case .n: append(.newLine, 2, &write, &read); continue
            case .b: append(.bell, 2, &write, &read); continue
            case .u:
                if read[2] == .openBracket {
                    // like: \u{1D11E}
                    read += 3
                    convert(&write, &read, end) { read in
                        return read[0] == .closeBracket
                    }
                    if read[0] == .closeBracket {
                        read += 1
                    }
                } else {
                    // like: \u20AC
                    read += 2
                    let start = read
                    convert(&write, &read, end) { read in
                        return read - start >= 4
                    }
                }
                continue
            default:
                break
            }
        }

        append(read[0], 1, &write, &read)
    }

    write[0] = 0
    return (write - data)
}

 @inlinable
func escapeBinary(unicode data: UnsafePointer<UInt8>,
                  count: Int,
                  unicode: Bool,
                  singleQuotes: Bool) -> Hitch {
    let writer = Hitch(capacity: count)

    var read = data
    let end = data + count

    while read < end {
        let ch = read[0]

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

 @inlinable
func unescapeBinary(ampersand data: UnsafeMutablePointer<UInt8>,
                    count: Int) -> Int {
    var read = data
    var write = data
    let end = data + count

    while read < end {
        // &amp;&lt;&gt;&quot;&apos;&#038;
        if read[0] == .ampersand && read < end - 2 {
            let endCount = end - read
            
            let char1 = read[1]
            if char1 == .hashTag {

                var tmpRead = read + 2
                var value: UInt32 = 0
                while tmpRead < end &&
                        tmpRead[0] >= .zero &&
                        tmpRead[0] <= .nine &&
                        tmpRead - read < 10 {
                    value &*= 10
                    value &+= UInt32(tmpRead[0] - .zero)
                    tmpRead += 1
                }
                if tmpRead[0] == .semiColon {
                    if let scalar = UnicodeScalar(value) {
                        for v in Character(scalar).utf8 {
                            append(v, 0, &write, &read)
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
                append(.ampersand, 5, &write, &read)
                continue
            } else if endCount >= 6 &&
                        char1 == .a &&
                        read[2] == .p &&
                        read[3] == .o &&
                        read[4] == .s &&
                        read[5] == .semiColon {
                append(.singleQuote, 6, &write, &read)
                continue
            } else if endCount >= 4 &&
                        char1 == .l &&
                        read[2] == .t &&
                        read[3] == .semiColon {
                append(.lessThan, 4, &write, &read)
                continue
            } else if endCount >= 4 &&
                        char1 == .g &&
                        read[2] == .t &&
                        read[3] == .semiColon {
                append(.greaterThan, 4, &write, &read)
                continue
            } else if endCount >= 6 &&
                        char1 == .q &&
                        read[2] == .u &&
                        read[3] == .o &&
                        read[4] == .t &&
                        read[5] == .semiColon {
                append(.doubleQuote, 6, &write, &read)
                continue
            } else if endCount >= 5 &&
                        char1 == .t &&
                        read[2] == .a &&
                        read[3] == .b &&
                        read[4] == .semiColon {
                append(.tab, 5, &write, &read)
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
                append(.newLine, 9, &write, &read)
                continue
            } else if endCount >= 6 &&
                        char1 == .n &&
                        read[2] == .b &&
                        read[3] == .s &&
                        read[4] == .p &&
                        read[5] == .semiColon {
                append(.space, 6, &write, &read)
                continue
            } else if endCount >= 6 &&
                        char1 == .b &&
                        read[2] == .u &&
                        read[3] == .l &&
                        read[4] == .l &&
                        read[5] == .semiColon {
                append(.astericks, 6, &write, &read)
                continue
            } else if endCount >= 6 &&
                        char1 == .c &&
                        read[2] == .o &&
                        read[3] == .p &&
                        read[4] == .y &&
                        read[5] == .semiColon {
                append(0xC2, 1, &write, &read)
                append(0xA9, 5, &write, &read)
                continue
            } else if endCount >= 6 &&
                        char1 == .z &&
                        read[2] == .w &&
                        read[3] == .n &&
                        read[4] == .j &&
                        read[5] == .semiColon {
                append(.space, 6, &write, &read)
                continue
            } else if endCount >= 5 &&
                        char1 == .z &&
                        read[2] == .w &&
                        read[3] == .j &&
                        read[4] == .semiColon {
                append(.space, 5, &write, &read)
                continue
            } else if endCount >= 5 &&
                        char1 == .r &&
                        read[2] == .e &&
                        read[3] == .g &&
                        read[4] == .semiColon {
                append(0xC2, 0, &write, &read)
                append(0xAE, 5, &write, &read)
                continue
            } else if endCount >= 7 &&
                        char1 == .n &&
                        read[2] == .d &&
                        read[3] == .a &&
                        read[4] == .s &&
                        read[5] == .h &&
                        read[6] == .semiColon {
                append(.minus, 7, &write, &read)
                continue
            }
        }

        append(read[0], 1, &write, &read)
    }
    
    replaceDanglingControlChars(start: data,
                                end: write)

    write[0] = 0
    return (write - data)
}

 @inlinable
func unescapeBinary(quotedPrintable data: UnsafeMutablePointer<UInt8>,
                    count: Int) -> Int {
    
    var read = data
    var write = data
    let end = data + count

    while read < end {
        if read[0] == .equal && read < end-2 {
            
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
            } else if char1 >= .A && char1 <= .F {
                value1 += (char1 - .A) + 10
            } else {
                append2(read[0], 1, &write, &read)
                continue
            }
            
            var value2: UInt8 = 0
            if char2 >= .zero && char2 <= .nine {
                value2 += char2 - .zero
            } else if char2 >= .A && char2 <= .F {
                value2 += (char2 - .A) + 10
            } else {
                append2(read[0], 1, &write, &read)
                continue
            }
            
            let ascii: UInt8 = value1 * 16 + value2
            append2(ascii, 3, &write, &read)
            continue
        }

        append2(read[0], 1, &write, &read)
    }
    
    replaceDanglingControlChars(start: data,
                                end: write)
    
    write[0] = 0
    return (write - data)
}

 @inlinable
func unescapeBinary(emlHeader data: UnsafeMutablePointer<UInt8>,
                    count: Int) -> Int {
    // like: =?UTF-8?B?T3JkZXIgQ29uZmlybWF0aW9uIOKAkyBPcmRlciAjOiAyNzU1NTQ=?=
    //       =?UTF-8?B?MzY1?=
    
    var read = data
    var write = data
    let end = data + count
            
    while read < end {
        if read[0] == .equal &&
            read[1] == .questionMark {
            // we found the beginning mark
            read += 2
            
            // Gather the format (ie UTF-8, ISO-8859-1, ISO-8859-2...)
            while read < end-1 {
                if read[0] == .questionMark {
                    read += 1
                    break
                }
                read += 1
            }
            
            // Gather the encoding type (base64 or quoted-printable)
            let typeOfEncoding: UInt8 = read[0]
            guard read[1] == .questionMark else { break }
            guard typeOfEncoding == .B || typeOfEncoding == .b || typeOfEncoding == .Q || typeOfEncoding == .q else { break }
            read += 2
            
            // advance to the end mark
            let contentStart = read
            var contentEnd = read
            while read < end-1 {
                if read[0] == .questionMark &&
                    read[1] == .equal {
                    contentEnd = read
                    read += 2
                    break
                }
                read += 1
            }
            
            // Now we have the format type, the encoding type, and the
            // range of the actual content.  Decode the content and
            // write it out.
            let contentHitch = Hitch(bytes: contentStart,
                                     offset: 0,
                                     count: contentEnd - contentStart)
            
            if typeOfEncoding == .B || typeOfEncoding == .b {
                guard let data = Data(base64Encoded: contentHitch.dataNoCopy(), options: [.ignoreUnknownCharacters]) else { break }
                guard let string = String(data: data, encoding: .utf8) else { break }
                contentHitch.replace(with: string)
            } else if typeOfEncoding == .Q || typeOfEncoding == .q {
                contentHitch.quotedPrintableUnescape()
            }
            
            for c in contentHitch {
                write[0] = c
                write += 1
            }
        } else {
            append2(read[0], 1, &write, &read)
        }
    }
    
    write[0] = 0
    return (write - data)
}

 @inlinable
func unescapeBinary(percent data: UnsafeMutablePointer<UInt8>,
                    count: Int) -> Int {
    // https:\/\/www.google.com\/url?q=https%3A%2F%2Fsardelkitchen.com&amp;sa=D&amp;sntz=1&amp;usg=AOvVaw1T4EtLqdGmEYA-MilAqQIc"
    var read = data
    var write = data
    let end = data + count

    while read < end {

        if read[0] == .percentSign && read < end-2 {
            
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
                append(read[0], 1, &write, &read)
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
                append(read[0], 1, &write, &read)
                continue
            }
            
            let ascii: UInt8 = value1 * 16 + value2
            if ascii >= 32 && ascii <= 126 {
                append(ascii, 3, &write, &read); continue
            }
        }

        append(read[0], 1, &write, &read)
    }

    write[0] = 0
    return (write - data)
}

@inlinable
public func decimal(_ v: UInt8) -> UInt32? {
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

@inlinable
public func decimal(_ v: UInt8) -> UInt8? {
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

@inlinable
public func hex(_ v: UInt8) -> UInt32? {
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

@inlinable
public func hex(_ v: UInt8) -> UInt8? {
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

@inlinable
public func hex2(_ v: UInt32) -> UInt8 {
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

@inlinable
public func hex2(_ v: UInt8) -> UInt8 {
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
