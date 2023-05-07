import Foundation


public extension HalfHitch {
    func extractCodeBlock(match: HalfHitch) -> Hitch? {
        return chitch_extract_block(match: match,
                                    source: self)
    }
}

public extension Hitch {
    func extractCodeBlock(match: HalfHitch) -> Hitch? {
        return chitch_extract_block(match: match,
                                    source: halfhitch())
    }
}

