import XCTest
import Hitch

struct TestHalfHitchCodable: Codable {
    let x: HalfHitch
}

final class HalfHitchTests: XCTestCase {
    
    func testCodeBlock() {
        let source: HalfHitch = """
        let x = 5;
        let y = 2;
        
        function add(x,y) {
            // this is a "sample {} code block"
            let f = function() {
                return undefined;
            }
            return x+y;
        }
        
        print("Hello World!");
        """
        
        let result: Hitch = """
        function add(x,y) {
            // this is a "sample {} code block"
            let f = function() {
                return undefined;
            }
            return x+y;
        }
        """
        
        XCTAssertEqual(source.extractCodeBlock(match: "function add"), result)
    }
    
    func testBase32() {
        let tests: [HalfHitch: HalfHitch] = [
            "": "",
            "f": "MY",
            "fo": "MZXQ",
            "foo": "MZXW6",
            "foob": "MZXW6YQ",
            "fooba": "MZXW6YTB",
            "foobar": "MZXW6YTBOI",
        ]
        
        for (test, result) in tests {
            XCTAssertEqual(test.dataNoCopy().base32Encoded()?.halfhitch(), result)
            XCTAssertEqual(test.dataNoCopy(), result.base32Decoded())
        }
    }
    
    func testBase64() {
        let tests: [HalfHitch: HalfHitch] = [
            "": "",
            "f": "Zg==",
            "fo": "Zm8=",
            "foo": "Zm9v",
            "foob": "Zm9vYg==",
            "fooba": "Zm9vYmE=",
            "foobar": "Zm9vYmFy",
        ]

        for (test, result) in tests {
            XCTAssertEqual(test.dataNoCopy().base64Encoded(), result)
            XCTAssertEqual(test.dataNoCopy(), result.base64Decoded())
        }
    }
    
    func testFirst() {
        let hello: Hitch = "d2579a0d728d7bfb198dabd280738c3e8a4d2718"
        XCTAssertEqual(hello.clamp(32).description, "d2579a0d728d7bfb198dabd280738c3e")
    }
    
    func testMD5() {
        let hello: HalfHitch = "Hello"
        XCTAssertEqual(hello.md5(), "8B1A9953C4611296A827ABF8C47804D7")
        
        XCTAssertEqual(hello.dataNoCopy().md5(), "8B1A9953C4611296A827ABF8C47804D7")
    }
    
    func testSimpleCreate() {
        let hello: HalfHitch = "Hello"
        XCTAssertEqual(hello.description, "Hello")
    }
    
    func testHashValue() {
        let hello: HalfHitch = "Hello"
        XCTAssertEqual(hello.hashValue, 210676686969)
        
        XCTAssertEqual(hitchLorem.hashValue, -7313112045928675463)
        XCTAssertEqual(halfhitchLorem.hashValue, -7313112045928675463)
        
        // force memory unaligned hash
        let unaligned0: HalfHitch = "Hello World this is a somewhat long string"
        let unaligned1: HalfHitch = " Hello World this is a somewhat long string"
        let unaligned2: HalfHitch = "  Hello World this is a somewhat long string"
        let unaligned3: HalfHitch = "   Hello World this is a somewhat long string"
        let unaligned4: HalfHitch = "    Hello World this is a somewhat long string"
        let unaligned5: HalfHitch = "     Hello World this is a somewhat long string"
        let unaligned6: HalfHitch = "      Hello World this is a somewhat long string"
        let unaligned7: HalfHitch = "       Hello World this is a somewhat long string"
        
        // NOTE: all of these should have the same hash if our alignment correction is working
        XCTAssertEqual(HalfHitch(source: unaligned0, from: 0, to: 0 + unaligned0.count).hashValue, 3474349103086970501)
        XCTAssertEqual(HalfHitch(source: unaligned1, from: 1, to: 1 + unaligned0.count).hashValue, 3474349103086970501)
        XCTAssertEqual(HalfHitch(source: unaligned2, from: 2, to: 2 + unaligned0.count).hashValue, 3474349103086970501)
        XCTAssertEqual(HalfHitch(source: unaligned3, from: 3, to: 3 + unaligned0.count).hashValue, 3474349103086970501)
        XCTAssertEqual(HalfHitch(source: unaligned4, from: 4, to: 4 + unaligned0.count).hashValue, 3474349103086970501)
        XCTAssertEqual(HalfHitch(source: unaligned5, from: 5, to: 5 + unaligned0.count).hashValue, 3474349103086970501)
        XCTAssertEqual(HalfHitch(source: unaligned6, from: 6, to: 6 + unaligned0.count).hashValue, 3474349103086970501)
        XCTAssertEqual(HalfHitch(source: unaligned7, from: 7, to: 7 + unaligned0.count).hashValue, 3474349103086970501)

    }
            
    func testIteration() {
        let hello: HalfHitch = "Hello"
        
        var i = 0
        var c = 0
        for x in hello {
            c += 1
            i += Int(x)
        }
        for x in hello {
            c += 1
            i += Int(x)
        }
        
        XCTAssertEqual(c, 10)
        XCTAssertEqual(i, 1000)
    }
    
    func testIterationRange() {
        let hello: HalfHitch = "Hello"
        
        var i = 0
        var c = 0

        for x in hello.stride(from: 1, to: 3) {
            c += 1
            i += Int(x)
        }
        
        XCTAssertEqual(c, 2)
        XCTAssertEqual(i, 209)
    }
    
    func testDirectAccess() {
        HalfHitch(stringLiteral: loremStatic).using { (bytes) in
            XCTAssertEqual(bytes[6], 105)
            XCTAssertEqual(bytes[3], 101)
        }
    }
    
    func testSubscript() {
        XCTAssertEqual(hitchLorem[6], 105)
        XCTAssertEqual(hitchLorem[3], 101)
    }
    
    func testContainsSingle() {
        XCTAssertTrue(hitchLorem.contains(111))
        XCTAssertFalse(hitchLorem.contains(16))
    }
    
    func testHashable() {
        let swiftKey1 = "key1"
        let hitchKey1: HalfHitch = "key1"
        
        let swiftKey2 = "key2"
        let hitchKey2: HalfHitch = "key2"
        
        var swiftDict: [String: Int] = [:]
        var hitchDict: [HalfHitch: Int] = [:]
        
        swiftDict[swiftKey1] = 1
        hitchDict[hitchKey1] = 1
        
        swiftDict[swiftKey2] = 2
        hitchDict[hitchKey2] = 2
        
        XCTAssertEqual(swiftDict[swiftKey1] ?? 0, 1)
        XCTAssertEqual(hitchDict[hitchKey1] ?? 0, 1)
        
        XCTAssertEqual(swiftDict[swiftKey2] ?? 0, 2)
        XCTAssertEqual(hitchDict[hitchKey2] ?? 0, 2)
    }
    
    func testEquality() {
        XCTAssertTrue(Hitch.empty == Hitch.empty)
        XCTAssertTrue(HalfHitch.empty == HalfHitch.empty)
        
        XCTAssertTrue(swiftLorem == swiftLorem)
        XCTAssertTrue(loremStatic == hitchLorem)
        XCTAssertTrue(hitchLorem == loremStatic)
        XCTAssertTrue(hitchLorem == hitchLorem)
    }
    
    func testCaselessEquality() {
        XCTAssertTrue(Hitch.empty ~== Hitch.empty)
        XCTAssertTrue(HalfHitch.empty ~== HalfHitch.empty)
        
        let hitch0: Hitch = "hello world"
        let hitch1: Hitch = "hElLo WoRlD"
        
        let hhitch0: HalfHitch = hitch0.halfhitch()
        let hhitch1: HalfHitch = hitch1.halfhitch()
        
        XCTAssertTrue(hitch0 ~== hitch1)
        XCTAssertTrue(hhitch0 ~== hhitch1)
    }
    
    func testEpoch() {
        XCTAssertEqual(HalfHitch("4/30/2021 12:00:00 AM").toEpoch(), 1619740800)
        XCTAssertEqual(HalfHitch("4/30/2021 1:00:00 AM").toEpoch(), 1619744400)
        XCTAssertEqual(HalfHitch("4/30/2021 8:19:27 AM").toEpoch(), 1619770767)
        XCTAssertEqual(HalfHitch("4/30/2021 8:19:27 PM").toEpoch(), 1619813967)
        XCTAssertEqual(HalfHitch("4/30/2021 12:00:00 PM").toEpoch(), 1619784000)
        XCTAssertEqual(HalfHitch("4/30/2021 1:19:27 PM").toEpoch(), 1619788767)
        XCTAssertEqual(HalfHitch("4/30/2021 11:59:59 PM").toEpoch(), 1619827199)
        
        XCTAssertEqual(HalfHitch("2023-03-16 20:59:32.808000").toEpoch2(), 1679000372)
        
        XCTAssertEqual(HalfHitch("2023-05-10T21:28:17Z").toEpochISO8601(), 1683754097)
        
        
        XCTAssertEqual(Int(ISO8601DateFormatter().date(from: "2024-08-14T21:00:47-04:00")!.timeIntervalSince1970), 1723683647)
        XCTAssertEqual(HalfHitch("2024-08-14T21:00:47-04:00").toEpochISO8601(), 1723683647)
        XCTAssertEqual(Int(ISO8601DateFormatter().date(from: "2024-08-14T21:00:47+04:00")!.timeIntervalSince1970), 1723654847)
        XCTAssertEqual(HalfHitch("2024-08-14T21:00:47+04:00").toEpochISO8601(), 1723654847)
        
        XCTAssertEqual(Int(ISO8601DateFormatter().date(from: "2024-08-14T21:00:47-0400")!.timeIntervalSince1970), 1723683647)
        XCTAssertEqual(HalfHitch("2024-08-14T21:00:47-0400").toEpochISO8601(), 1723683647)
        XCTAssertEqual(Int(ISO8601DateFormatter().date(from: "2024-08-14T21:00:47+0400")!.timeIntervalSince1970), 1723654847)
        XCTAssertEqual(HalfHitch("2024-08-14T21:00:47+0400").toEpochISO8601(), 1723654847)
    }
    
    func testData() {
        let loremData = hitchLorem.dataNoCopy()
        let hitchLorem2 = HalfHitch(data: loremData)
        
        XCTAssertEqual(hitchLorem.halfhitch(), hitchLorem2)
    }

        
    func testExtract() {
        let test1: HalfHitch = """
        "value1": 27,
        "value2": 27,
        value3: 27,
        "value4": "6.0",
        """
        
        XCTAssertEqual(test1.extract(#""value1""#, ",")?.toInt(fuzzy: true) ?? 0, 27)
        XCTAssertEqual(test1.extract(#""value2""#, ",")?.toInt(fuzzy: true) ?? 0, 27)
        XCTAssertEqual(test1.extract(#"value3"#, ",")?.toInt(fuzzy: true) ?? 0, 27)
        XCTAssertEqual(test1.extract(#""value4": ""#, "\""), "6.0")
    }
    
    func testIndexOf() {
        XCTAssertEqual(hitchLorem.firstIndex(of: "nulla pariatur"), 319)
    }
    
    func testFirstAndLast() {
        let hitchLorem: HalfHitch = "012456789"
        XCTAssertEqual(hitchLorem.first, .zero)
        XCTAssertEqual(hitchLorem.last, .nine)
        
        XCTAssertEqual(HalfHitch.empty.first, 0)
        XCTAssertEqual(HalfHitch.empty.last, 0)
    }
    
    func testLastIndexOf() {
        let hitchLorem: HalfHitch = "/true|false/"
        let hitchNeedle: HalfHitch = "/"
        
        XCTAssertEqual(hitchLorem.lastIndex(of: hitchNeedle), 11)
    }
    
    func testLastIndexOf2() {
        let hitchLorem: HalfHitch = "/true|false/"
        XCTAssertEqual(hitchLorem.lastIndex(of: UInt8.forwardSlash), 11)
    }
    
    func testIndexOf3() {
        XCTAssertEqual(halfhitchLorem.lastIndex(of: "nulla pariatur"), 319)
    }
        
    func testHalfHitchFromData0() {
        let data = "Hello world again".data(using: .utf8)!
        HalfHitch.using(data: data, from: 6, to: 11) { hh in
            XCTAssertEqual(hh.description, "world")
        }
    }
    
    func testHalfHitchFromRaw() {
        let hitch: Hitch = "Hello world again"
        
        guard let raw = hitch.raw() else {
            XCTFail()
            return
        }
        
        let partial = HalfHitch(sourceObject: hitch,
                                raw: raw,
                                count: hitch.count,
                                from: 5,
                                to: 12)
        
        let trimmed = partial.hitch()
        trimmed.trim()
        
        XCTAssertEqual(trimmed, "world")
    }
    
    func testHalfHitch0() {
        let hitch: HalfHitch = "Hello world again"
        XCTAssertEqual(hitch.substring(6, 11)?.description, "world")
    }
        
    func testHalfHitchToInt0() {
        let hitch: HalfHitch = "Hello 123456 again"
        XCTAssertEqual(hitch.substring(6, 12)?.toInt(), 123456)
    }
    
    func testHalfHitchToDouble0() {
        let hitch: HalfHitch = "Hello 123456.123456 again"
        XCTAssertEqual(hitch.substring(6, 19)?.toDouble(), 123456.123456)
    }
    
    func testTrim() {
        XCTAssertEqual(HalfHitch(string: "").trimmed().count, 0)
        XCTAssertEqual(HalfHitch(string: "\n\n").trimmed().count, 0)
        XCTAssertEqual(HalfHitch(string: "Hello   \t\n\r  ").trimmed(), "Hello")
        XCTAssertEqual(HalfHitch(string: "   \t\n\r  Hello").trimmed(), "Hello")
        XCTAssertEqual(HalfHitch(string: "   \t\n\r  Hello   \t\n\r  ").trimmed(), "Hello")
        XCTAssertEqual(HalfHitch(string: "Hello").trimmed(), "Hello")
    }
    
    func testSubstring0() {
        let hitch: HalfHitch = "Hello world again"
        XCTAssertEqual(hitch.substring(6, 11), "world")
    }
    
    func testSubstring1() {
        let hitch: HalfHitch = "Hello world again"
        XCTAssertNil(hitch.substring(99, 11))
    }
    
    func testSubstring2() {
        let hitch: HalfHitch = "Hello world again"
        XCTAssertNil(hitch.substring(99, 120))
    }
    
    func testSubstring3() {
        let hitch: HalfHitch = "Hello world again"
        XCTAssertNil(hitch.substring(-100, 120))
    }
    
    func testStartsWith1() {
        let hitch: HalfHitch = "Hello world again"
        XCTAssertTrue(hitch.starts(with: "Hello "))
    }
    
    func testStartsWith2() {
        let hitch: HalfHitch = "Hello world again"
        XCTAssertFalse(hitch.starts(with: "ello "))
    }
    
    func testStartsWith3() {
        let hitch: HalfHitch = "Hello world again"
        XCTAssertFalse(hitch.starts(with: "world"))
    }
    
    func testStartsWith4() {
        let hitch: HalfHitch = "Hello world again"
        XCTAssertTrue(hitch.starts(with: Hitch(string: "Hello world agai")))
    }
    
    func testUnicodeUnescaping() {
        // A, ö, Ж, €, 𝄞
        let hitch0 = Hitch(string: #"\\ \' \" \t \n \r"#)
        hitch0.unicodeUnescape()
        XCTAssertEqual(hitch0[0], .backSlash)
        XCTAssertEqual(hitch0[1], .space)
        XCTAssertEqual(hitch0[2], .singleQuote)
        XCTAssertEqual(hitch0[3], .space)
        XCTAssertEqual(hitch0[4], .doubleQuote)
        XCTAssertEqual(hitch0[5], .space)
        XCTAssertEqual(hitch0[6], .tab)
        XCTAssertEqual(hitch0[7], .space)
        XCTAssertEqual(hitch0[8], .newLine)
        XCTAssertEqual(hitch0[9], .space)
        XCTAssertEqual(hitch0[10], .carriageReturn)
        XCTAssertEqual(hitch0[11], 0)
        
        let hitch1: Hitch = Hitch(string: #"\u0041 \u00F6 \u0416 \u20AC \u{1D11E}"#)
        hitch1.unicodeUnescape()
        XCTAssertEqual(hitch1, "A ö Ж € 𝄞")
        
        var hitch2: HalfHitch = HalfHitch(string: #"\u0041 \u00F6 \u0416 \u20AC \u{1D11E}"#)
        hitch2.unicodeUnescape()
        XCTAssertEqual(hitch2, "A ö Ж € 𝄞")
        
    }
    
    func testUnicodeEscaping() {
        let hitch0 = HalfHitch("\\ \' \" \t \n \r").escaped(unicode: true,
                                                            singleQuotes: true)
        XCTAssertEqual(hitch0[0], .backSlash)
        XCTAssertEqual(hitch0[1], .backSlash)
        XCTAssertEqual(hitch0[2], .space)
        XCTAssertEqual(hitch0[3], .backSlash)
        XCTAssertEqual(hitch0[4], .singleQuote)
        XCTAssertEqual(hitch0[5], .space)
        XCTAssertEqual(hitch0[6], .backSlash)
        XCTAssertEqual(hitch0[7], .doubleQuote)
        XCTAssertEqual(hitch0[8], .space)
        XCTAssertEqual(hitch0[9], .backSlash)
        XCTAssertEqual(hitch0[10], .t)
        XCTAssertEqual(hitch0[11], .space)
        XCTAssertEqual(hitch0[12], .backSlash)
        XCTAssertEqual(hitch0[13], .n)
        XCTAssertEqual(hitch0[14], .space)
        XCTAssertEqual(hitch0[15], .backSlash)
        XCTAssertEqual(hitch0[16], .r)
        XCTAssertEqual(hitch0[17], 0)
        
        let hitch1: HalfHitch = "A ö Ж € 𝄞"
        XCTAssertEqual(hitch1.escaped(unicode: true,
                                      singleQuotes: true), #"A \u00F6 \u0416 \u20AC \u{1D11E}"#)
        XCTAssertEqual(hitch1.escaped(unicode: true,
                                              singleQuotes: true), #"A \u00F6 \u0416 \u20AC \u{1D11E}"#)
    }
    
    func testPercentUnescaping() {
        let hitch0: HalfHitch = #"https://www.example.com/url?q=https%3A%2F%2Fother.com&amp;sa=D&amp;sntz=1&amp;usg=AOvVaw1T4EtLqdGmEYA-MilAqQIc"#
        XCTAssertEqual(hitch0.percentUnescaped(), "https://www.example.com/url?q=https://other.com&amp;sa=D&amp;sntz=1&amp;usg=AOvVaw1T4EtLqdGmEYA-MilAqQIc")
        
        let hitch1: HalfHitch = #"https://www.example.com/url?q=https%3A%2F%2Fother.com&amp;sa=D&amp;sntz=1&amp;usg=AOvVaw1T4EtL%qdGmEYA-MilAqQIc"#
        XCTAssertEqual(hitch1.percentUnescaped(), "https://www.example.com/url?q=https://other.com&amp;sa=D&amp;sntz=1&amp;usg=AOvVaw1T4EtL%qdGmEYA-MilAqQIc")
        
        XCTAssertEqual(HalfHitch(stringLiteral: "%3A").percentUnescaped(), ":")
    }
    
    func testAmpersandUnescaping() {
        let hitch0: HalfHitch = #"&amp;&lt;&gt;&quot;&apos;&nbsp;&tab;&newline;&#038;Hello&#087;&#000079;&#82;&#76;&#0068;&#8364;&copy;&zwnj;&zwj;&reg;&ndash;&#153;"#
        XCTAssertEqual(hitch0.ampersandUnescaped(), "&<>\"' \t\n&HelloWORLD€©  ®-  ")
        
        XCTAssertEqual(HalfHitch(stringLiteral: "&amp;").ampersandUnescaped(), "&")
    }
    
    func testQuotedPrintableUnescaping() {
        let hitch0: HalfHitch = "style=3D'test' =E2=80=94=20=C2=A0\r\n"
        XCTAssertEqual(hitch0.quotedPrintableUnescaped(), "style='test' —  \n")
        
        XCTAssertEqual(HalfHitch(stringLiteral: "=3D").quotedPrintableUnescaped(), "=")
    }
    
    func testEmlHeaderUnescaping() {
        let emlHeader0: HalfHitch = "=?UTF-8?B?T3JkZXIgQ29uZmlybWF0aW9uIOKAkyBPcmRlciAjOiAyNzU1NTQ=?="
        XCTAssertEqual(emlHeader0.emlHeaderUnescaped(), "Order Confirmation – Order #: 275554")
        
        let emlHeader1: HalfHitch = "=?UTF-8?Q?style=3D'test'?="
        XCTAssertEqual(emlHeader1.emlHeaderUnescaped(), "style='test'")
        
        let emlHeader2: HalfHitch = "Order Confirmation – Order #: 275554"
        XCTAssertEqual(emlHeader2.emlHeaderUnescaped(), "Order Confirmation – Order #: 275554")
        
        let emlHeader3: HalfHitch = "=?UTF-8?B?U2Nod2FuJ3MgSG9tZSBEZWxpdmVyeQ==?=\r\n <schwanshomedelivery@emails.schwans.com>"
        XCTAssertEqual(emlHeader3.emlHeaderUnescaped(), "Schwan's Home Delivery\n <schwanshomedelivery@emails.schwans.com>")
        
        let emlHeader4: HalfHitch = "=?utf-8?q?NYON=C2=AE_by_Knowlita?= <shop@nyon.nyc>"
        XCTAssertEqual(emlHeader4.emlHeaderUnescaped(), "NYON®_by_Knowlita <shop@nyon.nyc>")
    }

    func testComponentInTwain() {
        let hitch0: HalfHitch = "     1  2  3"
        let parts0 = hitch0.components(inTwain: [.space, .carriageReturn, .newLine])
        XCTAssertEqual(parts0[0], "1")
        XCTAssertEqual(parts0[1], "2")
        XCTAssertEqual(parts0[2], "3")
        
        let hitch1: Hitch = "this is a hello   \n\n     \r\n         world in twain!  and another"
        let parts1 = hitch1.components(inTwain: [.space, .carriageReturn, .newLine])
        XCTAssertEqual(parts1[0], "this is a hello")
        XCTAssertEqual(parts1[1], "world in twain!")
        XCTAssertEqual(parts1[2], "and another")
        
        let hitch2: HalfHitch = "this is a hello   \n\n     \r\n         world in twain!"
        let parts2 = hitch2.components(inTwain: [.space, .carriageReturn, .newLine])
        XCTAssertEqual(parts2[0], "this is a hello")
        XCTAssertEqual(parts2[1], "world in twain!")
    }
        
    func testComparable() {
        let hitch1: HalfHitch = "Apple"
        let hitch2: HalfHitch = "apple"
        
        XCTAssertEqual(hitch1 < hitch2, "Apple" < "apple")
        
        XCTAssertEqual(Hitch(string: "5") < Hitch(string: "5.1.2"), "5" < "5.1.2")
        XCTAssertEqual(Hitch(string: "5") > Hitch(string: "5.1.2"), "5" > "5.1.2")
    }
    
    func testToInt() {
        let hitch = HalfHitch("  5  ")
        XCTAssertEqual(hitch.toInt(), 5)
        
        XCTAssertNil(HalfHitch("A").toInt())
        XCTAssertNil(HalfHitch("B").toInt())
    }
    
    func testToIntFuzzy() {
        XCTAssertEqual(HalfHitch("22").toInt(fuzzy: true), 22)
        XCTAssertEqual(HalfHitch("39").toInt(fuzzy: true), 39)
        XCTAssertEqual(HalfHitch("40012").toInt(fuzzy: true), 40012)

        XCTAssertEqual(HalfHitch("  sdf asdf22asdfasd f").toInt(fuzzy: true), 22)
        XCTAssertEqual(HalfHitch("gsdg39sdf .sdfsd").toInt(fuzzy: true), 39)
        XCTAssertEqual(HalfHitch("sdfsdf40012sdfg ").toInt(fuzzy: true), 40012)
    }
    
    func testToDoubleFuzzy() {
        XCTAssertEqual(HalfHitch("2.2").toDouble(fuzzy: true), 2.2)
        XCTAssertEqual(HalfHitch("3.9").toDouble(fuzzy: true), 3.9)
        XCTAssertEqual(HalfHitch("4.0012").toDouble(fuzzy: true), 4.0012)

        XCTAssertEqual(HalfHitch("  sdf asdf2.2asdfasd f").toDouble(fuzzy: true), 2.2)
        XCTAssertEqual(HalfHitch("gsdg3.9sdf .sdfsd").toDouble(fuzzy: true), 3.9)
        XCTAssertEqual(HalfHitch("sdfsdf4.0012sdfg ").toDouble(fuzzy: true), 4.0012)
    }
    
    func testSplitToDouble() {
        //let hitch = "1,2.2,3.9,4.0012,52345.24,-6.0,7.12,8134.99,9.320547,-72.25,  5.6  ,  2.2  4.4  ".halfhitch()
        XCTAssertEqual(HalfHitch("2.2").toDouble(), 2.2)
        XCTAssertEqual(HalfHitch("3.9").toDouble(), 3.9)
        XCTAssertEqual(HalfHitch("4.0012").toDouble(), 4.0012)
        XCTAssertEqual(HalfHitch("52345.24").toDouble(), 52345.24)
        XCTAssertEqual(HalfHitch("-6.0").toDouble(), -6.0)
        XCTAssertEqual(HalfHitch("7.12").toDouble(), 7.12)
        XCTAssertEqual(HalfHitch("8134.99").toDouble(), 8134.99)
        XCTAssertEqual(HalfHitch("9.320547").toDouble(), 9.320547)
        XCTAssertEqual(HalfHitch("-72.25").toDouble(), -72.25)
        XCTAssertEqual(HalfHitch("  5.6  ").toDouble(), 5.6)
        XCTAssertNil(HalfHitch("  2.2  4.4  ").toDouble())
        
        XCTAssertNil(HalfHitch("A").toDouble())
        XCTAssertNil(HalfHitch("B").toDouble())
    }
    
    func testToDouble() {
        let hitch: HalfHitch = "  5.2567  "
        XCTAssertEqual(hitch.toDouble(), 5.2567)
    }
    
    func testReplace1() {
        // replace(occurencesOf hitch: Hitch, with: Hitch, ignoreCase: Bool = false)
        XCTAssertEqual(Hitch(string: "Hello CrUeL world").replace(occurencesOf: "CrUeL", with: "happy"), "Hello happy world")
        XCTAssertEqual(Hitch(string: "Hello CrUeL world").replace(occurencesOf: "cRuEl", with: "happy", ignoreCase: true), "Hello happy world")
    }
    
    func testReplace2() {
        // reduction
        XCTAssertEqual(Hitch(string: "Hello Hello Hello Hello Hello Hello Hello Hello").replace(occurencesOf: "Hello", with: "Bye"), "Bye Bye Bye Bye Bye Bye Bye Bye")
        XCTAssertEqual(Hitch(string: "   Hello Hello Hello Hello Hello Hello Hello Hello   ").replace(occurencesOf: "Hello", with: "Bye"), "   Bye Bye Bye Bye Bye Bye Bye Bye   ")
        
        // expansion
        XCTAssertEqual(Hitch(string: "Hello Hello Hello Hello Hello Hello Hello Hello").replace(occurencesOf: "Hello", with: "Goodbye", ignoreCase: true), "Goodbye Goodbye Goodbye Goodbye Goodbye Goodbye Goodbye Goodbye")
        XCTAssertEqual(Hitch(string: "   Hello Hello Hello Hello Hello Hello Hello Hello   ").replace(occurencesOf: "Hello", with: "Goodbye", ignoreCase: true), "   Goodbye Goodbye Goodbye Goodbye Goodbye Goodbye Goodbye Goodbye   ")
        
        // same size
        XCTAssertEqual(Hitch(string: "Hello Hello Hello Hello Hello Hello Hello Hello").replace(occurencesOf: "Hello", with: "12345"), "12345 12345 12345 12345 12345 12345 12345 12345")
        XCTAssertEqual(Hitch(string: "   Hello Hello Hello Hello Hello Hello Hello Hello   ").replace(occurencesOf: "Hello", with: "12345"), "   12345 12345 12345 12345 12345 12345 12345 12345   ")
    }
    
    func testHitchAsKeys() {
        
        var info = [HalfHitch: Int]()
        
        let hitch: HalfHitch = "Hello CrUeL world"
        
        info[HalfHitch(source: hitch, from: 0, to: 5)] = 0
        info[HalfHitch(source: hitch, from: 6, to: 11)] = 1
        info[HalfHitch(source: hitch, from: 12, to: 17)] = 2
        
        let key: HalfHitch = "Hello"
        XCTAssertNotNil(info[key])
    }
    
    func testNullHalfHitch() {
        let halfHitch = HalfHitch()
        for _ in halfHitch {
            XCTFail()
        }
        
        let _ = halfHitch[1]
    }
    
    func testEqualityPerf() {
        let sourceHitches: [HalfHitch] = [
            "George the seventh123",
            "John the third1234567",
            "Henry the twelveth123",
            "Dennis the mennis1234",
            "Calvin and the Hobbes"
        ]
        
        let match: HalfHitch = "John the third1234567"
        var numMatches = 0
        
        // bisec: 0.383
        // biequal: 0.325
        // CHitch.swift: 0.175
        // v0.4.0 rework: 0.061
        
        measure {
            for hitch in sourceHitches {
                for _ in 0..<10000000 {
                    if hitch == match {
                        numMatches += 1
                    }
                }
            }
        }
        
        XCTAssertEqual(numMatches, 10000000 * 10)
    }
}

extension HalfHitchTests {
    static var allTests: [(String, (HalfHitchTests) -> () throws -> Void)] {
        return [
            ("testSimpleCreate", testSimpleCreate),
            ("testIteration", testIteration),
            ("testIterationRange", testIterationRange),
            ("testDirectAccess", testDirectAccess),
            ("testSubscript", testSubscript),
            ("testContainsSingle", testContainsSingle),
            ("testHashable", testHashable),
            ("testEquality", testEquality),
            ("testEpoch", testEpoch),
            ("testExtract", testExtract),
            ("testIndexOf", testIndexOf),
            ("testLastIndexOf", testLastIndexOf),
            ("testLastIndexOf2", testLastIndexOf2),
            ("testIndexOf3", testIndexOf3),
            ("testHalfHitchFromData0", testHalfHitchFromData0),
            ("testHalfHitch0", testHalfHitch0),
            ("testHalfHitchToInt0", testHalfHitchToInt0),
            ("testHalfHitchToDouble0", testHalfHitchToDouble0),
            ("testSubstring0", testSubstring0),
            ("testSubstring1", testSubstring1),
            ("testSubstring2", testSubstring2),
            ("testSubstring3", testSubstring3),
            ("testStartsWith1", testStartsWith1),
            ("testStartsWith2", testStartsWith2),
            ("testStartsWith3", testStartsWith3),
            ("testStartsWith4", testStartsWith4),
            ("testUnescaping", testUnicodeUnescaping),
            ("testEscaping", testUnicodeEscaping),
            ("testComparable", testComparable),
            ("testToInt", testToInt),
            ("testToIntFuzzy", testToIntFuzzy),
            ("testToDoubleFuzzy", testToDoubleFuzzy),
            ("testSplitToDouble", testSplitToDouble),
            ("testToDouble", testToDouble),
            ("testReplace1", testReplace1),
            ("testReplace2", testReplace2),
            ("testHitchAsKeys", testHitchAsKeys),
            ("testNullHalfHitch", testNullHalfHitch),
            
            // Performance tests cannot be run without XCode because we cannot test using release configuration
            //("testEqualityPerf", testEqualityPerf)
        ]
    }
}
