import Foundation

// swiftlint:disable identifier_name

internal extension Int8 {

    @usableFromInline static let null: Int8 = 0
    @usableFromInline static let startOfHeading: Int8 = 1
    @usableFromInline static let startOfText: Int8 = 2
    @usableFromInline static let endOfText: Int8 = 3
    @usableFromInline static let endOfTransmission: Int8 = 4
    @usableFromInline static let enquiry: Int8 = 5
    @usableFromInline static let acknowledge: Int8 = 6
    @usableFromInline static let bell: Int8 = 7
    @usableFromInline static let backspace: Int8 = 8
    @usableFromInline static let tab: Int8 = 9
    @usableFromInline static let newLine: Int8 = 10
    @usableFromInline static let lineFeed: Int8 = 10
    @usableFromInline static let verticalTab: Int8 = 11
    @usableFromInline static let formFeed: Int8 = 12
    @usableFromInline static let carriageReturn: Int8 = 13
    @usableFromInline static let shiftOut: Int8 = 14
    @usableFromInline static let shiftIn: Int8 = 15
    @usableFromInline static let dataLinkEscape: Int8 = 16
    @usableFromInline static let deviceControl1: Int8 = 17
    @usableFromInline static let deviceControl2: Int8 = 18
    @usableFromInline static let deviceControl3: Int8 = 19
    @usableFromInline static let deviceControl4: Int8 = 20

    @usableFromInline static let negativeAcknowledge: Int8 = 21
    @usableFromInline static let synchronousIdle: Int8 = 22
    @usableFromInline static let endOfBlock: Int8 = 23
    @usableFromInline static let cancel: Int8 = 24
    @usableFromInline static let endOfMedium: Int8 = 25
    @usableFromInline static let substitute: Int8 = 26
    @usableFromInline static let escape: Int8 = 27
    @usableFromInline static let fileSeparator: Int8 = 28
    @usableFromInline static let groupSeparator: Int8 = 29
    @usableFromInline static let recordSeparator: Int8 = 30
    @usableFromInline static let unitSeparator: Int8 = 31

    @usableFromInline static let space: Int8 = 32
    @usableFromInline static let bang: Int8 = 33
    @usableFromInline static let doubleQuote: Int8 = 34
    @usableFromInline static let hashTag: Int8 = 35
    @usableFromInline static let dollarSign: Int8 = 36
    @usableFromInline static let percentSign: Int8 = 37
    @usableFromInline static let ampersand: Int8 = 38
    @usableFromInline static let singleQuote: Int8 = 39
    @usableFromInline static let parenOpen: Int8 = 40
    @usableFromInline static let parenClose: Int8 = 41
    @usableFromInline static let astericks: Int8 = 42
    @usableFromInline static let plus: Int8 = 43
    @usableFromInline static let comma: Int8 = 44
    @usableFromInline static let minus: Int8 = 45
    @usableFromInline static let dot: Int8 = 46
    @usableFromInline static let forwardSlash: Int8 = 47

    @usableFromInline static let zero: Int8 = 48
    @usableFromInline static let one: Int8 = 49
    @usableFromInline static let two: Int8 = 50
    @usableFromInline static let three: Int8 = 51
    @usableFromInline static let four: Int8 = 52
    @usableFromInline static let five: Int8 = 53
    @usableFromInline static let six: Int8 = 54
    @usableFromInline static let seven: Int8 = 55
    @usableFromInline static let eight: Int8 = 56
    @usableFromInline static let nine: Int8 = 57

    @usableFromInline static let colon: Int8 = 58
    @usableFromInline static let semiColon: Int8 = 59
    @usableFromInline static let lessThan: Int8 = 60
    @usableFromInline static let equal: Int8 = 61
    @usableFromInline static let greaterThan: Int8 = 62
    @usableFromInline static let questionMark: Int8 = 63
    @usableFromInline static let atMark: Int8 = 64

    @usableFromInline static let A: Int8 = 65
    @usableFromInline static let B: Int8 = 66
    @usableFromInline static let C: Int8 = 67
    @usableFromInline static let D: Int8 = 68
    @usableFromInline static let E: Int8 = 69
    @usableFromInline static let F: Int8 = 70
    @usableFromInline static let G: Int8 = 71
    @usableFromInline static let H: Int8 = 72
    @usableFromInline static let I: Int8 = 73
    @usableFromInline static let J: Int8 = 74
    @usableFromInline static let K: Int8 = 75
    @usableFromInline static let L: Int8 = 76
    @usableFromInline static let M: Int8 = 77
    @usableFromInline static let N: Int8 = 78
    @usableFromInline static let O: Int8 = 79
    @usableFromInline static let P: Int8 = 80
    @usableFromInline static let Q: Int8 = 81
    @usableFromInline static let R: Int8 = 82
    @usableFromInline static let S: Int8 = 83
    @usableFromInline static let T: Int8 = 84
    @usableFromInline static let U: Int8 = 85
    @usableFromInline static let V: Int8 = 86
    @usableFromInline static let W: Int8 = 87
    @usableFromInline static let X: Int8 = 88
    @usableFromInline static let Y: Int8 = 89
    @usableFromInline static let Z: Int8 = 90

    @usableFromInline static let openBrace: Int8 = 91
    @usableFromInline static let backSlash: Int8 = 92
    @usableFromInline static let closeBrace: Int8 = 93
    @usableFromInline static let carrat: Int8 = 94
    @usableFromInline static let underscore: Int8 = 95
    @usableFromInline static let backtick: Int8 = 96

    @usableFromInline static let a: Int8 = 97
    @usableFromInline static let b: Int8 = 98
    @usableFromInline static let c: Int8 = 99
    @usableFromInline static let d: Int8 = 100
    @usableFromInline static let e: Int8 = 101
    @usableFromInline static let f: Int8 = 102
    @usableFromInline static let g: Int8 = 103
    @usableFromInline static let h: Int8 = 104
    @usableFromInline static let i: Int8 = 105
    @usableFromInline static let j: Int8 = 106
    @usableFromInline static let k: Int8 = 107
    @usableFromInline static let l: Int8 = 108
    @usableFromInline static let m: Int8 = 109
    @usableFromInline static let n: Int8 = 110
    @usableFromInline static let o: Int8 = 111
    @usableFromInline static let p: Int8 = 112
    @usableFromInline static let q: Int8 = 113
    @usableFromInline static let r: Int8 = 114
    @usableFromInline static let s: Int8 = 115
    @usableFromInline static let t: Int8 = 116
    @usableFromInline static let u: Int8 = 117
    @usableFromInline static let v: Int8 = 118
    @usableFromInline static let w: Int8 = 119
    @usableFromInline static let x: Int8 = 120
    @usableFromInline static let y: Int8 = 121
    @usableFromInline static let z: Int8 = 122

    @usableFromInline static let openBracket: Int8 = 123
    @usableFromInline static let pipe: Int8 = 124
    @usableFromInline static let closeBracket: Int8 = 125
    @usableFromInline static let tilde: Int8 = 126
    @usableFromInline static let del: Int8 = 127
}
