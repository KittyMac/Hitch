import Foundation

// swiftlint:disable identifier_name

public extension Int8 {
        
    @inlinable
    func isWhitspace() -> Bool {
        switch self {
        case .space, .newLine, .carriageReturn, .tab:
            return true
        default:
            return false
        }
    }

    static let null: Int8 = 0
    static let startOfHeading: Int8 = 1
    static let startOfText: Int8 = 2
    static let endOfText: Int8 = 3
    static let endOfTransmission: Int8 = 4
    static let enquiry: Int8 = 5
    static let acknowledge: Int8 = 6
    static let bell: Int8 = 7
    static let backspace: Int8 = 8
    static let tab: Int8 = 9
    static let newLine: Int8 = 10
    static let lineFeed: Int8 = 10
    static let verticalTab: Int8 = 11
    static let formFeed: Int8 = 12
    static let carriageReturn: Int8 = 13
    static let shiftOut: Int8 = 14
    static let shiftIn: Int8 = 15
    static let dataLinkEscape: Int8 = 16
    static let deviceControl1: Int8 = 17
    static let deviceControl2: Int8 = 18
    static let deviceControl3: Int8 = 19
    static let deviceControl4: Int8 = 20

    static let negativeAcknowledge: Int8 = 21
    static let synchronousIdle: Int8 = 22
    static let endOfBlock: Int8 = 23
    static let cancel: Int8 = 24
    static let endOfMedium: Int8 = 25
    static let substitute: Int8 = 26
    static let escape: Int8 = 27
    static let fileSeparator: Int8 = 28
    static let groupSeparator: Int8 = 29
    static let recordSeparator: Int8 = 30
    static let unitSeparator: Int8 = 31

    static let space: Int8 = 32
    static let bang: Int8 = 33
    static let doubleQuote: Int8 = 34
    static let hashTag: Int8 = 35
    static let dollarSign: Int8 = 36
    static let percentSign: Int8 = 37
    static let ampersand: Int8 = 38
    static let singleQuote: Int8 = 39
    static let parenOpen: Int8 = 40
    static let parenClose: Int8 = 41
    static let astericks: Int8 = 42
    static let plus: Int8 = 43
    static let comma: Int8 = 44
    static let minus: Int8 = 45
    static let dot: Int8 = 46
    static let forwardSlash: Int8 = 47

    static let zero: Int8 = 48
    static let one: Int8 = 49
    static let two: Int8 = 50
    static let three: Int8 = 51
    static let four: Int8 = 52
    static let five: Int8 = 53
    static let six: Int8 = 54
    static let seven: Int8 = 55
    static let eight: Int8 = 56
    static let nine: Int8 = 57

    static let colon: Int8 = 58
    static let semiColon: Int8 = 59
    static let lessThan: Int8 = 60
    static let equal: Int8 = 61
    static let greaterThan: Int8 = 62
    static let questionMark: Int8 = 63
    static let atMark: Int8 = 64

    static let A: Int8 = 65
    static let B: Int8 = 66
    static let C: Int8 = 67
    static let D: Int8 = 68
    static let E: Int8 = 69
    static let F: Int8 = 70
    static let G: Int8 = 71
    static let H: Int8 = 72
    static let I: Int8 = 73
    static let J: Int8 = 74
    static let K: Int8 = 75
    static let L: Int8 = 76
    static let M: Int8 = 77
    static let N: Int8 = 78
    static let O: Int8 = 79
    static let P: Int8 = 80
    static let Q: Int8 = 81
    static let R: Int8 = 82
    static let S: Int8 = 83
    static let T: Int8 = 84
    static let U: Int8 = 85
    static let V: Int8 = 86
    static let W: Int8 = 87
    static let X: Int8 = 88
    static let Y: Int8 = 89
    static let Z: Int8 = 90

    static let openBrace: Int8 = 91
    static let backSlash: Int8 = 92
    static let closeBrace: Int8 = 93
    static let carrat: Int8 = 94
    static let underscore: Int8 = 95
    static let backtick: Int8 = 96

    static let a: Int8 = 97
    static let b: Int8 = 98
    static let c: Int8 = 99
    static let d: Int8 = 100
    static let e: Int8 = 101
    static let f: Int8 = 102
    static let g: Int8 = 103
    static let h: Int8 = 104
    static let i: Int8 = 105
    static let j: Int8 = 106
    static let k: Int8 = 107
    static let l: Int8 = 108
    static let m: Int8 = 109
    static let n: Int8 = 110
    static let o: Int8 = 111
    static let p: Int8 = 112
    static let q: Int8 = 113
    static let r: Int8 = 114
    static let s: Int8 = 115
    static let t: Int8 = 116
    static let u: Int8 = 117
    static let v: Int8 = 118
    static let w: Int8 = 119
    static let x: Int8 = 120
    static let y: Int8 = 121
    static let z: Int8 = 122

    static let openBracket: Int8 = 123
    static let pipe: Int8 = 124
    static let closeBracket: Int8 = 125
    static let tilde: Int8 = 126
    static let del: Int8 = 127
}
