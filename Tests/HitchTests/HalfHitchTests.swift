import XCTest
@testable import Hitch

final class HalfHitchTests: XCTestCase {
    
    func testSimpleCreate() {
        let hello = "Hello"
        XCTAssertEqual(hello.halfhitch().description, hello)
    }
            
    func testIteration() {
        let hello = "Hello".halfhitch()
        
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
        let hello = "Hello".halfhitch()
        
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
        HalfHitch(string: lorem).using { (bytes) in
            XCTAssertEqual(bytes[6], 105)
            XCTAssertEqual(bytes[3], 101)
        }
    }
    
    func testSubscript() {
        let hitchLorem = lorem.halfhitch()
        XCTAssertEqual(hitchLorem[6], 105)
        XCTAssertEqual(hitchLorem[3], 101)
    }
    
    func testContainsSingle() {
        let hitchLorem = lorem.halfhitch()
        XCTAssertTrue(hitchLorem.contains(111))
        XCTAssertFalse(hitchLorem.contains(16))
    }
    
    func testHashable() {
        let swiftKey1 = "key1"
        let hitchKey1 = swiftKey1.halfhitch()
        
        let swiftKey2 = "key2"
        let hitchKey2 = swiftKey2.halfhitch()
        
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
        let swiftLorem = lorem
        let hitchLorem = lorem.halfhitch()
        
        XCTAssertTrue(Hitch.empty == Hitch.empty)
        XCTAssertTrue(HalfHitch.empty == HalfHitch.empty)
        
        XCTAssertTrue(swiftLorem == swiftLorem)
        XCTAssertTrue(swiftLorem == hitchLorem)
        XCTAssertTrue(hitchLorem == swiftLorem)
        XCTAssertTrue(hitchLorem == hitchLorem)
    }
    
    func testEpoch() {
        XCTAssertEqual("4/30/2021 12:00:00 AM".halfhitch().toEpoch(), 1619740800)
        XCTAssertEqual("4/30/2021 1:00:00 AM".halfhitch().toEpoch(), 1619744400)
        XCTAssertEqual("4/30/2021 8:19:27 AM".halfhitch().toEpoch(), 1619770767)
        XCTAssertEqual("4/30/2021 8:19:27 PM".halfhitch().toEpoch(), 1619813967)
        XCTAssertEqual("4/30/2021 12:00:00 PM".halfhitch().toEpoch(), 1619784000)
        XCTAssertEqual("4/30/2021 1:19:27 PM".halfhitch().toEpoch(), 1619788767)
        XCTAssertEqual("4/30/2021 11:59:59 PM".halfhitch().toEpoch(), 1619827199)
        
    }
        
    func testExtract() {
        let test1 = """
        "value1": 27,
        "value2": 27,
        value3: 27,
        "value4": "6.0",
        """.halfhitch()
        
        XCTAssertEqual(test1.extract(#""value1""#.hitch(), ",".hitch())?.toInt(fuzzy: true) ?? 0, 27)
        XCTAssertEqual(test1.extract(#""value2""#.hitch(), ",".hitch())?.toInt(fuzzy: true) ?? 0, 27)
        XCTAssertEqual(test1.extract(#"value3"#.hitch(), ",".hitch())?.toInt(fuzzy: true) ?? 0, 27)
        XCTAssertEqual(test1.extract(#""value4": ""#.hitch(), "\"".hitch()), "6.0".hitch())
    }
    
    func testIndexOf() {
        let hitchLorem = lorem.halfhitch()
        let hitchNeedle = Hitch(string: "nulla pariatur")
        
        XCTAssertEqual(hitchLorem.firstIndex(of: hitchNeedle), 319)
    }
    
    func testLastIndexOf() {
        let hitchLorem = "/true|false/".halfhitch()
        let hitchNeedle = Hitch(string: "/")
        
        XCTAssertEqual(hitchLorem.lastIndex(of: hitchNeedle), 11)
    }
    
    func testLastIndexOf2() {
        let hitchLorem = "/true|false/".halfhitch()
        XCTAssertEqual(hitchLorem.lastIndex(of: UInt8.forwardSlash), 11)
    }
    
    func testIndexOf3() {
        let hitchLorem = lorem.halfhitch()
        let hitchNeedle = Hitch(string: "nulla pariatur")
        
        XCTAssertEqual(hitchLorem.lastIndex(of: hitchNeedle), 319)
    }
        
    func testHalfHitchFromData0() {
        let data = "Hello world again".data(using: .utf8)!
        HalfHitch.using(data: data, from: 6, to: 11) { hh in
            XCTAssertEqual(hh.description, "world")
        }
    }
    
    func testHalfHitch0() {
        let hitch = "Hello world again".halfhitch()
        XCTAssertEqual(hitch.substring(6, 11)?.description, "world")
    }
        
    func testHalfHitchToInt0() {
        let hitch = "Hello 123456 again".halfhitch()
        XCTAssertEqual(hitch.substring(6, 12)?.toInt(), 123456)
    }
    
    func testHalfHitchToDouble0() {
        let hitch = "Hello 123456.123456 again".halfhitch()
        XCTAssertEqual(hitch.substring(6, 19)?.toDouble(), 123456.123456)
    }
    
    func testSubstring0() {
        let hitch = "Hello world again".halfhitch()
        XCTAssertEqual(hitch.substring(6, 11), "world".hitch())
    }
    
    func testSubstring1() {
        let hitch = "Hello world again".halfhitch()
        XCTAssertNil(hitch.substring(99, 11))
    }
    
    func testSubstring2() {
        let hitch = "Hello world again".halfhitch()
        XCTAssertNil(hitch.substring(99, 120))
    }
    
    func testSubstring3() {
        let hitch = "Hello world again".halfhitch()
        XCTAssertNil(hitch.substring(-100, 120))
    }
    
    func testStartsWith1() {
        let hitch = "Hello world again".halfhitch()
        XCTAssertTrue(hitch.starts(with: "Hello "))
    }
    
    func testStartsWith2() {
        let hitch = "Hello world again".halfhitch()
        XCTAssertFalse(hitch.starts(with: "ello "))
    }
    
    func testStartsWith3() {
        let hitch = "Hello world again".halfhitch()
        XCTAssertFalse(hitch.starts(with: "world"))
    }
    
    func testStartsWith4() {
        let hitch = "Hello world again".halfhitch()
        XCTAssertTrue(hitch.starts(with: Hitch(string: "Hello world agai")))
    }
    
    func testUnescaping() {
        // A, ö, Ж, €, 𝄞
        let hitch0 = #"\\ \' \" \t \n \r"#.hitch().unescape()
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
        
        let hitch1 = #"\u0041 \u00F6 \u0416 \u20AC \u{1D11E}"#.hitch().unescape()
        XCTAssertEqual(hitch1, "A ö Ж € 𝄞".hitch())
        
        var hitch2 = #"\u0041 \u00F6 \u0416 \u20AC \u{1D11E}"#.hitch().halfhitch()
        hitch2.unescape()
        XCTAssertEqual(hitch2, "A ö Ж € 𝄞".halfhitch())
        
    }
    
    func testEscaping() {
        let hitch0 = "\\ \' \" \t \n \r".halfhitch().escaped(unicode: true,
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
        
        let hitch1 = "A ö Ж € 𝄞".halfhitch()
        XCTAssertEqual(hitch1.escaped(unicode: true,
                                      singleQuotes: true), #"A \u00F6 \u0416 \u20AC \u{1D11E}"#.hitch())
        XCTAssertEqual(hitch1.hitch().escaped(unicode: true,
                                              singleQuotes: true), #"A \u00F6 \u0416 \u20AC \u{1D11E}"#.hitch())
    }
    
    func testComparable() {
        let hitch1 = "Apple".halfhitch()
        let hitch2 = "apple".halfhitch()
        
        XCTAssertEqual(hitch1 < hitch2, "Apple" < "apple")
        
        XCTAssertEqual(Hitch(string: "5") < Hitch(string: "5.1.2"), "5" < "5.1.2")
        XCTAssertEqual(Hitch(string: "5") > Hitch(string: "5.1.2"), "5" > "5.1.2")
    }
       
    func testSplitToInt() {
        let hitch = "1,2,3,4,52345,-6,7,8134,9,-72,  5  ,  2  4  ".halfhitch()
        var array = [Int]()
            
        let parts = hitch.split(separator: 44)
        for part in parts {
            guard let part = part.toInt() else { continue }
            array.append(part)
        }
        
        let result = array.map { String($0) }.joined(separator: ",").halfhitch()
        XCTAssertEqual(result, "1,2,3,4,52345,-6,7,8134,9,-72,5".halfhitch())
    }
    
    func testToInt() {
        let hitch = "  5  ".halfhitch()
        XCTAssertEqual(hitch.toInt(), 5)
        
        XCTAssertNil("A".halfhitch().toInt())
        XCTAssertNil("B".halfhitch().toInt())
    }
    
    func testToIntFuzzy() {
        XCTAssertEqual("22".halfhitch().toInt(fuzzy: true), 22)
        XCTAssertEqual("39".halfhitch().toInt(fuzzy: true), 39)
        XCTAssertEqual("40012".halfhitch().toInt(fuzzy: true), 40012)

        XCTAssertEqual("  sdf asdf22asdfasd f".halfhitch().toInt(fuzzy: true), 22)
        XCTAssertEqual("gsdg39sdf .sdfsd".halfhitch().toInt(fuzzy: true), 39)
        XCTAssertEqual("sdfsdf40012sdfg ".halfhitch().toInt(fuzzy: true), 40012)
    }
    
    func testToDoubleFuzzy() {
        XCTAssertEqual("2.2".halfhitch().toDouble(fuzzy: true), 2.2)
        XCTAssertEqual("3.9".halfhitch().toDouble(fuzzy: true), 3.9)
        XCTAssertEqual("4.0012".halfhitch().toDouble(fuzzy: true), 4.0012)

        XCTAssertEqual("  sdf asdf2.2asdfasd f".halfhitch().toDouble(fuzzy: true), 2.2)
        XCTAssertEqual("gsdg3.9sdf .sdfsd".halfhitch().toDouble(fuzzy: true), 3.9)
        XCTAssertEqual("sdfsdf4.0012sdfg ".halfhitch().toDouble(fuzzy: true), 4.0012)
    }
    
    func testSplitToDouble() {
        //let hitch = "1,2.2,3.9,4.0012,52345.24,-6.0,7.12,8134.99,9.320547,-72.25,  5.6  ,  2.2  4.4  ".halfhitch()
        XCTAssertEqual("2.2".halfhitch().toDouble(), 2.2)
        XCTAssertEqual("3.9".halfhitch().toDouble(), 3.9)
        XCTAssertEqual("4.0012".halfhitch().toDouble(), 4.0012)
        XCTAssertEqual("52345.24".halfhitch().toDouble(), 52345.24)
        XCTAssertEqual("-6.0".halfhitch().toDouble(), -6.0)
        XCTAssertEqual("7.12".halfhitch().toDouble(), 7.12)
        XCTAssertEqual("8134.99".halfhitch().toDouble(), 8134.99)
        XCTAssertEqual("9.320547".halfhitch().toDouble(), 9.320547)
        XCTAssertEqual("-72.25".halfhitch().toDouble(), -72.25)
        XCTAssertEqual("  5.6  ".halfhitch().toDouble(), 5.6)
        XCTAssertNil("  2.2  4.4  ".halfhitch().toDouble())
        
        XCTAssertNil("A".halfhitch().toDouble())
        XCTAssertNil("B".halfhitch().toDouble())
    }
    
    func testToDouble() {
        let hitch = "  5.2567  ".halfhitch()
        XCTAssertEqual(hitch.toDouble(), 5.2567)
    }
    
    func testReplace1() {
        // replace(occurencesOf hitch: Hitch, with: Hitch, ignoreCase: Bool = false)
        XCTAssertEqual(Hitch(string: "Hello CrUeL world").replace(occurencesOf: "CrUeL".hitch(), with: "happy".hitch()), "Hello happy world".hitch())
        XCTAssertEqual(Hitch(string: "Hello CrUeL world").replace(occurencesOf: "cRuEl".hitch(), with: "happy".hitch(), ignoreCase: true), "Hello happy world".hitch())
    }
    
    func testReplace2() {
        // reduction
        XCTAssertEqual(Hitch(string: "Hello Hello Hello Hello Hello Hello Hello Hello").replace(occurencesOf: "Hello".hitch(), with: "Bye".hitch()), "Bye Bye Bye Bye Bye Bye Bye Bye".hitch())
        XCTAssertEqual(Hitch(string: "   Hello Hello Hello Hello Hello Hello Hello Hello   ").replace(occurencesOf: "Hello".hitch(), with: "Bye".hitch()), "   Bye Bye Bye Bye Bye Bye Bye Bye   ".hitch())
        
        // expansion
        XCTAssertEqual(Hitch(string: "Hello Hello Hello Hello Hello Hello Hello Hello").replace(occurencesOf: "Hello".hitch(), with: "Goodbye".hitch(), ignoreCase: true), "Goodbye Goodbye Goodbye Goodbye Goodbye Goodbye Goodbye Goodbye".hitch())
        XCTAssertEqual(Hitch(string: "   Hello Hello Hello Hello Hello Hello Hello Hello   ").replace(occurencesOf: "Hello".hitch(), with: "Goodbye".hitch(), ignoreCase: true), "   Goodbye Goodbye Goodbye Goodbye Goodbye Goodbye Goodbye Goodbye   ".hitch())
        
        // same size
        XCTAssertEqual(Hitch(string: "Hello Hello Hello Hello Hello Hello Hello Hello").replace(occurencesOf: "Hello".hitch(), with: "12345".hitch()), "12345 12345 12345 12345 12345 12345 12345 12345".hitch())
        XCTAssertEqual(Hitch(string: "   Hello Hello Hello Hello Hello Hello Hello Hello   ").replace(occurencesOf: "Hello".hitch(), with: "12345".hitch()), "   12345 12345 12345 12345 12345 12345 12345 12345   ".hitch())
    }
    
    func testHitchAsKeys() {
        
        var info = [HalfHitch: Int]()
        
        let hitch = "Hello CrUeL world".halfhitch()
        
        info[HalfHitch(source: hitch, from: 0, to: 5)] = 0
        info[HalfHitch(source: hitch, from: 6, to: 11)] = 1
        info[HalfHitch(source: hitch, from: 12, to: 17)] = 2
        
        let key = "Hello".halfhitch()
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
        let sourceHitches = [
            "George the seventh123".halfhitch(),
            "John the third1234567".halfhitch(),
            "Henry the twelveth123".halfhitch(),
            "Dennis the mennis1234".halfhitch(),
            "Calvin and the Hobbes".halfhitch()
        ]
        
        let match = "John the third1234567".halfhitch()
        var numMatches = 0
        
        // bisec: 0.383
        // biequal: 0.325
        // CHitch.swift: 0.175
        
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

    static var allTests = [
        ("testSimpleCreate", testSimpleCreate),
    ]
}
