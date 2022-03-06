import XCTest
@testable import Hitch

final class HalfHitchTests: XCTestCase {
    
    func testSimpleCreate() {
        let hello: HalfHitch = "Hello"
        XCTAssertEqual(hello.description, "Hello")
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
    
    func testEpoch() {
        XCTAssertEqual(HalfHitch("4/30/2021 12:00:00 AM").toEpoch(), 1619740800)
        XCTAssertEqual(HalfHitch("4/30/2021 1:00:00 AM").toEpoch(), 1619744400)
        XCTAssertEqual(HalfHitch("4/30/2021 8:19:27 AM").toEpoch(), 1619770767)
        XCTAssertEqual(HalfHitch("4/30/2021 8:19:27 PM").toEpoch(), 1619813967)
        XCTAssertEqual(HalfHitch("4/30/2021 12:00:00 PM").toEpoch(), 1619784000)
        XCTAssertEqual(HalfHitch("4/30/2021 1:19:27 PM").toEpoch(), 1619788767)
        XCTAssertEqual(HalfHitch("4/30/2021 11:59:59 PM").toEpoch(), 1619827199)
        
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
    
    func testUnescaping() {
        // A, ö, Ж, €, 𝄞
        let hitch0 = Hitch(string: #"\\ \' \" \t \n \r"#)
        hitch0.unescape()
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
        hitch1.unescape()
        XCTAssertEqual(hitch1, "A ö Ж € 𝄞")
        
        var hitch2: HalfHitch = HalfHitch(string: #"\u0041 \u00F6 \u0416 \u20AC \u{1D11E}"#)
        hitch2.unescape()
        XCTAssertEqual(hitch2, "A ö Ж € 𝄞")
        
    }
    
    func testEscaping() {
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
            ("testUnescaping", testUnescaping),
            ("testEscaping", testEscaping),
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
