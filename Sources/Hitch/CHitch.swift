import Foundation

// Ported from cHitch.c.

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
    var data: UnsafeMutablePointer<UInt8>?
}

// MARK: - Utility

@usableFromInline
func memcasecmp(_ ptr1: UnsafeMutablePointer<UInt8>,
                _ ptr2: UnsafeMutablePointer<UInt8>,
                _ count: Int,
                _ ignoreCase: Bool) -> Int32 {
    if ignoreCase {
        return ptr1.withMemoryRebound(to: CChar.self, capacity: count) { ptr1 in
            return ptr2.withMemoryRebound(to: CChar.self, capacity: count) { ptr2 in
                return strncasecmp(ptr1, ptr2, count)
            }
        }
    }
    return memcmp(ptr1, ptr2, count)
}

@usableFromInline
func isDigit(_ x: UInt8) -> Bool {
    return x >= .zero && x <= .nine
}

@usableFromInline
func toUpper(_ x: UInt8) -> UInt8 {
    return ((x >= .a && x <= .z) ? x - 0x20 : x)
}

@usableFromInline
func toLower(_ x: UInt8) -> UInt8 {
    return ((x >= .A && x <= .Z) ? x + 0x20 : x)
}

@usableFromInline
func isWhitespace(_ x: UInt8) -> Bool {
    return x == .tab || x == .newLine || x == .carriageReturn || x == .space
}

// MARK: - Memory Allocation

@usableFromInline
func chitch_internal_malloc(_ capacity: Int) -> UnsafeMutablePointer<UInt8>? {
    return malloc(capacity)?.bindMemory(to: UInt8.self, capacity: capacity)
}

@usableFromInline
func chitch_internal_realloc(_ ptr: UnsafeMutablePointer<UInt8>?, _ capacity: Int) -> UnsafeMutablePointer<UInt8>? {
    guard let ptr = ptr else { return nil }
    return realloc(ptr, capacity)?.bindMemory(to: UInt8.self, capacity: capacity)
}

@usableFromInline
func chitch_internal_free(_ ptr: UnsafeMutablePointer<UInt8>?) {
    guard let ptr = ptr else { return }
    free(ptr)
}

// MARK: - INIT

@usableFromInline
func chitch_empty() -> CHitch {
    return CHitch()
}

@usableFromInline
func chitch_init_capacity(_ capacity: Int) -> CHitch {
    var c = CHitch()
    c.count = 0
    c.capacity = capacity
    c.data = chitch_internal_malloc(capacity + 1)
    return c
}

@usableFromInline
func chitch_init_raw(_ raw: UnsafeMutablePointer<UInt8>?, _ count: Int) -> CHitch {
    guard let raw = raw else { return chitch_empty() }
    var c = CHitch()
    c.count = count
    c.capacity = count
    c.data = chitch_internal_malloc(count + 1)
    c.data?.assign(from: raw, count: count)
    return c
}

@usableFromInline
func chitch_init_raw(_ raw: UnsafePointer<UInt8>?, _ count: Int) -> CHitch {
    guard let raw = raw else { return chitch_empty() }
    var c = CHitch()
    c.count = count
    c.capacity = count
    c.data = chitch_internal_malloc(count + 1)
    c.data?.assign(from: raw, count: count)
    return c
}

@usableFromInline
func chitch_init_string(_ string: String) -> CHitch {
    return chitch_using(string, chitch_init_raw)
}

@usableFromInline
func chitch_init_substring(_ c0: CHitch, _ lhs_positions: Int, _ rhs_positions: Int) -> CHitch {
    let size = rhs_positions - lhs_positions
    guard size > 0 && size <= c0.count else { return CHitch() }
    guard lhs_positions >= 0 && lhs_positions <= c0.count else { return CHitch() }
    guard rhs_positions >= 0 && rhs_positions <= c0.count else { return CHitch() }
    guard let c0_data = c0.data else { return CHitch() }
    return chitch_init_raw(c0_data + lhs_positions, size)
}

@usableFromInline
func chitch_dealloc(_ chitch: inout CHitch) {
    chitch_internal_free(chitch.data)
}

@usableFromInline
func chitch_realloc(_ c0: inout CHitch, _ newCapacity: Int) {
    // Note: UnsafeMutablePointer appears to be missing a realloc!
    guard newCapacity != c0.capacity else { return }

    guard let c0_data = c0.data else {
        c0 = chitch_init_capacity(newCapacity)
        return
    }

    c0.count = min(c0.count, newCapacity)
    c0.capacity = newCapacity
    c0.data = chitch_internal_realloc(c0_data, newCapacity + 1)
}

@usableFromInline
func chitch_resize(_ c0: inout CHitch, _ newCapacity: Int) {
    if newCapacity > c0.capacity {
        chitch_realloc(&c0, newCapacity + 1)
    } else if newCapacity < c0.capacity {
        c0.count = newCapacity
    }
}

@usableFromInline
func chitch_sanity(_ c0: inout CHitch, _ desiredCapacity: Int) {
    if desiredCapacity > c0.capacity {
        chitch_realloc(&c0, desiredCapacity + 1)
    }
}

// MARK: - MUTATING METHODS

@usableFromInline
func chitch_tolower_raw(_ lhs: UnsafeMutablePointer<UInt8>?, _ lhs_count: Int) {
    guard lhs_count > 0 else { return }
    guard let lhs = lhs else { return }

    var ptr = lhs
    let end = lhs + lhs_count
    var c: UInt8 = 0
    while ptr < end {
        c = ptr.pointee
        ptr.pointee = toLower(c)
        ptr += 1
    }
}

@usableFromInline
func chitch_toupper_raw(_ lhs: UnsafeMutablePointer<UInt8>?, _ lhs_count: Int) {
    guard lhs_count > 0 else { return }
    guard let lhs = lhs else { return }

    var ptr = lhs
    let end = lhs + lhs_count
    var c: UInt8 = 0
    while ptr < end {
        c = ptr.pointee
        ptr.pointee = toUpper(c)
        ptr += 1
    }
}

@usableFromInline
func chitch_trim(_ c0: inout CHitch) {
    guard let c0_data = c0.data else { return }

    var start = c0_data
    var end = c0_data + c0.count - 1

    var c = start.pointee
    while start < end && isWhitespace(c) {
        start += 1
        c = start.pointee
    }

    c = end.pointee
    while end > start && isWhitespace(c) {
        end -= 1
        c = end.pointee
    }

    c0.count = end - start + 1
    if start == c0.data {
        return
    }
    memmove(c0_data, start, c0.count)
}

@usableFromInline
func chitch_replace(_ c0: inout CHitch, _ find: CHitch, _ replace: CHitch, _ ignoreCase: Bool) {
    guard let find_data = find.data else { return }
    guard let replace_data = replace.data else { return }

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
            nextOffset = chitch_firstof_raw_offset(c0.data, nextOffset, c0_count, find.data, find_count)
            if nextOffset < 0 {
                break
            }
            nextOffset += find_count
            num_occurences += 1
        }

        let capacity_required = c0_count + (replace_count - find_count) * num_occurences

        chitch_sanity(&c0, capacity_required)
        guard let c0_data = c0.data else { return }

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
            if (old_ptr_a.pointee == find_start_lower || old_ptr_a.pointee == find_start_upper) &&
                old_ptr_a + find_count <= old_end &&
                memcasecmp(old_ptr_a, find_data, find_count, ignoreCase) == 0 {

                fix_count = old_ptr_b - (old_ptr_a + find_count)
                if fix_count > 0 {
                    memmove(new_ptr - fix_count, (old_ptr_a + find_count), fix_count)
                    new_ptr -= fix_count
                }

                new_ptr -= replace_count
                memmove(new_ptr, replace_data, replace_count)
                old_ptr_b = old_ptr_a
            }

            old_ptr_a -= 1
        }

        // final copy
        fix_count = old_ptr_b - (old_ptr_a + find_count)
        if fix_count > 0 {
            memmove((old_ptr_a + find_count), new_ptr - fix_count, fix_count)
        }

        c0.count = capacity_required
    } else {
        // Our array can stay the same size as we perform the replacement. Since we can go front to
        // back we don't need to know the number of occurrences a priori.
        guard let c0_data = c0.data else { return }

        // work our way from back to front, copying and replacing as we go
        let start = c0_data
        let old_end = c0_data + c0_count

        var old_ptr = start
        var new_ptr = start

        while old_ptr <= old_end {
            // is this the thing we need to replace?
            if (old_ptr.pointee == find_start_lower || old_ptr.pointee == find_start_upper) &&
                old_ptr + find_count <= old_end &&
                    memcasecmp(old_ptr, find_data, find_count, ignoreCase) == 0 {
                old_ptr += find_count

                memmove(new_ptr, replace_data, replace_count)
                new_ptr += replace_count
            } else {
                new_ptr.pointee = old_ptr.pointee
                new_ptr += 1
                old_ptr += 1
            }
        }

        c0.count = (new_ptr - start) - 1
    }
}

@usableFromInline
func chitch_concat(_ c0: inout CHitch, _ rhs: UnsafeMutablePointer<UInt8>?, _ rhs_count: Int) {
    guard rhs_count > 0 else { return }
    guard let rhs = rhs else { return }

    chitch_sanity(&c0, c0.count + rhs_count)
    guard let c0_data = c0.data else { return }

    (c0_data + c0.count).assign(from: rhs, count: rhs_count)
    c0.count += rhs_count
}

@usableFromInline
func chitch_concat(_ c0: inout CHitch, _ rhs: UnsafePointer<UInt8>?, _ rhs_count: Int) {
    guard rhs_count > 0 else { return }
    guard let rhs = rhs else { return }

    chitch_sanity(&c0, c0.count + rhs_count)
    guard let c0_data = c0.data else { return }

    (c0_data + c0.count).assign(from: rhs, count: rhs_count)
    c0.count += rhs_count
}

@usableFromInline
func chitch_concat_char(_ c0: inout CHitch, _ rhs: UInt8) {

    chitch_sanity(&c0, c0.count + 1)
    guard let c0_data = c0.data else { return }

    c0_data[c0.count] = rhs
    c0.count += 1
}

@usableFromInline
func chitch_concat_precision(_ c0: inout CHitch, _ rhs_in: UnsafeMutablePointer<UInt8>?, _ rhs_count: Int, _ precision: Int) {
    guard rhs_count > 0 else { return }
    guard var rhs = rhs_in else { return }

    chitch_sanity(&c0, c0.count + rhs_count)
    guard let c0_data = c0.data else { return }

    // treat each '.' found with digits on boths sides as if it were a double, include only precision number of decimal places
    var ptr = c0_data + c0.count
    let end = rhs + rhs_count

    ptr.pointee = rhs.pointee
    ptr += 1
    rhs += 1

    while rhs < end {
        if rhs.pointee == .dot && isDigit(rhs[-1]) && isDigit(rhs[1]) {
            ptr.pointee = rhs.pointee
            ptr += 1; rhs += 1

            // copy over the precisions
            var precisionCount = precision
            while rhs < end && precisionCount > 0 {
                precisionCount -= 1

                if isDigit(rhs.pointee) == false {
                    break
                }

                ptr.pointee = rhs.pointee
                ptr += 1; rhs += 1
            }

            // skip any more digits
            while precisionCount == 0 && rhs < end && isDigit(rhs.pointee) {
                rhs += 1
            }

        } else {
            ptr.pointee = rhs.pointee
            ptr += 1; rhs += 1
        }
    }

    c0.count = ptr - c0_data
}

@usableFromInline
func chitch_insert_raw(_ c0: inout CHitch, _ position_in: Int, _ rhs: UnsafeMutablePointer<UInt8>?, _ rhs_count: Int) {
    guard let rhs = rhs else { return }

    var position = position_in

    if position < 0 { position = 0 }
    if position >= c0.count {
        return chitch_concat(&c0, rhs, rhs_count)
    }

    chitch_sanity(&c0, c0.count + rhs_count)
    guard let c0_data = c0.data else { return }

    // Start at end and copy back until old count + rhs_count to make room
    // for simultaneous copy operation
    var ptr = c0_data + c0.count
    let start = c0_data + position
    while ptr >= start {
        ptr[rhs_count] = ptr.pointee
        ptr -= 1
    }

    // simulataneous insert and copy
    var src_ptr = rhs
    var dst_ptr = c0_data + position
    let end = dst_ptr + rhs_count
    while dst_ptr < end {
        dst_ptr.pointee = src_ptr.pointee
        dst_ptr += 1
        src_ptr += 1
    }

    c0.count += rhs_count
}

@usableFromInline
func chitch_insert_raw(_ c0: inout CHitch, _ position_in: Int, _ rhs: UnsafeRawPointer?, _ rhs_count: Int) {
    let raw = UnsafeMutableRawPointer(mutating: rhs)
    chitch_insert_raw(&c0,
                      position_in,
                      raw?.bindMemory(to: UInt8.self, capacity: rhs_count),
                      rhs_count)
}

@usableFromInline
func chitch_insert_cstring(_ c0: inout CHitch, _ position: Int, _ string: String) {
    return chitch_using(string) { string_raw, string_count in
        return chitch_insert_raw(&c0, position, string_raw, string_count)
    }
}

@usableFromInline
func chitch_insert_char(_ c0: inout CHitch, _ position: Int, _ rhs: UInt8) {
    return chitch_insert_raw(&c0, position, [rhs], 1)
}

@usableFromInline
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
            ptr.pointee = .zero + UInt8(rhs)
            ptr -= 1
            len = 1
        } else {
            let neg = (rhs < 0)
            if neg {
                rhs = -rhs
            }

            while ptr > raw && rhs > 0 {
                ptr.pointee = .zero + UInt8(rhs % 10)
                ptr -= 1
                rhs /= 10
            }

            if neg {
                ptr.pointee = .minus
                ptr -= 1
            }

            len = end - ptr
        }

        return chitch_insert_raw(&c0, position, ptr+1, len)
    }

}

// MARK: - IMMUTABLE METHODS

@usableFromInline
func chitch_cmp_raw(_ lhs: UnsafeMutablePointer<UInt8>?,
                    _ lhs_count: Int,
                    _ rhs: UnsafeMutablePointer<UInt8>?,
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
        if lhsPtr.pointee != rhs.pointee {
            return Int(lhsPtr.pointee) - Int(rhs.pointee)
        }
        lhsPtr += 1
        rhsPtr += 1
    }

    return 0
}

@usableFromInline
func chitch_equal_raw(_ lhs: UnsafeMutablePointer<UInt8>?,
                      _ lhs_count: Int,
                      _ rhs: UnsafeMutablePointer<UInt8>?,
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

@usableFromInline
func chitch_contains_raw(_ haystack: UnsafeMutablePointer<UInt8>?,
                         _ haystack_count: Int,
                         _ needle: UnsafeMutablePointer<UInt8>?,
                         _ needle_count: Int) -> Bool {
    return chitch_firstof_raw(haystack, haystack_count, needle, needle_count) >= 0
}

@usableFromInline
func chitch_firstof_raw_offset(_ haystack: UnsafeMutablePointer<UInt8>?,
                               _ haystack_offset: Int,
                               _ haystack_count: Int,
                               _ needle: UnsafeMutablePointer<UInt8>?,
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

@usableFromInline
func chitch_firstof_raw(_ haystack: UnsafeMutablePointer<UInt8>?,
                        _ haystack_count: Int,
                        _ needle: UnsafeMutablePointer<UInt8>?,
                        _ needle_count: Int) -> Int {
    guard haystack_count >= 0 else { return -1 }
    guard needle_count > 0 else { return 0 }
    if needle == nil && haystack == nil { return 0 }
    guard let haystack = haystack else { return -1 }
    guard let needle = needle else { return -1 }
    guard needle_count <= haystack_count else { return -1 }

    var ptr = haystack
    let end = haystack + haystack_count - needle_count
    let needle_start = needle[0]

    var found = true

    while ptr <= end {
        if ptr.pointee == needle_start {
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
        ptr += 1
    }

    return -1
}

@usableFromInline
func chitch_lastof_raw(_ haystack: UnsafeMutablePointer<UInt8>?,
                       _ haystack_count: Int,
                       _ needle: UnsafeMutablePointer<UInt8>?,
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
        if ptr.pointee == needle_start {
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

@usableFromInline
func chitch_toepoch(_ c0: inout CHitch) -> Int {
    // Handles just this one date format. Timezone is always considered to be UTC
    // 4/30/2021 8:19:27 AM
    guard let c0_data = c0.data else { return 0 }
    guard c0.count > 0 else { return 0 }

    guard let stringValue = String(bytesNoCopy: c0_data, length: c0.count, encoding: .utf8, freeWhenDone: false) else { return 0 }
    guard let date = epochFormat.date(from: stringValue) else { return 0 }

    return Int(date.timeIntervalSince1970)
}

@usableFromInline
func chitch_using<T>(_ string: String, _ block: (UnsafeMutablePointer<UInt8>, Int) -> T) -> T {
    return string.withCString { bytes in
        var ptr = bytes
        while ptr.pointee != 0 {
            ptr += 1
        }
        let raw = UnsafeMutableRawPointer(mutating: bytes)
        let count = ptr - bytes
        let raw2 = raw.bindMemory(to: UInt8.self, capacity: count)
        return block(raw2, count)
    }
}
