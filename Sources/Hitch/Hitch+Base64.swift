import Foundation

public extension Data {
    func base64Encoded() -> HalfHitch? {
        return HalfHitch(data: self).base64Encoded()
    }
    
    func base64Decoded() -> Data? {
        return HalfHitch(data: self).base64Decoded()
    }
}

public extension StaticString {
    func base64Encoded() -> HalfHitch? {
        return HalfHitch(stringLiteral: self).base64Encoded()
    }
    
    func base64Decoded() -> Data? {
        return HalfHitch(stringLiteral: self).base64Decoded()
    }
}

public extension String {
    func base64Encoded() -> HalfHitch? {
        return HalfHitch(string: self).base64Encoded()
    }
    
    func base64Decoded() -> Data? {
        return HalfHitch(string: self).base64Decoded()
    }
}

public extension HalfHitch {
    func base64Encoded() -> HalfHitch? {
        return HalfHitch(string: dataNoCopy().base64EncodedString())
    }
    
    func base64Decoded() -> Data? {
        return Data(base64Encoded: dataNoCopy(), options: [.ignoreUnknownCharacters])
    }
}

public extension Hitch {
    func base64Encoded() -> HalfHitch? {
        return halfhitch().base64Encoded()
    }
    
    func base64Decoded() -> Data? {
        return halfhitch().base64Decoded()
    }
}
