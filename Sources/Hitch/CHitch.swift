import Foundation

@usableFromInline
internal let nullPad = 2

// Ported from cHitch.c.

@usableFromInline
struct Needle: Equatable {
    @usableFromInline let bytes: UnsafePointer<UInt8>
    @usableFromInline let count: Int
    @usableFromInline let startingByte: UInt8
    
    @usableFromInline let hitch: Hitch
    
    @usableFromInline
    init?(_ hitch: Hitch) {
        guard let bytes = hitch.raw() else { return nil }
        self.hitch = hitch
        self.bytes = bytes
        self.count = hitch.count
        self.startingByte = bytes[0]
    }
}

@usableFromInline
let epochFormat: DateFormatter = {
    let format = DateFormatter()
    format.dateFormat = "MM/dd/yyyy hh:mm:ss a"
    format.timeZone = TimeZone(secondsFromGMT: 0)
    format.locale = Locale(identifier: "en_US_POSIX")
    return format
}()

@usableFromInline
struct CHitch {
    @usableFromInline
    var capacity: Int = 0
    @usableFromInline
    var count: Int = 0
    @usableFromInline
    var copyOnWrite: Bool = false
    @usableFromInline
    var mutableData: UnsafeMutablePointer<UInt8>?
    @usableFromInline
    var castedMutableData: UnsafePointer<UInt8>?
    @usableFromInline
    var staticData: UnsafePointer<UInt8>?

    public init() { }

    @inlinable
    var universalData: UnsafePointer<UInt8>? {
        if castedMutableData != nil { return castedMutableData }
        return staticData
    }
}

// MARK: - Utility

 @inlinable
func nullify(_ chitch: inout CHitch) {
    if chitch.count <= chitch.capacity {
        chitch.mutableData?[chitch.count] = 0
    } else {
        chitch_sanity(&chitch, chitch.capacity + 1)
        chitch.mutableData?[chitch.count] = 0
    }
}

 @inlinable
func memcasecmp(_ ptr1: UnsafePointer<UInt8>,
                _ ptr2: UnsafePointer<UInt8>,
                _ count: Int,
                _ ignoreCase: Bool) -> Int32 {
    if ignoreCase {
        return ptr1.withMemoryRebound(to: CChar.self, capacity: count) { ptr1 in
            return ptr2.withMemoryRebound(to: CChar.self, capacity: count) { ptr2 in
#if os(Windows)
                return _strnicmp(ptr1, ptr2, count)
#else
                return strncasecmp(ptr1, ptr2, count)
#endif
            }
        }
    }
    return memcmp(ptr1, ptr2, count)
}

 @inlinable
func isDigit(_ x: UInt8) -> Bool {
    return x >= .zero && x <= .nine
}

 @inlinable
func toUpper(_ x: UInt8) -> UInt8 {
    return ((x >= .a && x <= .z) ? x - 0x20 : x)
}

 @inlinable
func toLower(_ x: UInt8) -> UInt8 {
    return ((x >= .A && x <= .Z) ? x + 0x20 : x)
}

 @inlinable
func isWhitespace(_ x: UInt8) -> Bool {
    return x == .tab || x == .newLine || x == .carriageReturn || x == .space
}

// MARK: - Memory Allocation

 @inlinable
func chitch_internal_malloc(_ capacity: Int) -> UnsafeMutablePointer<UInt8>? {
    return malloc(capacity)?.bindMemory(to: UInt8.self, capacity: capacity)
}

 @inlinable
func chitch_internal_realloc(_ ptr: UnsafeMutablePointer<UInt8>?, _ capacity: Int) -> UnsafeMutablePointer<UInt8>? {
    guard let ptr = ptr else { return nil }
    return realloc(ptr, capacity)?.bindMemory(to: UInt8.self, capacity: capacity)
}

 @inlinable
func chitch_internal_free(_ ptr: UnsafeMutablePointer<UInt8>?) {
    guard let ptr = ptr else { return }
    free(ptr)
}

// MARK: - INIT

 @inlinable
func chitch_empty() -> CHitch {
    return CHitch()
}

 @inlinable
func chitch_static(_ raw: UnsafePointer<UInt8>?, _ count: Int, _ copyOnWrite: Bool) -> CHitch {
    var c = CHitch()
    c.count = count
    c.capacity = count
    c.staticData = raw
    c.copyOnWrite = copyOnWrite
    return c
}

 @inlinable
func chitch_init_capacity(_ capacity: Int) -> CHitch {
    var c = CHitch()
    c.count = 0
    c.capacity = capacity
    c.mutableData = chitch_internal_malloc(capacity + nullPad)
    c.castedMutableData = UnsafePointer(c.mutableData)
    nullify(&c)
    return c
}

 @inlinable
func chitch_init_raw(_ raw: UnsafeMutablePointer<UInt8>?, _ count: Int) -> CHitch {
    guard let raw = raw else { return chitch_empty() }
    var c = CHitch()
    c.count = count
    c.capacity = count
    c.mutableData = chitch_internal_malloc(count + nullPad)
    c.castedMutableData = UnsafePointer(c.mutableData)
    c.mutableData?.assign(from: raw, count: count)
    nullify(&c)
    return c
}

 @inlinable
func chitch_init_raw(_ raw: UnsafePointer<UInt8>?, _ count: Int) -> CHitch {
    guard let raw = raw else { return chitch_empty() }
    var c = CHitch()
    c.count = count
    c.capacity = count
    c.mutableData = chitch_internal_malloc(count + nullPad)
    c.castedMutableData = UnsafePointer(c.mutableData)
    c.mutableData?.assign(from: raw, count: count)
    nullify(&c)
    return c
}

@inlinable
func chitch_init_own(_ raw: UnsafeMutablePointer<UInt8>?, _ count: Int) -> CHitch {
   guard let raw = raw else { return chitch_empty() }
   var c = CHitch()
   c.count = count
   c.capacity = count
   c.mutableData = raw
   c.castedMutableData = UnsafePointer(c.mutableData)
   c.mutableData?.assign(from: raw, count: count)
   nullify(&c)
   return c
}

 @inlinable
func chitch_init_string(_ string: String) -> CHitch {
    return chitch_using(string, chitch_init_raw)
}

 @inlinable
func chitch_init_substring(_ c0: CHitch, _ lhs_positions: Int, _ rhs_positions: Int) -> CHitch {
    let size = rhs_positions - lhs_positions
    guard size > 0 && size <= c0.count else { return CHitch() }
    guard lhs_positions >= 0 && lhs_positions <= c0.count else { return CHitch() }
    guard rhs_positions >= 0 && rhs_positions <= c0.count else { return CHitch() }

    if let c0_data = c0.mutableData {
        return chitch_init_raw(c0_data + lhs_positions, size)
    }
    if let c0_data = c0.staticData {
        return chitch_init_raw(c0_data + lhs_positions, size)
    }
    return CHitch()
}

 @inlinable
func chitch_init_substring_raw(_ raw: UnsafePointer<UInt8>?, _ count: Int, _ lhs_positions: Int, _ rhs_positions: Int) -> CHitch {
    guard let raw = raw else { return chitch_empty() }
    let size = rhs_positions - lhs_positions
    guard size > 0 && size <= count else { return CHitch() }
    guard lhs_positions >= 0 && lhs_positions <= count else { return CHitch() }
    guard rhs_positions >= 0 && rhs_positions <= count else { return CHitch() }
    return chitch_init_raw(raw + lhs_positions, size)
}

 @inlinable
func chitch_dealloc(_ chitch: inout CHitch) {
    chitch_internal_free(chitch.mutableData)
    chitch.mutableData = nil
    chitch.capacity = 0
    chitch.count = 0
    chitch.mutableData = nil
    chitch.castedMutableData = nil
    chitch.staticData = nil
}

 @inlinable
func chitch_make_mutable(_ c0: inout CHitch) {
    if let c0_data = c0.staticData {
        if c0.copyOnWrite == false {
            #if DEBUG
            fatalError("Mutating method called on Hitchable where copyOnWrite is set to false")
            #else
            print("warning: attempted to mutate a Hitchable where copyOnWrite is set to false")
            return
            #endif
        }
        c0 = chitch_init_raw(UnsafeMutablePointer(mutating: c0_data), c0.count)
    }
}

 @inlinable
func chitch_realloc(_ c0: inout CHitch, _ newCapacity: Int) {
    // Note: UnsafeMutablePointer appears to be missing a realloc!
    guard newCapacity != c0.capacity else { return }

    if let c0_data = c0.mutableData {
        c0.count = min(c0.count, newCapacity)
        c0.capacity = newCapacity
        c0.mutableData = chitch_internal_realloc(c0_data, newCapacity + nullPad)
        c0.castedMutableData = UnsafePointer(c0.mutableData)
        nullify(&c0)
        return
    }
    if let _ = c0.staticData {
        return
    }
    c0 = chitch_init_capacity(newCapacity)
}

 @inlinable
func chitch_resize(_ c0: inout CHitch, _ newCapacity: Int) {
    if newCapacity > c0.capacity {
        chitch_realloc(&c0, newCapacity)
    } else if newCapacity < c0.capacity {
        c0.count = newCapacity
        nullify(&c0)
    }
}

 @inlinable
func chitch_sanity(_ c0: inout CHitch, _ desiredCapacity: Int) {
    if desiredCapacity > c0.capacity {
        chitch_realloc(&c0, desiredCapacity)
    }
}

// MARK: - MUTATING METHODS

 @inlinable
func chitch_tolower_raw(_ lhs: UnsafeMutablePointer<UInt8>?, _ lhs_count: Int) {
    guard lhs_count > 0 else { return }
    guard let lhs = lhs else { return }

    var ptr = lhs
    let end = lhs + lhs_count
    var c: UInt8 = 0
    while ptr < end {
        c = ptr[0]
        ptr[0] = toLower(c)
        ptr += 1
    }
}

 @inlinable
func chitch_toupper_raw(_ lhs: UnsafeMutablePointer<UInt8>?, _ lhs_count: Int) {
    guard lhs_count > 0 else { return }
    guard let lhs = lhs else { return }

    var ptr = lhs
    let end = lhs + lhs_count
    var c: UInt8 = 0
    while ptr < end {
        c = ptr[0]
        ptr[0] = toUpper(c)
        ptr += 1
    }
}

 @inlinable
func chitch_trim(_ c0: inout CHitch) {
    guard let c0_data = c0.mutableData else { return }

    var start = c0_data
    var end = c0_data + c0.count - 1

    var c = start[0]
    while start < end && isWhitespace(c) {
        start += 1
        c = start[0]
    }

    c = end[0]
    while end > start && isWhitespace(c) {
        end -= 1
        c = end[0]
    }

    c0.count = end - start + 1
    
    if start == c0.mutableData {
        nullify(&c0)
        return
    }
    memmove(c0_data, start, c0.count)
    nullify(&c0)
}

 @inlinable
func chitch_replace(_ c0: inout CHitch, _ find: CHitch, _ replace: CHitch, _ ignoreCase: Bool) {
    guard let find_data = find.universalData else { return }
    let replace_data = replace.universalData

    let c0_count = c0.count
    let find_count = find.count
    let replace_count = replace.count

    let find_start_lower = toLower(find_data[0])
    let find_start_upper = toUpper(find_data[0])

    // Expansion: our array is going to need to grow before we can perform the replacement
    if replace_count > find_count {
        // Figure out how big out final array needs to be, then resize c0
        var num_occurences = 0
        var nextOffset = 0
        while true {
            nextOffset = chitch_firstof_raw_offset(c0.mutableData, nextOffset, c0_count, find_data, find_count)
            if nextOffset < 0 {
                break
            }
            nextOffset += find_count
            num_occurences += 1
        }

        let capacity_required = c0_count + (replace_count - find_count) * num_occurences

        chitch_sanity(&c0, capacity_required)
        guard let c0_data = c0.mutableData else { return }

        // work our way from back to front, copying and replacing as we go
        let start = c0_data
        let old_end = c0_data + c0_count
        let new_end = c0_data + capacity_required

        var old_ptr_a = old_end
        var old_ptr_b = old_end
        var new_ptr = new_end

        var fix_count = 0

        while old_ptr_a >= start {
            // is this the thing we need to replace?
            if (old_ptr_a[0] == find_start_lower || old_ptr_a[0] == find_start_upper) &&
                old_ptr_a + find_count <= old_end &&
                memcasecmp(old_ptr_a, find_data, find_count, ignoreCase) == 0 {

                fix_count = old_ptr_b - (old_ptr_a + find_count)
                if fix_count > 0 {
                    memmove(new_ptr - fix_count, (old_ptr_a + find_count), fix_count)
                    new_ptr -= fix_count
                }

                new_ptr -= replace_count
                if let replace_data = replace_data {
                    memmove(new_ptr, replace_data, replace_count)
                }
                old_ptr_b = old_ptr_a
            }

            old_ptr_a -= 1
        }

        // final copy
        if old_ptr_a >= start {
            fix_count = old_ptr_b - (old_ptr_a + find_count)
            if fix_count > 0 {
                memmove((old_ptr_a + find_count), new_ptr - fix_count, fix_count)
            }
        }

        c0.count = capacity_required
        nullify(&c0)
    } else {
        // Our array can stay the same size as we perform the replacement. Since we can go front to
        // back we don't need to know the number of occurrences a priori.
        guard let c0_data = c0.mutableData else { return }

        // work our way from back to front, copying and replacing as we go
        let start = c0_data
        let old_end = c0_data + c0_count

        var old_ptr = start
        var new_ptr = start

        while old_ptr <= old_end {
            // is this the thing we need to replace?
            if (old_ptr[0] == find_start_lower || old_ptr[0] == find_start_upper) &&
                old_ptr + find_count <= old_end &&
                    memcasecmp(old_ptr, find_data, find_count, ignoreCase) == 0 {
                old_ptr += find_count

                if let replace_data = replace_data {
                    memmove(new_ptr, replace_data, replace_count)
                }
                new_ptr += replace_count
            } else {
                new_ptr[0] = old_ptr[0]
                new_ptr += 1
                old_ptr += 1
            }
        }

        c0.count = (new_ptr - start) - 1
        nullify(&c0)
    }
}

 @inlinable
func chitch_replace(_ c0: inout CHitch, _ from: Int, _ to: Int, _ replace: CHitch) {
    if from == to && replace.count == 0 {
        return
    }

    let replace_data = replace.universalData

    let find_count = to - from

    let c0_count = c0.count
    let replace_count = replace.count

    // Expansion: our array is going to need to grow before we can perform the replacement
    if replace_count > find_count {
        let capacity_required = c0_count + (replace_count - find_count)

        chitch_sanity(&c0, capacity_required)
        guard let c0_data = c0.mutableData else { return }

        let from_ptr = c0_data + from

        // work our way from back to front, copying and replacing as we go
        let start = c0_data
        let old_end = c0_data + c0_count
        let new_end = c0_data + capacity_required

        var old_ptr_a = old_end
        var old_ptr_b = old_end
        var new_ptr = new_end

        var fix_count = 0

        while old_ptr_a >= start {
            // is this the thing we need to replace?
            if old_ptr_a == from_ptr {
                fix_count = old_ptr_b - (old_ptr_a + find_count)
                if fix_count > 0 {
                    memmove(new_ptr - fix_count, (old_ptr_a + find_count), fix_count)
                    new_ptr -= fix_count
                }

                new_ptr -= replace_count

                if let replace_data = replace_data {
                    memmove(new_ptr, replace_data, replace_count)
                }
                old_ptr_b = old_ptr_a
            }

            old_ptr_a -= 1
        }

        // final copy
        if old_ptr_a >= start {
            fix_count = old_ptr_b - (old_ptr_a + find_count)
            if fix_count > 0 {
                memmove((old_ptr_a + find_count), new_ptr - fix_count, fix_count)
            }
        }

        c0.count = capacity_required
        nullify(&c0)
    } else {
        // Our array can stay the same size as we perform the replacement. Since we can go front to
        // back we don't need to know the number of occurrences a priori.
        guard let c0_data = c0.mutableData else { return }

        let from_ptr = c0_data + from

        // work our way from back to front, copying and replacing as we go
        let start = c0_data
        let old_end = c0_data + c0_count

        var old_ptr = start
        var new_ptr = start

        while old_ptr <= old_end {
            // is this the thing we need to replace?
            if old_ptr == from_ptr {
                old_ptr += find_count

                if let replace_data = replace_data {
                    memmove(new_ptr, replace_data, replace_count)
                }
                new_ptr += replace_count
            } else {
                new_ptr[0] = old_ptr[0]
                new_ptr += 1
                old_ptr += 1
            }
        }

        c0.count = (new_ptr - start) - 1
        if c0.count < 0 {
            c0.count = 0
        }
        nullify(&c0)
    }
}

 @inlinable
func chitch_concat(_ c0: inout CHitch, _ rhs: UnsafePointer<UInt8>?, _ rhs_count: Int) {
    guard rhs_count > 0 else { return }
    guard let rhs = rhs else { return }

    chitch_sanity(&c0, c0.count + rhs_count)
    guard let c0_data = c0.mutableData else { return }

    (c0_data + c0.count).assign(from: rhs, count: rhs_count)
    c0.count += rhs_count
    nullify(&c0)
}

 @inlinable
func chitch_concat_char(_ c0: inout CHitch, _ rhs: UInt8) {

    chitch_sanity(&c0, c0.count + 1)
    guard let c0_data = c0.mutableData else { return }

    c0_data[c0.count] = rhs
    c0.count += 1
    nullify(&c0)
}

 @inlinable
func chitch_concat_precision(_ c0: inout CHitch, _ rhs_in: UnsafePointer<UInt8>?, _ rhs_count: Int, _ precision: Int) {
    guard rhs_count > 0 else { return }
    guard var rhs = rhs_in else { return }

    chitch_sanity(&c0, c0.count + rhs_count)
    guard let c0_data = c0.mutableData else { return }

    // treat each '.' found with digits on boths sides as if it were a double, include only precision number of decimal places
    var ptr = c0_data + c0.count
    let end = rhs + rhs_count

    ptr[0] = rhs[0]
    ptr += 1
    rhs += 1

    while rhs < end {
        if rhs[0] == .dot && isDigit(rhs[-1]) && isDigit(rhs[1]) {
            ptr[0] = rhs[0]
            ptr += 1; rhs += 1

            // copy over the precisions
            var precisionCount = precision
            while rhs < end && precisionCount > 0 {
                precisionCount -= 1

                if isDigit(rhs[0]) == false {
                    break
                }

                ptr[0] = rhs[0]
                ptr += 1; rhs += 1
            }

            // skip any more digits
            while precisionCount == 0 && rhs < end && isDigit(rhs[0]) {
                rhs += 1
            }

        } else {
            ptr[0] = rhs[0]
            ptr += 1; rhs += 1
        }
    }

    c0.count = ptr - c0_data
    nullify(&c0)
}

 @inlinable
func chitch_insert_raw(_ c0: inout CHitch, _ position_in: Int, _ rhs: UnsafePointer<UInt8>?, _ rhs_count: Int) {
    guard let rhs = rhs else { return }

    var position = position_in

    if position < 0 { position = 0 }
    if position >= c0.count {
        return chitch_concat(&c0, rhs, rhs_count)
    }

    chitch_sanity(&c0, c0.count + rhs_count)
    guard let c0_data = c0.mutableData else { return }

    // Start at end and copy back until old count + rhs_count to make room
    // for simultaneous copy operation
    var ptr = c0_data + c0.count
    let start = c0_data + position
    while ptr >= start {
        ptr[rhs_count] = ptr[0]
        ptr -= 1
    }

    // simulataneous insert and copy
    var src_ptr = rhs
    var dst_ptr = c0_data + position
    let end = dst_ptr + rhs_count
    while dst_ptr < end {
        dst_ptr[0] = src_ptr[0]
        dst_ptr += 1
        src_ptr += 1
    }

    c0.count += rhs_count
    nullify(&c0)
}

 @inlinable
func chitch_insert_cstring(_ c0: inout CHitch, _ position: Int, _ string: String) {
    return chitch_using(string) { string_raw, string_count in
        return chitch_insert_raw(&c0, position, string_raw, string_count)
    }
}

 @inlinable
func chitch_insert_char(_ c0: inout CHitch, _ position: Int, _ rhs: UInt8) {
    return chitch_insert_raw(&c0, position, [rhs], 1)
}

 @inlinable
func chitch_insert_int(_ c0: inout CHitch, _ position: Int, _ rhs_in: Int) {
    switch rhs_in {
    case 0: return chitch_insert_char(&c0, position, .zero)
    case 1: return chitch_insert_char(&c0, position, .one)
    case 2: return chitch_insert_char(&c0, position, .two)
    case 3: return chitch_insert_char(&c0, position, .three)
    case 4: return chitch_insert_char(&c0, position, .four)
    case 5: return chitch_insert_char(&c0, position, .five)
    case 6: return chitch_insert_char(&c0, position, .six)
    case 7: return chitch_insert_char(&c0, position, .seven)
    case 8: return chitch_insert_char(&c0, position, .eight)
    case 9: return chitch_insert_char(&c0, position, .nine)
    default: break
    }

    var s = [UInt8](repeating: 0, count: 128)
    return s.withUnsafeMutableBytes { buffer in
        guard let raw = buffer.baseAddress?.bindMemory(to: UInt8.self, capacity: 128) else { return }

        let end = raw + 128 - 1
        var ptr = end
        var len = 0
        var rhs = rhs_in

        if rhs >= 0 && rhs <= 9 {
            ptr[0] = .zero + UInt8(rhs)
            ptr -= 1
            len = 1
        } else {
            let neg = (rhs < 0)
            if neg {
                rhs = -rhs
            }

            while ptr > raw && rhs > 0 {
                ptr[0] = .zero + UInt8(rhs % 10)
                ptr -= 1
                rhs /= 10
            }

            if neg {
                ptr[0] = .minus
                ptr -= 1
            }

            len = end - ptr
        }

        return chitch_insert_raw(&c0, position, ptr+1, len)
    }

}

// MARK: - IMMUTABLE METHODS

 @inlinable
func chitch_hash_raw(_ lhs: UnsafePointer<UInt8>?,
                     _ lhs_count: Int) -> Int {
    guard let lhs = lhs else { return 0 }
    let lhsEnd = lhs + min(lhs_count, 128)
    var lhsPtr = lhs
    var hash: Int = 5381
    var idx: Int = 0
    while lhsPtr < lhsEnd {
        hash = (( hash << 5) &+ hash) &+ Int(lhsPtr[0])
        idx += 1
        lhsPtr += 1
    }
    return hash
}

 @inlinable
func chitch_multihash_raw(_ lhs: UnsafePointer<UInt8>?,
                          _ lhs_count: Int) -> Int {
    guard let lhs = lhs else { return 0 }
    let lhsEnd = lhs + min(lhs_count, 128)
    var lhsPtr = lhs
    var hash: Int = 5381
    var idx: Int = 0
    while lhsPtr < lhsEnd {
        hash = (( hash << 5) &+ hash) &+ Int(lhsPtr[0])
        idx += 1
        lhsPtr += 1
    }
    return hash
}

 @inlinable
func chitch_cmp_raw(_ lhs: UnsafePointer<UInt8>?,
                    _ lhs_count: Int,
                    _ rhs: UnsafePointer<UInt8>?,
                    _ rhs_count: Int) -> Int {
    guard lhs != nil && rhs != nil else { return 0 }
    guard let lhs = lhs else { return -1 }
    guard let rhs = rhs else { return -1 }
    if lhs_count < rhs_count {
        return -1
    } else if lhs_count > rhs_count {
        return 1
    }

    if lhs == rhs {
        return 0
    }

    let lhsEnd = lhs + lhs_count
    var lhsPtr = lhs
    var rhsPtr = rhs
    while lhsPtr < lhsEnd {
        if lhsPtr[0] != rhsPtr[0] {
            return Int(lhsPtr[0]) - Int(rhsPtr[0])
        }
        lhsPtr += 1
        rhsPtr += 1
    }

    return 0
}

 @inlinable
func chitch_equal_raw(_ lhs: UnsafePointer<UInt8>?,
                      _ lhs_count: Int,
                      _ rhs: UnsafePointer<UInt8>?,
                      _ rhs_count: Int) -> Bool {
    if lhs == nil && rhs == nil { return true }
    guard lhs != nil && rhs != nil else { return false }
    guard let lhs = lhs else { return false }
    guard let rhs = rhs else { return false }
    guard lhs_count == rhs_count else { return false }
    guard lhs != rhs else { return true }
    if lhs_count > 0 && lhs[0] != rhs[0] { return false }
    return memcmp(lhs, rhs, rhs_count) == 0
}

 @inlinable
func chitch_equal_caseless_raw(_ lhs: UnsafePointer<UInt8>?,
                      _ lhs_count: Int,
                      _ rhs: UnsafePointer<UInt8>?,
                      _ rhs_count: Int) -> Bool {
    if lhs == nil && rhs == nil { return true }
    guard lhs != nil && rhs != nil else { return false }
    guard let lhs = lhs else { return false }
    guard let rhs = rhs else { return false }
    guard lhs_count == rhs_count else { return false }
    guard lhs != rhs else { return true }
    if lhs_count > 0 && lhs[0] != rhs[0] { return false }
    return memcasecmp(lhs, rhs, rhs_count, true) == 0
}

 @inlinable
func chitch_contains_raw(_ haystack: UnsafePointer<UInt8>?,
                         _ haystack_count: Int,
                         _ needle: UnsafePointer<UInt8>?,
                         _ needle_count: Int) -> Bool {
    return chitch_firstof_raw(haystack, haystack_count, needle, needle_count) >= 0
}

 @inlinable
func chitch_firstof_raw_offset(_ haystack: UnsafePointer<UInt8>?,
                               _ haystack_offset: Int,
                               _ haystack_count: Int,
                               _ needle: UnsafePointer<UInt8>?,
                               _ needle_count: Int) -> Int {
    guard haystack_count >= 0 else { return -1 }
    guard needle_count > 0 else { return 0 }
    if needle == nil && haystack == nil { return 0 }
    guard let haystack = haystack else { return -1 }
    guard let needle = needle else { return -1 }

    let result = chitch_firstof_raw(haystack + haystack_offset, haystack_count - haystack_offset, needle, needle_count)
    if result < 0 {
        return result
    }
    return result + haystack_offset
}

 @inlinable
func chitch_firstof_raw(_ haystack: UnsafePointer<UInt8>?,
                        _ haystack_count: Int,
                        _ needle: UnsafePointer<UInt8>?,
                        _ needle_count: Int) -> Int {
    guard haystack_count >= 0 else { return -1 }
    guard needle_count > 0 else { return 0 }
    if needle == nil && haystack == nil { return 0 }
    guard let haystack = haystack else { return -1 }
    guard let needle = needle else { return -1 }
    guard needle_count <= haystack_count else { return -1 }

    /*
    if needle_count > 1,
       haystack[haystack_count] == 0,
       needle[needle_count] == 0 {
        if let found = strstr(haystack, needle) {
            return found.withMemoryRebound(to: UInt8.self, capacity: needle_count) { pointer in
                return pointer - UnsafeMutablePointer(mutating: haystack)
            }
        }
        return -1
    }
    */
    
    let haystack_end = haystack + haystack_count - needle_count
    
    let needle_count_minus_one = needle_count - 1
    let needle_start_pointee = needle[0]
    let needle_end = needle + needle_count_minus_one
    let needle_end_pointee = needle_end[0]

    var ptr = haystack
    var ptr2 = haystack + needle_count_minus_one
    
    if needle_count == 1 {
        while ptr <= haystack_end {
            if ptr[0] == needle_start_pointee {
                return (ptr - haystack)
            }
            ptr += 1
        }
        return -1
    }
    
    while ptr <= haystack_end {
        if ptr.pointee == needle_start_pointee,
           ptr2.pointee == needle_end_pointee,
           memcmp(ptr, needle, needle_count) == 0 {
            return (ptr - haystack)
        }
        ptr += 1
        ptr2 += 1
    }

    return -1
}

 @inlinable
func chitch_lastof_raw(_ haystack: UnsafePointer<UInt8>?,
                       _ haystack_count: Int,
                       _ needle: UnsafePointer<UInt8>?,
                       _ needle_count: Int) -> Int {
    guard haystack_count >= 0 else { return -1 }
    guard needle_count > 0 else { return 0 }
    if needle == nil && haystack == nil { return 0 }
    guard let haystack = haystack else { return -1 }
    guard let needle = needle else { return -1 }
    guard needle_count <= haystack_count else { return -1 }

    let start = haystack
    let end = haystack + haystack_count - needle_count
    var ptr = end
    let needle_start = needle[0]

    var found = true

    while ptr >= start {
        if ptr[0] == needle_start {
            switch needle_count {
            case 1: return (ptr - haystack)
            case 2: if ptr[1] == needle[1] { return (ptr - haystack) }; break
            case 3: if ptr[1] == needle[1] && ptr[2] == needle[2] { return (ptr - haystack) }; break
            case 4: if ptr[1] == needle[1] && ptr[2] == needle[2] && ptr[3] == needle[3] { return (ptr - haystack) }; break
            case 5: if ptr[1] == needle[1] && ptr[2] == needle[2] && ptr[3] == needle[3] && ptr[4] == needle[4] { return (ptr - haystack) }; break
            case 6: if ptr[1] == needle[1] && ptr[2] == needle[2] && ptr[3] == needle[3] && ptr[4] == needle[4] && ptr[5] == needle[5] { return (ptr - haystack) }; break
            case 7: if ptr[1] == needle[1] && ptr[2] == needle[2] && ptr[3] == needle[3] && ptr[4] == needle[4] && ptr[5] == needle[5] && ptr[6] == needle[6] { return (ptr - haystack) }; break
            case 8: if ptr[1] == needle[1] && ptr[2] == needle[2] && ptr[3] == needle[3] && ptr[4] == needle[4] && ptr[5] == needle[5] && ptr[6] == needle[6] && ptr[7] == needle[7] { return (ptr - haystack) }; break
            case 9: if ptr[1] == needle[1] && ptr[2] == needle[2] && ptr[3] == needle[3] && ptr[4] == needle[4] && ptr[5] == needle[5] && ptr[6] == needle[6] && ptr[7] == needle[7] && ptr[8] == needle[8] { return (ptr - haystack) }; break
            case 10: if ptr[1] == needle[1] && ptr[2] == needle[2] && ptr[3] == needle[3] && ptr[4] == needle[4] && ptr[5] == needle[5] && ptr[6] == needle[6] && ptr[7] == needle[7] && ptr[8] == needle[8] && ptr[9] == needle[9] { return (ptr - haystack) }; break
            default:
                found = true
                for idx in 1..<needle_count {
                    if ptr[idx] != needle[idx] {
                        found = false
                        break
                    }
                }
                if found {
                    return (ptr - haystack)
                }
                break
            }
        }
        ptr -= 1
    }

    return -1
}

 @inlinable
func chitch_toepoch(_ c0: inout CHitch) -> Int {
    // Handles just this one date format. Timezone is always considered to be UTC
    // 4/30/2021 8:19:27 AM
    guard let c0_data = c0.universalData else { return 0 }
    guard c0.count > 0 else { return 0 }

    guard let stringValue = String(bytesNoCopy: UnsafeMutableRawPointer(mutating: c0_data), length: c0.count, encoding: .utf8, freeWhenDone: false) else { return 0 }
    guard let date = epochFormat.date(from: stringValue) else { return 0 }

    return Int(date.timeIntervalSince1970)
}

 @inlinable
func chitch_toepoch_raw(_ raw: UnsafePointer<UInt8>?,
                        _ count: Int) -> Int {
    // Handles just this one date format very efficiently. Timezone is always considered to be UTC
    // 4/30/2021 8:19:27 AM
    guard let raw = raw else { return 0 }
    guard count > 0 else { return 0 }
        
    var monthPtr = raw
    var monthCount = 0
    var dayPtr = raw
    var dayCount = 0
    var yearPtr = raw
    var yearCount = 0
    var hourPtr = raw
    var hourCount = 0
    var minutePtr = raw
    var minuteCount = 0
    var secondPtr = raw
    var secondCount = 0
    var ptr = raw
    let ptrEnd = raw + count
    
    // month
    monthPtr = ptr
    while ptr[0] != .forwardSlash && ptr < ptrEnd {
        ptr += 1
        monthCount += 1
    }
    ptr += 1
    guard ptr < ptrEnd else { return 0 }
    guard var tm_month = intFromBinary(data: monthPtr, count: monthCount) else { return 0 }
    
    // day
    dayPtr = ptr
    while ptr[0] != .forwardSlash && ptr < ptrEnd {
        ptr += 1
        dayCount += 1
    }
    ptr += 1
    guard ptr < ptrEnd else { return 0 }
    guard let tm_day = intFromBinary(data: dayPtr, count: dayCount) else { return 0 }
    
    // year
    yearPtr = ptr
    while ptr[0] != .space && ptr < ptrEnd {
        ptr += 1
        yearCount += 1
    }
    ptr += 1
    guard ptr < ptrEnd else { return 0 }
    guard var tm_year = intFromBinary(data: yearPtr, count: yearCount) else { return 0 }
    
    // hour
    hourPtr = ptr
    while ptr[0] != .colon && ptr < ptrEnd {
        ptr += 1
        hourCount += 1
    }
    ptr += 1
    guard ptr < ptrEnd else { return 0 }
    guard var tm_hour = intFromBinary(data: hourPtr, count: hourCount) else { return 0 }
    
    // minute
    minutePtr = ptr
    while ptr[0] != .colon && ptr < ptrEnd {
        ptr += 1
        minuteCount += 1
    }
    ptr += 1
    guard ptr < ptrEnd else { return 0 }
    guard let tm_min = intFromBinary(data: minutePtr, count: minuteCount) else { return 0 }
    
    // second
    secondPtr = ptr
    while ptr[0] != .space && ptr < ptrEnd {
        ptr += 1
        secondCount += 1
    }
    ptr += 1
    guard ptr < ptrEnd else { return 0 }
    guard let tm_sec = intFromBinary(data: secondPtr, count: secondCount) else { return 0 }
    
    if ptr[0] == .p || ptr[0] == .P {
        if tm_hour != 12 {
            tm_hour += 12
        }
    } else if tm_hour == 12 {
        tm_hour = 0
    }
        
    /* tm_sec seconds after the minute [0-60] */
    /* tm_min minutes after the hour [0-59] */
    /* tm_hour hours since midnight [0-23] */
    /* tm_mday day of the month [1-31] */
    /* tm_mon months since January [0-11] */
    /* tm_year years since 1900 */
    /* tm_yday days since January 1 [0-365] */
    /* tm_isdst Daylight Savings Time flag */
    /* tm_gmtoff offset from UTC in seconds */

    tm_year -= 1900
    tm_month -= 1
    
    // Source adapted from https://dox.ipxe.org/time_8c.html
    let days_to_month_start: [Int] = [ 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334 ]
    
    var is_leap_year = false
    if tm_year % 4 == 0 {
        is_leap_year = true
    }
    if tm_year % 100 == 0 {
        is_leap_year = false
    }
    if tm_year % 400 == 100 {
        is_leap_year = true
    }
    
    var tm_yday = (tm_day - 1) + days_to_month_start[ tm_month ]
    if tm_month >= 2 && is_leap_year {
        tm_yday += 1
    }
        
    return tm_sec + tm_min*60 + tm_hour*3600 + tm_yday*86400 + (tm_year-70)*31536000 + ((tm_year-69)/4)*86400 - ((tm_year-1)/100)*86400 + ((tm_year+299)/400)*86400
}

 @inlinable
func chitch_toepoch2_raw(_ raw: UnsafePointer<UInt8>?,
                        _ count: Int) -> Int {
    // Handles just this one date format very efficiently. Timezone is always considered to be UTC
    // 2023-03-16 20:59:32.808000
    guard let raw = raw else { return 0 }
    guard count > 0 else { return 0 }
        
    var monthPtr = raw
    var monthCount = 0
    var dayPtr = raw
    var dayCount = 0
    var yearPtr = raw
    var yearCount = 0
    var hourPtr = raw
    var hourCount = 0
    var minutePtr = raw
    var minuteCount = 0
    var secondPtr = raw
    var secondCount = 0
    var ptr = raw
    let ptrEnd = raw + count
    
    // year
    yearPtr = ptr
    while ptr[0] != .minus && ptr < ptrEnd {
        ptr += 1
        yearCount += 1
    }
    ptr += 1
    guard ptr < ptrEnd else { return 0 }
    guard var tm_year = intFromBinary(data: yearPtr, count: yearCount) else { return 0 }
    
    // month
    monthPtr = ptr
    while ptr[0] != .minus && ptr < ptrEnd {
        ptr += 1
        monthCount += 1
    }
    ptr += 1
    guard ptr < ptrEnd else { return 0 }
    guard var tm_month = intFromBinary(data: monthPtr, count: monthCount) else { return 0 }
    
    // day
    dayPtr = ptr
    while ptr[0] != .space && ptr < ptrEnd {
        ptr += 1
        dayCount += 1
    }
    ptr += 1
    guard ptr < ptrEnd else { return 0 }
    guard let tm_day = intFromBinary(data: dayPtr, count: dayCount) else { return 0 }
    
    
    
    // hour
    hourPtr = ptr
    while ptr[0] != .colon && ptr < ptrEnd {
        ptr += 1
        hourCount += 1
    }
    ptr += 1
    guard ptr < ptrEnd else { return 0 }
    guard let tm_hour = intFromBinary(data: hourPtr, count: hourCount) else { return 0 }
    
    // minute
    minutePtr = ptr
    while ptr[0] != .colon && ptr < ptrEnd {
        ptr += 1
        minuteCount += 1
    }
    ptr += 1
    guard ptr < ptrEnd else { return 0 }
    guard let tm_min = intFromBinary(data: minutePtr, count: minuteCount) else { return 0 }
    
    // second
    secondPtr = ptr
    while ptr[0] != .dot && ptr < ptrEnd {
        ptr += 1
        secondCount += 1
    }
    ptr += 1
    guard ptr < ptrEnd else { return 0 }
    guard let tm_sec = intFromBinary(data: secondPtr, count: secondCount) else { return 0 }
            
    /* tm_sec seconds after the minute [0-60] */
    /* tm_min minutes after the hour [0-59] */
    /* tm_hour hours since midnight [0-23] */
    /* tm_mday day of the month [1-31] */
    /* tm_mon months since January [0-11] */
    /* tm_year years since 1900 */
    /* tm_yday days since January 1 [0-365] */
    /* tm_isdst Daylight Savings Time flag */
    /* tm_gmtoff offset from UTC in seconds */

    tm_year -= 1900
    tm_month -= 1
    
    // Source adapted from https://dox.ipxe.org/time_8c.html
    let days_to_month_start: [Int] = [ 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334 ]
    
    var is_leap_year = false
    if tm_year % 4 == 0 {
        is_leap_year = true
    }
    if tm_year % 100 == 0 {
        is_leap_year = false
    }
    if tm_year % 400 == 100 {
        is_leap_year = true
    }
    
    var tm_yday = (tm_day - 1) + days_to_month_start[ tm_month ]
    if tm_month >= 2 && is_leap_year {
        tm_yday += 1
    }
        
    return tm_sec + tm_min*60 + tm_hour*3600 + tm_yday*86400 + (tm_year-70)*31536000 + ((tm_year-69)/4)*86400 - ((tm_year-1)/100)*86400 + ((tm_year+299)/400)*86400
}

 @inlinable
func chitch_toepochISO8601_raw(_ raw: UnsafePointer<UInt8>?,
                               _ count: Int) -> Int {
    // Handles just this one date format very efficiently. Timezone is always considered to be UTC
    // 2023-03-16 20:59:32.808000
    // 2023-05-10T21:28:17Z
    // 2024-08-14T21:00:47-04:00
    // 2024-08-14T21:00:47-0400
    guard let raw = raw else { return 0 }
    guard count > 0 else { return 0 }
        
    var monthPtr = raw
    var monthCount = 0
    var dayPtr = raw
    var dayCount = 0
    var yearPtr = raw
    var yearCount = 0
    var hourPtr = raw
    var hourCount = 0
    var minutePtr = raw
    var minuteCount = 0
    var secondPtr = raw
    var secondCount = 0
    var ptr = raw
    let ptrEnd = raw + count
    
    // year
    yearPtr = ptr
    while ptr[0] != .minus && ptr < ptrEnd {
        ptr += 1
        yearCount += 1
    }
    ptr += 1
    guard ptr < ptrEnd else { return 0 }
    guard var tm_year = intFromBinary(data: yearPtr, count: yearCount) else { return 0 }
    
    // month
    monthPtr = ptr
    while ptr[0] != .minus && ptr < ptrEnd {
        ptr += 1
        monthCount += 1
    }
    ptr += 1
    guard ptr < ptrEnd else { return 0 }
    guard var tm_month = intFromBinary(data: monthPtr, count: monthCount) else { return 0 }
    
    // day
    dayPtr = ptr
    while ptr[0] != .T && ptr < ptrEnd {
        ptr += 1
        dayCount += 1
    }
    ptr += 1
    guard ptr < ptrEnd else { return 0 }
    guard let tm_day = intFromBinary(data: dayPtr, count: dayCount) else { return 0 }
    
    
    
    // hour
    hourPtr = ptr
    while ptr[0] != .colon && ptr < ptrEnd {
        ptr += 1
        hourCount += 1
    }
    ptr += 1
    guard ptr < ptrEnd else { return 0 }
    guard let tm_hour = intFromBinary(data: hourPtr, count: hourCount) else { return 0 }
    
    // minute
    minutePtr = ptr
    while ptr[0] != .colon && ptr < ptrEnd {
        ptr += 1
        minuteCount += 1
    }
    ptr += 1
    guard ptr < ptrEnd else { return 0 }
    guard let tm_min = intFromBinary(data: minutePtr, count: minuteCount) else { return 0 }
    
    // second
    secondPtr = ptr
    while ptr[0] != .Z && ptr[0] != .minus && ptr[0] != .plus && ptr < ptrEnd {
        ptr += 1
        secondCount += 1
    }
    ptr += 1
    
    // timezone
    var tm_gmtoff = 0
    if ptr[0] == .Z {
        // already UTC
    } else if ptrEnd - ptr >= 4,
              ptr[-1] == .minus || ptr[-1] == .plus {
        let colonOffset = ptr[2] == .colon ? 1 : 0
        if let tzHours = intFromBinary(data: ptr, count: 2),
           let tzMinutes = intFromBinary(data: ptr+2+colonOffset, count: 2) {
            if ptr[-1] == .minus {
                tm_gmtoff += tzHours * 60 * 60
                tm_gmtoff += tzMinutes * 60
            } else {
                tm_gmtoff -= tzHours * 60 * 60
                tm_gmtoff -= tzMinutes * 60
            }
        }
    }
    
    guard ptr <= ptrEnd else { return 0 }
    guard let tm_sec = intFromBinary(data: secondPtr, count: secondCount) else { return 0 }
            
    /* tm_sec seconds after the minute [0-60] */
    /* tm_min minutes after the hour [0-59] */
    /* tm_hour hours since midnight [0-23] */
    /* tm_mday day of the month [1-31] */
    /* tm_mon months since January [0-11] */
    /* tm_year years since 1900 */
    /* tm_yday days since January 1 [0-365] */
    /* tm_isdst Daylight Savings Time flag */
    /* tm_gmtoff offset from UTC in seconds */

    tm_year -= 1900
    tm_month -= 1
    
    // Source adapted from https://dox.ipxe.org/time_8c.html
    let days_to_month_start: [Int] = [ 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334 ]
    
    var is_leap_year = false
    if tm_year % 4 == 0 {
        is_leap_year = true
    }
    if tm_year % 100 == 0 {
        is_leap_year = false
    }
    if tm_year % 400 == 100 {
        is_leap_year = true
    }
    
    var tm_yday = (tm_day - 1) + days_to_month_start[ tm_month ]
    if tm_month >= 2 && is_leap_year {
        tm_yday += 1
    }
        
    return tm_sec + tm_min*60 + tm_hour*3600 + tm_yday*86400 + (tm_year-70)*31536000 + ((tm_year-69)/4)*86400 - ((tm_year-1)/100)*86400 + ((tm_year+299)/400)*86400 + tm_gmtoff
}

@usableFromInline
func chitch_using<T>(_ string: String, _ block: (UnsafePointer<UInt8>, Int) -> T) -> T {
    return string.utf8CString.withUnsafeBytes { bytes in
        if let raw2 = bytes.baseAddress?.bindMemory(to: UInt8.self, capacity: bytes.count) {
            return block(raw2, bytes.count - 1)
        }
        
        return string.withCString { bytes in
            var ptr = bytes
            while ptr[0] != 0 {
                ptr += 1
            }
            let raw = UnsafeMutableRawPointer(mutating: bytes)
            let count = ptr - bytes
            let raw2 = raw.bindMemory(to: UInt8.self, capacity: count)
            return block(raw2, count)
        }
    }
}

// Given the data in a Hitch, encode it using base32 and characters which
// are "domain safe" (A-Z,a-z,0-9)
fileprivate let encodeTable: [UInt8] = [.A, .B, .C, .D, .E, .F, .G, .H, .I, .J, .K, .L, .M, .N, .O, .P, .Q, .R, .S, .T, .U, .V, .W, .X, .Y, .Z, .two, .three, .four, .five, .six, .seven]
fileprivate let pad: UInt8 = .minus

// Note: i hate this but without these broken out as then own methods
// the swift compiler is too slow.
 @inlinable
func chitch_base32_tableIdx4(v: UInt8, b: UInt8, c: UInt8, d: UInt8, e: UInt8) -> Int {
    return Int((v & b) << c | d >> e)
}

 @inlinable
func chitch_base32_tableIdx1_right(v: UInt8, b: UInt8, c: UInt8) -> Int {
    return Int((v & b) >> c)
}

 @inlinable
func chitch_base32_tableIdx1_left(v: UInt8, b: UInt8, c: UInt8) -> Int {
    return Int((v & b) << c)
}

 @inlinable
func chitch_base32_tableIdx2(v: UInt8, b: UInt8) -> Int {
    return Int(v & b)
}

 @inlinable
func chitch_base32_tableIdx0(v: UInt8, b: UInt8) -> Int {
    return Int(v >> b)
}

func chitch_base32_encode(data: Data) -> Hitch? {
    let original = Hitch(data: data)
    let result = Hitch(capacity: data.count * 8)
    
    guard let src_start = original.raw() else { return nil }
    let src_end = src_start + original.count
    
    var ptr = src_start
    while ptr <= src_end - 5 {
        result.append( encodeTable[chitch_base32_tableIdx0(v: ptr[0], b: 3)] )
        result.append( encodeTable[chitch_base32_tableIdx4(v: ptr[0], b: 0b00000111, c: 2, d: ptr[1], e: 6)] )
        result.append( encodeTable[chitch_base32_tableIdx1_right(v: ptr[1], b: 0b00111110, c: 1)] )
        result.append( encodeTable[chitch_base32_tableIdx4(v: ptr[1], b: 0b00000001, c: 4, d: ptr[2], e: 4)] )
        result.append( encodeTable[chitch_base32_tableIdx4(v: ptr[2], b: 0b00001111, c: 1, d: ptr[3], e: 7)] )
        result.append( encodeTable[chitch_base32_tableIdx1_right(v: ptr[3], b: 0b01111100, c: 2)] )
        result.append( encodeTable[chitch_base32_tableIdx4(v: ptr[3], b: 0b00000011, c: 3, d: ptr[4], e: 5)] )
        result.append( encodeTable[chitch_base32_tableIdx2(v: ptr[4], b: 0b00011111)] )
        ptr += 5
    }
    
    let extra = src_end - ptr
    
    switch extra {
    case 1:
        result.append( encodeTable[chitch_base32_tableIdx0(v: ptr[0], b: 3)] )
        result.append( encodeTable[chitch_base32_tableIdx4(v: ptr[0], b: 0b00000111, c: 2, d: ptr[1], e: 6)] )
    case 2:
        result.append( encodeTable[chitch_base32_tableIdx0(v: ptr[0], b: 3)] )
        result.append( encodeTable[chitch_base32_tableIdx4(v: ptr[0], b: 0b00000111, c: 2, d: ptr[1], e: 6)] )
        result.append( encodeTable[chitch_base32_tableIdx1_right(v: ptr[1], b: 0b00111110, c: 1)] )
        result.append( encodeTable[chitch_base32_tableIdx1_left(v: ptr[1], b: 0b00000001, c: 4)] )
    case 3:
        result.append( encodeTable[chitch_base32_tableIdx0(v: ptr[0], b: 3)] )
        result.append( encodeTable[chitch_base32_tableIdx4(v: ptr[0], b: 0b00000111, c: 2, d: ptr[1], e: 6)] )
        result.append( encodeTable[chitch_base32_tableIdx1_right(v: ptr[1], b: 0b00111110, c: 1)] )
        result.append( encodeTable[chitch_base32_tableIdx4(v: ptr[1], b: 0b00000001, c: 4, d: ptr[2], e: 4)] )
        result.append( encodeTable[chitch_base32_tableIdx4(v: ptr[2], b: 0b00001111, c: 1, d: ptr[3], e: 7)] )
    case 4:
        result.append( encodeTable[chitch_base32_tableIdx0(v: ptr[0], b: 3)] )
        result.append( encodeTable[chitch_base32_tableIdx4(v: ptr[0], b: 0b00000111, c: 2, d: ptr[1], e: 6)] )
        result.append( encodeTable[chitch_base32_tableIdx1_right(v: ptr[1], b: 0b00111110, c: 1)] )
        result.append( encodeTable[chitch_base32_tableIdx4(v: ptr[1], b: 0b00000001, c: 4, d: ptr[2], e: 4)] )
        result.append( encodeTable[chitch_base32_tableIdx4(v: ptr[2], b: 0b00001111, c: 1, d: ptr[3], e: 7)] )
        result.append( encodeTable[chitch_base32_tableIdx1_right(v: ptr[3], b: 0b01111100, c: 2)] )
        result.append( encodeTable[chitch_base32_tableIdx1_left(v: ptr[3], b: 0b00000011, c: 3)] )
    default:
        break
    }
    
    return result
}

let __: UInt8 = 255
let decodeTable: [UInt8] = [
    __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0x00 - 0x0F
    __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0x10 - 0x1F
    __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0x20 - 0x2F
    __,__,26,27, 28,29,30,31, __,__,__,__, __,__,__,__,  // 0x30 - 0x3F
    __, 0, 1, 2,  3, 4, 5, 6,  7, 8, 9,10, 11,12,13,14,  // 0x40 - 0x4F
    15,16,17,18, 19,20,21,22, 23,24,25,__, __,__,__,__,  // 0x50 - 0x5F
    __, 0, 1, 2,  3, 4, 5, 6,  7, 8, 9,10, 11,12,13,14,  // 0x60 - 0x6F
    15,16,17,18, 19,20,21,22, 23,24,25,__, __,__,__,__,  // 0x70 - 0x7F
    __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0x80 - 0x8F
    __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0x90 - 0x9F
    __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0xA0 - 0xAF
    __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0xB0 - 0xBF
    __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0xC0 - 0xCF
    __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0xD0 - 0xDF
    __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0xE0 - 0xEF
    __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0xF0 - 0xFF
]


func chitch_base32_decode(halfHitch original: HalfHitch) -> Data? {
    let result = Hitch(capacity: original.count / 8 + 5)
    
    guard let src_start = original.raw() else { return nil }
    let src_end = src_start + original.count
    
    // sanity check the string:
    var ptr = src_start
        
    // proceed with the decoding
    var value0: UInt8 = 0
    var value1: UInt8 = 0
    var value2: UInt8 = 0
    var value3: UInt8 = 0
    var value4: UInt8 = 0
    var value5: UInt8 = 0
    var value6: UInt8 = 0
    var value7: UInt8 = 0
    
    while ptr <= src_end - 8 {
        guard ptr[0] >= .A && ptr[0] <= .Z ||
                ptr[0] >= .a && ptr[0] <= .z ||
                ptr[0] >= .two && ptr[0] <= .seven ||
                ptr[0] == .minus else {
            return nil
        }
        
        value0 = decodeTable[Int(ptr[0])]
        value1 = decodeTable[Int(ptr[1])]
        value2 = decodeTable[Int(ptr[2])]
        value3 = decodeTable[Int(ptr[3])]
        value4 = decodeTable[Int(ptr[4])]
        value5 = decodeTable[Int(ptr[5])]
        value6 = decodeTable[Int(ptr[6])]
        value7 = decodeTable[Int(ptr[7])]
        
        result.append( value0 << 3 | value1 >> 2 )
        result.append( value1 << 6 | value2 << 1 | value3 >> 4 )
        result.append( value3 << 4 | value4 >> 1 )
        result.append( value4 << 7 | value5 << 2 | value6 >> 3 )
        result.append( value6 << 5 | value7 )
        
        ptr += 8
    }
    
    let extra = src_end - ptr
    
    switch extra {
    case 2:
        value0 = decodeTable[Int(ptr[0])]
        value1 = decodeTable[Int(ptr[1])]
        result.append( value0 << 3 | value1 >> 2 )
    case 4:
        value0 = decodeTable[Int(ptr[0])]
        value1 = decodeTable[Int(ptr[1])]
        value2 = decodeTable[Int(ptr[2])]
        value3 = decodeTable[Int(ptr[3])]
        result.append( value0 << 3 | value1 >> 2 )
        result.append( value1 << 6 | value2 << 1 | value3 >> 4 )
    case 5:
        value0 = decodeTable[Int(ptr[0])]
        value1 = decodeTable[Int(ptr[1])]
        value2 = decodeTable[Int(ptr[2])]
        value3 = decodeTable[Int(ptr[3])]
        value4 = decodeTable[Int(ptr[4])]
        result.append( value0 << 3 | value1 >> 2 )
        result.append( value1 << 6 | value2 << 1 | value3 >> 4 )
        result.append( value3 << 4 | value4 >> 1 )
    case 7:
        value0 = decodeTable[Int(ptr[0])]
        value1 = decodeTable[Int(ptr[1])]
        value2 = decodeTable[Int(ptr[2])]
        value3 = decodeTable[Int(ptr[3])]
        value4 = decodeTable[Int(ptr[4])]
        value5 = decodeTable[Int(ptr[5])]
        value6 = decodeTable[Int(ptr[6])]
        result.append( value0 << 3 | value1 >> 2 )
        result.append( value1 << 6 | value2 << 1 | value3 >> 4 )
        result.append( value3 << 4 | value4 >> 1 )
        result.append( value4 << 7 | value5 << 2 | value6 >> 3 )
    default:
        break
    }
    
    return result.dataCopy()
}


func chitch_extract_block(match prefix: HalfHitch,
                          source: HalfHitch) -> Hitch? {
    // Extracts a "code block" from the provided source after matching the
    // prefix. Think of this as an easy method for returning a function or
    // dictionary defined in a source file.
    guard let prefixPtr = prefix.raw() else { return nil }
    guard let sourcePtr = source.raw() else { return nil }

    let prefixCount = prefix.count
    let sourceCount = source.count
    
    let startPtr = sourcePtr
    let endPtr = sourcePtr + sourceCount
    var ptr = startPtr
    var prefixStartPtr = startPtr
    
    // 1. find prefix
    while ptr < (endPtr - prefixCount) {
        
        if ptr[0] == prefixPtr[0] &&
            ptr[1] == prefixPtr[1] {
            
            prefixStartPtr = ptr
            
            var isPrefix = true
            for idx in 0..<prefixCount-1 {
                if ptr[0] == prefix[idx] {
                    ptr += 1
                } else {
                    isPrefix = false
                    break
                }
            }
            
            if isPrefix {
                // continue until ending }, ignoring contents of all strings
                var bracketCount = 0
                while ptr < endPtr {
                    if ptr[0] == .openBracket {
                        bracketCount += 1
                    }
                    if ptr[0] == .closeBracket {
                        bracketCount -= 1
                        if (bracketCount <= 0) {
                            ptr += 1
                            break
                        }
                    }
                    if ptr[0] == .doubleQuote ||
                        ptr[0] == .singleQuote ||
                        ptr[0] == .backtick {
                        let endingChar = ptr[0]
                        
                        ptr += 1
                        while ptr < endPtr {
                            if ptr[0] == endingChar && ptr[-1] != .backSlash {
                                break
                            }
                            ptr += 1
                        }
                    }
                
                    ptr += 1
                }
                
                // make new substring
                return source.substring(prefixStartPtr - sourcePtr, ptr - sourcePtr)
            }
            
        } else {
            ptr += 1
        }
    }
    
    return nil
}
