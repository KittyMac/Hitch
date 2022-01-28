import Foundation

// Ported from cHitch.c.

@usableFromInline
struct CHitch {
    @usableFromInline
    var capacity: Int = 0
    @usableFromInline
    var count: Int = 0
    @usableFromInline
    var data: UnsafeMutablePointer<UInt8>?
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
        ptr.pointee = ((c >= .A && c <= .Z) ? c + 0x20 : c)
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
        ptr.pointee = ((c >= .a && c <= .z) ? c - 0x20 : c)
        ptr += 1
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
