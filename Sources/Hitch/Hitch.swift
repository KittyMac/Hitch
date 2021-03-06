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

    @inlinable @inline(__always)
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

    @inlinable @inline(__always)
    public static func == (lhs: Hitch, rhs: Hitch) -> Bool {
        return chitch_equal_raw(lhs.raw(), lhs.count, rhs.raw(), rhs.count)
    }

    @inlinable @inline(__always)
    public static func == (lhs: Hitch, rhs: HalfHitch) -> Bool {
        return chitch_equal_raw(lhs.raw(), lhs.count, rhs.raw(), rhs.count)
    }

    @inlinable @inline(__always)
    public static func == (lhs: HalfHitch, rhs: Hitch) -> Bool {
        return chitch_equal_raw(lhs.raw(), lhs.count, rhs.raw(), rhs.count)
    }

    @inlinable @inline(__always)
    public static func == (lhs: Hitch, rhs: StaticString) -> Bool {
        let halfhitch = HalfHitch(stringLiteral: rhs)
        return chitch_equal_raw(lhs.raw(), lhs.count, halfhitch.raw(), halfhitch.count)
    }

    @inlinable @inline(__always)
    public static func == (lhs: StaticString, rhs: Hitch) -> Bool {
        let halfhitch = HalfHitch(stringLiteral: lhs)
        return chitch_equal_raw(halfhitch.raw(), halfhitch.count, rhs.raw(), rhs.count)
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let object0 = object else { return false }
        guard let object1 = object0 as? Hitchable else { return false }
        return chitch_equal_raw(raw(), count, object1.raw(), object1.count)
    }

    @inlinable @inline(__always)
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

    @inlinable @inline(__always)
    public func raw() -> UnsafePointer<UInt8>? {
        return chitch.universalData
    }

    @inlinable @inline(__always)
    public func mutableRaw() -> UnsafeMutablePointer<UInt8>? {
        return chitch.mutableData
    }

    @inlinable @inline(__always)
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        self.init(string: string)
    }

    @inlinable @inline(__always)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.description)
    }

    @usableFromInline
    var chitch: CHitch

    @usableFromInline
    var lastHash: Int = 0

    @inlinable @inline(__always)
    deinit {
        chitch_dealloc(&chitch)
    }

    @inlinable @inline(__always)
    required public init? (contentsOfFile path: String) {
        // Read contents of file directly into our memory (unnecessary data copy)
        guard let file = fopen(path, "r") else {
            return nil
        }

        fseek(file, 0, SEEK_END)
        let size = ftell(file)
        fseek(file, 0, SEEK_SET)

        chitch = chitch_init_capacity(size)

        guard let mutableData = chitch.mutableData else { return nil }

        fread(mutableData, 1, size, file)

        fclose(file)
        chitch.count = size
    }

    @inlinable @inline(__always)
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

    @inlinable @inline(__always)
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

    @inlinable @inline(__always)
    required public init (string: String) {
        chitch = chitch_init_string(string)
    }

    @inlinable @inline(__always)
    public init(hitch: Hitch) {
        chitch = chitch_init_raw(hitch.raw(), hitch.count)
    }

    @inlinable @inline(__always)
    public init(bytes: UnsafeMutablePointer<UInt8>, offset: Int, count: Int) {
        chitch = chitch_init_raw(bytes + offset, count)
    }

    @inlinable @inline(__always)
    public init(bytes: UnsafePointer<UInt8>, offset: Int, count: Int) {
        chitch = chitch_init_raw(bytes + offset, count)
    }

    @inlinable @inline(__always)
    public init(data: Data) {
        chitch = chitch_empty()
        super.init()

        data.withUnsafeBytes { unsafeRawBufferPointer in
            let unsafeBufferPointer = unsafeRawBufferPointer.bindMemory(to: UInt8.self)
            guard let bytes = unsafeBufferPointer.baseAddress else { return }
            chitch = chitch_init_raw(bytes, data.count)
        }
    }

    @inlinable @inline(__always)
    public init(capacity: Int) {
        chitch = chitch_init_capacity(capacity)
    }

    public override init() {
        chitch = chitch_empty()
    }

    @usableFromInline
    internal init(chitch: CHitch) {
        self.chitch = chitch
    }

    public override var description: String {
        if let raw = raw() {
            return String(bytesNoCopy: UnsafeMutableRawPointer(mutating: raw), length: count, encoding: .utf8, freeWhenDone: false) ?? ""
        }
        if let raw = mutableRaw() {
            return String(bytesNoCopy: raw, length: count, encoding: .utf8, freeWhenDone: false) ?? ""
        }
        return ""
    }

    @inlinable @inline(__always)
    public var count: Int {
        get {
            return chitch.count
        }
        set {
            chitch_resize(&chitch, Swift.max(0, newValue))
        }
    }

    @inlinable @inline(__always)
    public var capacity: Int {
        get {
            return chitch.capacity
        }
    }

    @inlinable @inline(__always)
    public func exportAsData() -> Data {
        defer { chitch = chitch_empty() }
        if let raw = chitch.universalData {
            return Data(bytes: raw, count: count)
        }
        return Data()
    }

    @inlinable @inline(__always)
    public override var hash: Int {
        if lastHash == 0 {
            lastHash = chitch_hash_raw(raw(), count)
        }
        return lastHash
    }

    @inlinable @inline(__always)
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
            }
            currentIdx = nextIdx + separatorCount
        }

        if currentIdx != rawCount {
            components.append(
                HalfHitch(sourceObject: self, raw: raw, count: rawCount, from: currentIdx, to: rawCount)
            )
        }

        return components
    }

    @inlinable @inline(__always)
    public func components(separatedBy separator: HalfHitch) -> [Hitch] {
        let hhcomponents: [HalfHitch] = components(separatedBy: separator)
        return hhcomponents.map { $0.hitch() }
    }

    // MARK: - Mutating

    @inlinable @inline(__always)
    public func clear() {
        lastHash = 0
        chitch_resize(&chitch, 0)
    }

    @inlinable @inline(__always)
    public func release() {
        lastHash = 0
        chitch_dealloc(&chitch)
        chitch = chitch_empty()
    }

    @inlinable @inline(__always)
    public func replace(with string: String) {
        lastHash = 0
        count = 0
        append(string)
    }

    @inlinable @inline(__always)
    public func replace(with hitch: Hitch) {
        lastHash = 0
        count = 0
        append(hitch)
    }

    @inlinable @inline(__always)
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

    @inlinable @inline(__always)
    @discardableResult
    public func replace(occurencesOf hitch: Hitch, with: Hitch, ignoreCase: Bool = false) -> Self {
        lastHash = 0
        chitch_make_mutable(&chitch)
        chitch_replace(&chitch, hitch.chitch, with.chitch, ignoreCase)
        return self
    }

    @inlinable @inline(__always)
    @discardableResult
    public func reserveCapacity(_ newCapacity: Int) -> Self {
        if newCapacity > chitch.capacity {
            chitch_make_mutable(&chitch)
            chitch_resize(&chitch, newCapacity)
        }
        return self
    }

    @inlinable @inline(__always)
    @discardableResult
    public func lowercase() -> Self {
        lastHash = 0
        chitch_make_mutable(&chitch)
        chitch_tolower_raw(chitch.mutableData, chitch.count)
        return self
    }

    @inlinable @inline(__always)
    @discardableResult
    public func uppercase() -> Self {
        lastHash = 0
        chitch_make_mutable(&chitch)
        chitch_toupper_raw(chitch.mutableData, chitch.count)
        return self
    }

    @inlinable @inline(__always)
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

    @inlinable @inline(__always)
    @discardableResult
    public func append(_ bytes: UnsafePointer<UInt8>, count: Int) -> Self {
        lastHash = 0
        chitch_make_mutable(&chitch)
        chitch_concat(&chitch, bytes, count)
        return self
    }

    @inlinable @inline(__always)
    @discardableResult
    public func append(_ bytes: UnsafeMutablePointer<UInt8>, count: Int) -> Self {
        lastHash = 0
        chitch_make_mutable(&chitch)
        chitch_concat(&chitch, bytes, count)
        return self
    }

    @inlinable @inline(__always)
    @discardableResult
    public func append(_ hitch: Hitchable) -> Self {
        lastHash = 0
        chitch_make_mutable(&chitch)
        chitch_concat(&chitch, hitch.raw(), hitch.count)
        return self
    }

    @inlinable @inline(__always)
    @discardableResult
    public func append(_ string: String) -> Self {
        lastHash = 0
        chitch_make_mutable(&chitch)
        chitch_using(string) { string_raw, string_count in
            chitch_concat(&chitch, string_raw, string_count)
        }
        return self
    }

    @inlinable @inline(__always)
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

    @inlinable @inline(__always)
    @discardableResult
    public func append(_ char: UInt8) -> Self {
        lastHash = 0
        chitch_make_mutable(&chitch)
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
        lastHash = 0
        chitch_make_mutable(&chitch)
        data.withUnsafeBytes { unsafeRawBufferPointer in
            let unsafeBufferPointer = unsafeRawBufferPointer.bindMemory(to: UInt8.self)
            guard let bytes = unsafeBufferPointer.baseAddress else { return }
            chitch_concat(&chitch, bytes, data.count)
        }
        return self
    }

    @inlinable @inline(__always)
    @discardableResult
    public func insert(_ hitch: Hitch, index: Int) -> Self {
        lastHash = 0
        chitch_make_mutable(&chitch)
        chitch_insert_raw(&chitch, index, hitch.raw(), hitch.count)
        return self
    }

    @inlinable @inline(__always)
    @discardableResult
    public func insert(_ string: String, index: Int) -> Self {
        lastHash = 0
        chitch_make_mutable(&chitch)
        chitch_insert_cstring(&chitch, index, string)
        return self
    }

    @inlinable @inline(__always)
    @discardableResult
    public func insert(_ string: String, index: Int, precision: Int?) -> Self {
        lastHash = 0
        chitch_make_mutable(&chitch)
        chitch_using(string) { string_raw, _ in
            var length = string.count
            if let precision = precision {
                var ptr = string_raw
                while ptr.pointee != 0 {
                    let c = UInt8(ptr.pointee)
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

    @inlinable @inline(__always)
    @discardableResult
    public func insert(_ char: UInt8, index: Int) -> Self {
        lastHash = 0
        chitch_make_mutable(&chitch)
        chitch_insert_char(&chitch, index, char)
        return self
    }

    @inlinable @inline(__always)
    @discardableResult
    public func insert<T: FixedWidthInteger>(number: T, index: Int) -> Self {
        lastHash = 0
        chitch_make_mutable(&chitch)
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
        lastHash = 0
        chitch_make_mutable(&chitch)
        data.withUnsafeBytes { unsafeRawBufferPointer in
            let unsafeBufferPointer = unsafeRawBufferPointer.bindMemory(to: UInt8.self)
            guard let bytes = unsafeBufferPointer.baseAddress else { return }
            chitch_insert_raw(&chitch, index, bytes, data.count)
        }
        return self
    }

    @inlinable @inline(__always)
    @discardableResult
    public func trim() -> Self {
        lastHash = 0
        chitch_make_mutable(&chitch)
        chitch_trim(&chitch)
        return self
    }

    @inlinable @inline(__always)
    @discardableResult
    public func unescape() -> Hitch {
        lastHash = 0
        chitch_make_mutable(&chitch)
        guard let raw = chitch.mutableData else { return self }
        count = unescapeBinary(data: raw,
                               count: count)
        return self
    }

    @inlinable @inline(__always)
    @discardableResult
    public func unescaped() -> Hitch {
        // returns self if there was nothing to unescape, or silo'd halfhitch if there was
        guard let raw = raw() else { return self }

        var local: UInt8 = .backSlash
        guard chitch_contains_raw(raw, count, &local, 1) == true else { return self }

        return Hitch(hitch: self).unescape()
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

}
