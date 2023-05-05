import Foundation

public extension Data {
    func base32Encoded() -> Hitch? {
        return chitch_base32_encode(data: self)
    }
    
    func base32Decoded() -> Data? {
        return self.withUnsafeBytes { unsafeRawBufferPointer in
            let unsafeBufferPointer = unsafeRawBufferPointer.bindMemory(to: UInt8.self)
            guard let bytes = unsafeBufferPointer.baseAddress else { return nil }
            return chitch_base32_decode(halfHitch: HalfHitch(sourceObject: nil,
                                                             raw: bytes,
                                                             count: count,
                                                             from: 0,
                                                             to: count))
        }
    }
}

public extension StaticString {
    func base32Encoded() -> Hitch? {
        return chitch_base32_encode(data: HalfHitch(stringLiteral: self).dataNoCopy())
    }
    
    func base32Decoded() -> Data? {
        return chitch_base32_decode(halfHitch: HalfHitch(stringLiteral: self))
    }
}

public extension String {
    func base32Encoded() -> Hitch? {
        guard let data = self.data(using: .utf8) else { return nil }
        return chitch_base32_encode(data: data)
    }
    
    func base32Decoded() -> Data? {
        return chitch_base32_decode(halfHitch: HalfHitch(string: self))
    }
}

public extension HalfHitch {
    func base32Encoded() -> Hitch? {
        return chitch_base32_encode(data: dataNoCopy())
    }
    
    func base32Decoded() -> Data? {
        return chitch_base32_decode(halfHitch: self)
    }
}

public extension Hitch {
    func base32Encoded() -> Hitch? {
        return chitch_base32_encode(data: dataNoCopy())
    }
    
    func base32Decoded() -> Data? {
        return chitch_base32_decode(halfHitch: self.halfhitch())
    }
}
