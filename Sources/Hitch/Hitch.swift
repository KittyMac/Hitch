// swiftlint:disable type_body_length

import Foundation

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

    @inlinable
    mutating func write(_ string: String) {
        if let index = index {
            hitch.insert(string, index: index, precision: precision)
        } else {
            hitch.append(string, precision: precision)
        }
    }
}

// Note: being a subclass of NSObject is required (BOO) due to runtime crash on Linux when storing Hitch values in a dictionary
// See unit test testCastAnyToHitch().
public final class Hitch: NSObject, Hitchable, ExpressibleByStringLiteral, Sequence, Comparable, Codable {
    public static let empty: Hitch = ""
    
    @inlinable
    public func getSourceObject() -> AnyObject? {
        return self
    }

    @inlinable
    public static func == (lhs: Hitch, rhs: Hitch) -> Bool {
        return chitch_equal_raw(lhs.raw(), lhs.count, rhs.raw(), rhs.count)
    }

    @inlinable
    public static func == (lhs: Hitch, rhs: HalfHitch) -> Bool {
        return chitch_equal_raw(lhs.raw(), lhs.count, rhs.raw(), rhs.count)
    }

    @inlinable
    public static func == (lhs: HalfHitch, rhs: Hitch) -> Bool {
        return chitch_equal_raw(lhs.raw(), lhs.count, rhs.raw(), rhs.count)
    }

    @inlinable
    public static func == (lhs: Hitch, rhs: StaticString) -> Bool {
        let halfhitch = HalfHitch(stringLiteral: rhs)
        return chitch_equal_raw(lhs.raw(), lhs.count, halfhitch.raw(), halfhitch.count)
    }

    @inlinable
    public static func == (lhs: StaticString, rhs: Hitch) -> Bool {
        let halfhitch = HalfHitch(stringLiteral: lhs)
        return chitch_equal_raw(halfhitch.raw(), halfhitch.count, rhs.raw(), rhs.count)
    }
    
    @inlinable
    public static func ~== (lhs: Hitch, rhs: Hitch) -> Bool {
        return chitch_equal_caseless_raw(lhs.raw(), lhs.count, rhs.raw(), rhs.count)
    }

    @inlinable
    public static func ~== (lhs: Hitch, rhs: HalfHitch) -> Bool {
        return chitch_equal_caseless_raw(lhs.raw(), lhs.count, rhs.raw(), rhs.count)
    }

    @inlinable
    public static func ~== (lhs: HalfHitch, rhs: Hitch) -> Bool {
        return chitch_equal_caseless_raw(lhs.raw(), lhs.count, rhs.raw(), rhs.count)
    }

    @inlinable
    public static func ~== (lhs: Hitch, rhs: StaticString) -> Bool {
        let halfhitch = HalfHitch(stringLiteral: rhs)
        return chitch_equal_caseless_raw(lhs.raw(), lhs.count, halfhitch.raw(), halfhitch.count)
    }

    @inlinable
    public static func ~== (lhs: StaticString, rhs: Hitch) -> Bool {
        let halfhitch = HalfHitch(stringLiteral: lhs)
        return chitch_equal_caseless_raw(halfhitch.raw(), halfhitch.count, rhs.raw(), rhs.count)
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let object0 = object else { return false }
        guard let object1 = object0 as? Hitchable else { return false }
        return chitch_equal_raw(raw(), count, object1.raw(), object1.count)
    }

    @inlinable
    public subscript (index: Int) -> UInt8 {
        get {
            if let data = chitch.universalData,
               index < chitch.count {
                return data[index]
            }
            return 0
        }
        set(newValue) {
            if let data = chitch.mutableData,
               index < chitch.count {
                data[index] = newValue
            }
        }
    }

    @inlinable
    public func raw() -> UnsafePointer<UInt8>? {
        return chitch.universalData
    }

    @inlinable
    public func mutableRaw() -> UnsafeMutablePointer<UInt8>? {
        return chitch.mutableData
    }

    @inlinable
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        self.init(string: string)
    }

    @inlinable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.description)
    }

    @usableFromInline
    var chitch: CHitch

    @usableFromInline
    var lastHash: Int = 0

    deinit {
        chitch_dealloc(&chitch)
    }

    required public init? (contentsOfFile path: String) {
        // Read contents of file directly into our memory (unnecessary data copy)
        guard let file = fopen(path, "r") else {
            return nil
        }

        fseek(file, 0, SEEK_END)
        let size = Int(ftell(file))
        fseek(file, 0, SEEK_SET)

        chitch = chitch_init_capacity(size)

        guard let mutableData = chitch.mutableData else { return nil }

        fread(mutableData, 1, size, file)

        fclose(file)
        chitch.count = size
        nullify(&chitch)
    }

    required public init (stringLiteral: StaticString, copyOnWrite: Bool) {
        if stringLiteral.hasPointerRepresentation {
            chitch = chitch_static(stringLiteral.utf8Start,
                                   stringLiteral.utf8CodeUnitCount,
                                   copyOnWrite)
        } else {
            chitch = stringLiteral.withUTF8Buffer { bytes in
                chitch_init_raw(bytes.baseAddress, bytes.count)
            }
        }
    }

    required public init (stringLiteral: StaticString) {
        if stringLiteral.hasPointerRepresentation {
            chitch = chitch_static(stringLiteral.utf8Start,
                                   stringLiteral.utf8CodeUnitCount,
                                   false)
        } else {
            chitch = stringLiteral.withUTF8Buffer { bytes in
                chitch_init_raw(bytes.baseAddress, bytes.count)
            }
        }
    }

    required public init (string: String) {
        chitch = chitch_init_string(string)
    }

    public init(hitch: Hitch) {
        chitch = chitch_init_raw(hitch.raw(), hitch.count)
    }

    public init(bytes: UnsafeMutablePointer<UInt8>, offset: Int, count: Int) {
        chitch = chitch_init_raw(bytes + offset, count)
    }

    public init(bytes: UnsafePointer<UInt8>, offset: Int, count: Int) {
        chitch = chitch_init_raw(bytes + offset, count)
    }
    
    public init(utf8 raw: UnsafePointer<UInt8>) {
        chitch = chitch_init_raw(raw, strlen(raw))
    }
    
    public init(utf8 raw: UnsafePointer<CChar>) {
        chitch = chitch_init_raw(UnsafeRawPointer(raw).assumingMemoryBound(to: UInt8.self), strlen(raw))
    }

    public init(data: Data) {
        chitch = chitch_empty()
        super.init()

        data.withUnsafeBytes { unsafeRawBufferPointer in
            let unsafeBufferPointer = unsafeRawBufferPointer.bindMemory(to: UInt8.self)
            guard let bytes = unsafeBufferPointer.baseAddress else { return }
            chitch = chitch_init_raw(bytes, data.count)
        }
    }

    public init(capacity: Int) {
        chitch = chitch_init_capacity(capacity)
    }
    
    public init(garbage: Int) {
        chitch = chitch_init_capacity(garbage)
        chitch.count = garbage
        nullify(&chitch)
    }

    public override init() {
        chitch = chitch_empty()
    }

    @usableFromInline
    internal init(chitch: CHitch) {
        self.chitch = chitch
    }

    public override var description: String {
        return toTempString()
    }

    @inlinable
    public var count: Int {
        get {
            return chitch.count
        }
        set {
            chitch_resize(&chitch, Swift.max(0, newValue))
        }
    }

    @inlinable
    public var capacity: Int {
        get {
            return chitch.capacity
        }
    }
    
    /// Give the raw memory for this string back to the caller, then
    /// forget about it. It becomes the responsibility of the caller
    /// to release this memory
    @inlinable
    public func export() -> (UnsafePointer<UInt8>?, Int) {
        defer { chitch = chitch_empty() }
        if let raw = chitch.universalData {
            return (raw, count)
        }
        return (nil, 0)
    }

    @inlinable
    public func exportAsData() -> Data {
        if let raw = chitch.mutableData {
            defer { chitch = chitch_empty() }
            return Data(bytesNoCopy: raw, count: count, deallocator: .free)
        }
        if let raw = chitch.universalData {
            defer { release() }
            return Data(bytes: raw, count: count)
        }
        return Data()
    }

    @inlinable
    public override var hash: Int {
        if lastHash == 0 {
            lastHash = chitch_hash_raw(raw(), count)
        }
        return lastHash
    }

    @inlinable
    public func components(separatedBy separator: HalfHitch) -> [HalfHitch] {
        guard let raw = raw() else { return [] }
        guard let separatorRaw = separator.raw() else { return [] }
        let rawCount = count
        let separatorCount = separator.count

        var components = [HalfHitch]()
        var currentIdx = 0

        while true {
            let nextIdx = chitch_firstof_raw_offset(raw, currentIdx, rawCount, separatorRaw, separatorCount)
            if nextIdx < 0 {
                break
            }

            if currentIdx != nextIdx {
                components.append(
                    HalfHitch(sourceObject: self, raw: raw, count: rawCount, from: currentIdx, to: nextIdx)
                )
            } else {
                components.append(
                    ""
                )
            }
            currentIdx = nextIdx + separatorCount
        }

        if currentIdx != rawCount {
            components.append(
                HalfHitch(sourceObject: self, raw: raw, count: rawCount, from: currentIdx, to: rawCount)
            )
        } else {
            components.append(
                ""
            )
        }

        return components
    }

    @inlinable
    public func components(separatedBy separator: HalfHitch) -> [Hitch] {
        let hhcomponents: [HalfHitch] = components(separatedBy: separator)
        return hhcomponents.map { $0.hitch() }
    }

    // MARK: - Mutating

    @inlinable
    public func clear() {
        lastHash = 0
        chitch_resize(&chitch, 0)
    }

    @inlinable
    public func release() {
        lastHash = 0
        chitch_dealloc(&chitch)
        chitch = chitch_empty()
    }

    @inlinable
    public func replace(with string: String) {
        lastHash = 0
        count = 0
        append(string)
    }

    @inlinable
    public func replace(with hitch: Hitch) {
        lastHash = 0
        count = 0
        append(hitch)
    }

    @inlinable
    @discardableResult
    public func replace(from: Int, to: Int, with: Hitch) -> Self {
        guard from >= 0 && from <= count else { return self }
        guard to >= 0 && to <= count else { return self }
        guard from <= to else { return self }

        lastHash = 0
        chitch_make_mutable(&chitch)
        chitch_replace(&chitch, from, to, with.chitch)
        return self
    }

    @inlinable
    @discardableResult
    public func replace(occurencesOf hitch: Hitch, with: Hitch, ignoreCase: Bool = false) -> Self {
        lastHash = 0
        chitch_make_mutable(&chitch)
        chitch_replace(&chitch, hitch.chitch, with.chitch, ignoreCase)
        return self
    }

    @inlinable
    @discardableResult
    public func reserveCapacity(_ newCapacity: Int) -> Self {
        if newCapacity > chitch.capacity {
            chitch_make_mutable(&chitch)
            chitch_resize(&chitch, newCapacity)
        }
        return self
    }

    @inlinable
    @discardableResult
    public func lowercase() -> Self {
        lastHash = 0
        chitch_make_mutable(&chitch)
        chitch_tolower_raw(chitch.mutableData, chitch.count)
        return self
    }

    @inlinable
    @discardableResult
    public func uppercase() -> Self {
        lastHash = 0
        chitch_make_mutable(&chitch)
        chitch_toupper_raw(chitch.mutableData, chitch.count)
        return self
    }

    @inlinable
    @discardableResult
    public func append(_ hitch: Hitch, precision: Int? = nil) -> Self {
        lastHash = 0
        chitch_make_mutable(&chitch)
        if let precision = precision {
            chitch_concat_precision(&chitch, hitch.raw(), hitch.count, precision)
        } else {
            chitch_concat(&chitch, hitch.raw(), hitch.count)
        }
        return self
    }

    @inlinable
    @discardableResult
    public func append(_ bytes: UnsafePointer<UInt8>, count: Int) -> Self {
        lastHash = 0
        chitch_make_mutable(&chitch)
        chitch_concat(&chitch, bytes, count)
        return self
    }

    @inlinable
    @discardableResult
    public func append(_ bytes: UnsafeMutablePointer<UInt8>, count: Int) -> Self {
        lastHash = 0
        chitch_make_mutable(&chitch)
        chitch_concat(&chitch, bytes, count)
        return self
    }

    @inlinable
    @discardableResult
    public func append(_ hitch: Hitchable) -> Self {
        lastHash = 0
        chitch_make_mutable(&chitch)
        chitch_concat(&chitch, hitch.raw(), hitch.count)
        return self
    }

    @inlinable
    @discardableResult
    public func append(_ string: String) -> Self {
        lastHash = 0
        chitch_make_mutable(&chitch)
        chitch_using(string) { string_raw, string_count in
            chitch_concat(&chitch, string_raw, string_count)
        }
        return self
    }

    @inlinable
    @discardableResult
    public func append(_ string: String, precision: Int?) -> Self {
        lastHash = 0
        chitch_make_mutable(&chitch)
        return chitch_using(string) { string_raw, string_count in
            if let precision = precision {
                chitch_concat_precision(&chitch, string_raw, string_count, precision)
            } else {
                chitch_concat(&chitch, string_raw, string_count)
            }
            return self
        }
    }

    @inlinable
    @discardableResult
    public func append(_ char: UInt8) -> Self {
        lastHash = 0
        chitch_make_mutable(&chitch)
        chitch_concat_char(&chitch, char)
        return self
    }

    @inlinable
    @discardableResult
    public func append<T: FixedWidthInteger>(number: T) -> Self {
        return insert(number: number, index: count)
    }

    @inlinable
    @discardableResult
    public func append(double: Double, precision: Int? = nil) -> Self {
        var output = HitchOutputStream(hitch: self, precision: precision)
        double.write(to: &output)
        return self
    }

    @inlinable
    @discardableResult
    public func append(_ data: Data) -> Self {
        lastHash = 0
        chitch_make_mutable(&chitch)
        data.withUnsafeBytes { unsafeRawBufferPointer in
            let unsafeBufferPointer = unsafeRawBufferPointer.bindMemory(to: UInt8.self)
            guard let bytes = unsafeBufferPointer.baseAddress else { return }
            chitch_concat(&chitch, bytes, data.count)
        }
        return self
    }

    @inlinable
    @discardableResult
    public func insert(_ hitch: Hitch, index: Int) -> Self {
        lastHash = 0
        chitch_make_mutable(&chitch)
        chitch_insert_raw(&chitch, index, hitch.raw(), hitch.count)
        return self
    }

    @inlinable
    @discardableResult
    public func insert(_ string: String, index: Int) -> Self {
        lastHash = 0
        chitch_make_mutable(&chitch)
        chitch_insert_cstring(&chitch, index, string)
        return self
    }

    @inlinable
    @discardableResult
    public func insert(_ string: String, index: Int, precision: Int?) -> Self {
        lastHash = 0
        chitch_make_mutable(&chitch)
        chitch_using(string) { string_raw, _ in
            var length = string.count
            if let precision = precision {
                var ptr = string_raw
                while ptr[0] != 0 {
                    let c = UInt8(ptr[0])
                    if c == .dot {
                        length = Swift.min(length, ptr - string_raw + precision + 1)
                        break
                    }
                    ptr += 1
                }
            }
            chitch_insert_raw(&chitch, index, string_raw, length)
        }
        return self
    }

    @inlinable
    @discardableResult
    public func insert(_ char: UInt8, index: Int) -> Self {
        lastHash = 0
        chitch_make_mutable(&chitch)
        chitch_insert_char(&chitch, index, char)
        return self
    }

    @inlinable
    @discardableResult
    public func insert<T: FixedWidthInteger>(number: T, index: Int) -> Self {
        lastHash = 0
        chitch_make_mutable(&chitch)
        chitch_insert_int(&chitch, index, Int(number))
        return self
    }

    @inlinable
    @discardableResult
    public func insert(double: Double, index: Int, precision: Int? = nil) -> Self {
        var output = HitchOutputStream(hitch: self, index: index, precision: precision)
        double.write(to: &output)
        return self
    }

    @inlinable
    @discardableResult
    public func insert(_ data: Data, index: Int) -> Self {
        lastHash = 0
        chitch_make_mutable(&chitch)
        data.withUnsafeBytes { unsafeRawBufferPointer in
            let unsafeBufferPointer = unsafeRawBufferPointer.bindMemory(to: UInt8.self)
            guard let bytes = unsafeBufferPointer.baseAddress else { return }
            chitch_insert_raw(&chitch, index, bytes, data.count)
        }
        return self
    }
    
    @inlinable
    @discardableResult
    public func clamp(_ k: Int) -> Self {
        if count > k {
            count = k
        }
        return self
    }

    @inlinable
    @discardableResult
    public func trim() -> Self {
        lastHash = 0
        chitch_make_mutable(&chitch)
        chitch_trim(&chitch)
        return self
    }

    @inlinable
    @discardableResult
    public func unicodeUnescape() -> Hitch {
        lastHash = 0
        chitch_make_mutable(&chitch)
        guard let raw = chitch.mutableData else { return self }
        count = unescapeBinary(unicode: raw,
                               count: count)
        return self
    }

    @inlinable
    @discardableResult
    public func unicodeUnescaped() -> Hitch {
        // returns self if there was nothing to unescape, or silo'd halfhitch if there was
        guard let raw = raw() else { return self }

        var local: UInt8 = .backSlash
        guard chitch_contains_raw(raw, count, &local, 1) == true else { return self }

        return Hitch(hitch: self).unicodeUnescape()
    }
    
    @inlinable
    @discardableResult
    public func percentUnescape() -> Hitch {
        lastHash = 0
        chitch_make_mutable(&chitch)
        guard let raw = chitch.mutableData else { return self }
        count = unescapeBinary(percent: raw,
                               count: count)
        return self
    }

    @inlinable
    @discardableResult
    public func percentUnescaped() -> Hitch {
        // returns self if there was nothing to unescape, or silo'd halfhitch if there was
        guard let raw = raw() else { return self }

        var local: UInt8 = .percentSign
        guard chitch_contains_raw(raw, count, &local, 1) == true else { return self }

        return Hitch(hitch: self).percentUnescape()
    }
    
    @inlinable
    @discardableResult
    public func ampersandUnescape() -> Hitch {
        lastHash = 0
        chitch_make_mutable(&chitch)
        guard let raw = chitch.mutableData else { return self }
        count = unescapeBinary(ampersand: raw,
                               count: count)
        return self
    }

    @inlinable
    @discardableResult
    public func ampersandUnescaped() -> Hitch {
        // returns self if there was nothing to unescape, or silo'd halfhitch if there was
        guard let raw = raw() else { return self }

        var local: UInt8 = .ampersand
        guard chitch_contains_raw(raw, count, &local, 1) == true else { return self }

        return Hitch(hitch: self).ampersandUnescape()
    }
    
    @inlinable
    @discardableResult
    public func quotedPrintableUnescape() -> Hitch {
        lastHash = 0
        chitch_make_mutable(&chitch)
        guard let raw = chitch.mutableData else { return self }
        count = unescapeBinary(quotedPrintable: raw,
                               count: count)
        return self
    }

    @inlinable
    @discardableResult
    public func quotedPrintableUnescaped() -> Hitch {
        // returns self if there was nothing to unescape, or silo'd halfhitch if there was
        guard let raw = raw() else { return self }

        var local: UInt8 = .equal
        guard chitch_contains_raw(raw, count, &local, 1) == true else { return self }

        return Hitch(hitch: self).quotedPrintableUnescape()
    }
    
    @inlinable
    @discardableResult
    public func emlHeaderUnescape() -> Hitch {
        lastHash = 0
        chitch_make_mutable(&chitch)
        guard let raw = chitch.mutableData else { return self }
        count = unescapeBinary(emlHeader: raw,
                               count: count)
        return self
    }

    @inlinable
    @discardableResult
    public func emlHeaderUnescaped() -> Hitch {
        // returns self if there was nothing to unescape, or silo'd halfhitch if there was
        guard let raw = raw() else { return self }

        guard count > 2 else { return self }
        guard raw[0] == .equal && raw[1] == .questionMark else { return self }

        return Hitch(hitch: self).emlHeaderUnescape()
    }

    @inlinable
    @discardableResult
    public func halfhitch(_ lhsPos: Int, _ rhsPos: Int) -> HalfHitch {
        guard lhsPos >= 0 && lhsPos <= count else { return HalfHitch() }
        guard rhsPos >= 0 && rhsPos <= count else { return HalfHitch() }
        guard lhsPos <= rhsPos else { return HalfHitch() }
        return HalfHitch(source: self, from: lhsPos, to: rhsPos)
    }

    @inlinable
    @discardableResult
    public func halfhitch() -> HalfHitch {
        return HalfHitch(source: self, from: 0, to: count)
    }

}
