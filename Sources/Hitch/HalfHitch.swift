// swiftlint:disable type_body_length

import Foundation
import bstrlib

public struct HalfHitch: CustomStringConvertible, Comparable, Codable, Hashable {

    public var description: String {
        return String(data: source.dataNoCopy(start: from, end: to), encoding: .utf8) ?? "null"
    }

    @usableFromInline
    let source: Hitch
    @usableFromInline
    var from: Int
    @usableFromInline
    var to: Int

    @inlinable @inline(__always)
    init(source: Hitch, from: Int, to: Int) {
        self.source = source
        self.from = from
        self.to = to
    }

    internal var tagbstr: tagbstring {
        guard let raw = source.raw() else { return tagbstring(mlen: 0, slen: 0, data: nil) }
        let mlen = Int32(source.count - from)
        let slen = Int32(to - from)
        return tagbstring(mlen: mlen, slen: slen, data: raw + from)
    }

    public static func < (lhs: HalfHitch, rhs: HalfHitch) -> Bool {
        var lhs = lhs.tagbstr
        var rhs = rhs.tagbstr
        return bstrcmp(&lhs, &rhs) < 0
    }

    public static func < (lhs: String, rhs: HalfHitch) -> Bool {
        let hitch = lhs.hitch()
        var rhs = rhs.tagbstr
        return bstrcmp(hitch.bstr, &rhs) < 0
    }

    public static func < (lhs: HalfHitch, rhs: String) -> Bool {
        let hitch = rhs.hitch()
        var lhs = lhs.tagbstr
        return bstrcmp(&lhs, hitch.bstr) < 0
    }

    public static func == (lhs: HalfHitch, rhs: HalfHitch) -> Bool {
        var lhs = lhs.tagbstr
        var rhs = rhs.tagbstr
        return biseq(&lhs, &rhs) == 1
    }

    public static func == (lhs: String, rhs: HalfHitch) -> Bool {
        let hitch = lhs.hitch()
        var rhs = rhs.tagbstr
        return biseq(hitch.bstr, &rhs) == 1
    }

    public static func == (lhs: HalfHitch, rhs: String) -> Bool {
        let hitch = rhs.hitch()
        var lhs = lhs.tagbstr
        return biseq(&lhs, hitch.bstr) == 1
    }
}
