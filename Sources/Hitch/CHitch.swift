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

@usableFromInline
func chitch_empty() -> CHitch {
    return CHitch()
}

@usableFromInline
func chitch_init_capacity(_ capacity: Int) -> CHitch {
    var c = CHitch()
    c.count = 0
    c.capacity = capacity
    c.data = UnsafeMutablePointer<UInt8>.allocate(capacity: capacity + 1)
    return c
}

@usableFromInline
func chitch_init_raw(_ raw: UnsafeMutablePointer<UInt8>?, _ count: Int) -> CHitch {
    guard let raw = raw else { return chitch_empty() }
    var c = CHitch()
    c.count = count
    c.capacity = count
    c.data = UnsafeMutablePointer<UInt8>.allocate(capacity: count + 1)
    c.data?.assign(from: raw, count: count)
    return c
}

@usableFromInline
func chitch_init_raw(_ raw: UnsafePointer<UInt8>?, _ count: Int) -> CHitch {
    guard let raw = raw else { return chitch_empty() }
    var c = CHitch()
    c.count = count
    c.capacity = count
    c.data = UnsafeMutablePointer<UInt8>.allocate(capacity: count + 1)
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
    chitch.data?.deallocate()
}

@usableFromInline
func chitch_realloc(_ c0: inout CHitch, _ newCount: Int) {
    // Note: UnsafeMutablePointer appears to be missing a realloc!
    let newData = UnsafeMutablePointer<UInt8>.allocate(capacity: newCount + 1)
    chitch_concat_raw(newData, 0, c0.data, min(c0.count, newCount))
    c0.data?.deallocate()
    c0.data = newData
}

@usableFromInline
func chitch_resize(_ c0: inout CHitch, _ newCount: Int) {
    if newCount > c0.capacity {
        chitch_realloc(&c0, newCount + 1)
    } else {
        c0.count = newCount
    }
}

@usableFromInline
func chitch_concat_raw(_ lhs: UnsafeMutablePointer<UInt8>?, _ lhs_count: Int, _ rhs: UnsafeMutablePointer<UInt8>?, _ rhs_count: Int) {
    guard rhs_count > 0 else { return }
    guard let lhs = lhs else { return }
    guard let rhs = rhs else { return }

    // TODO: handle realloc
    (lhs + lhs_count).assign(from: rhs, count: rhs_count)

    // memmove(c0->data + c0.count, rhs, rhs_count)
    // c0->count += rhs_count
}

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
