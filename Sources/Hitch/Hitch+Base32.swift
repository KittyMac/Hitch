import Foundation

public extension Data {
    func base32Encoded() -> Hitch? {
        return chitch_base32_encode(data: self)
    }
}

public extension HalfHitch {
    func base32Decoded() -> Data? {
        return chitch_base32_decode(halfHitch: self)
    }
}

public extension Hitch {
    func base32Decoded() -> Data? {
        return chitch_base32_decode(halfHitch: self.halfhitch())
    }
}
