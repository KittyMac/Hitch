import XCTest
@testable import Hitch

let lorem = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."

final class HitchTests: XCTestCase {
        
    func testSimpleCreate() {
        let hello = "Hello"
        XCTAssertEqual(hello.hitch().description, hello)
    }
    
    func testAppendToEmpty() {
        let hello = Hitch()
        hello.append(.h)
        hello.append(.e)
        hello.append(.l)
        hello.append(.l)
        hello.append(.o)
        XCTAssertEqual(hello, "hello")
    }
    
    func testToLower() {
        let hello = "Hello"
        XCTAssertEqual(hello.hitch().lowercase().description, hello.lowercased())
    }
    
    func testToUpper() {
        let hello = "Hello"
        XCTAssertEqual(hello.hitch().uppercase().description, hello.uppercased())
    }
    
    func testIteration() {
        let hello = "Hello".hitch()
        
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
        let hello = "Hello".hitch()
        
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
        lorem.hitch().using { (bytes) in
            XCTAssertEqual(bytes[6], 105)
            XCTAssertEqual(bytes[3], 101)
        }
    }
    
    func testSubscript() {
        let hitchLorem = lorem.hitch()
        XCTAssertEqual(hitchLorem[6], 105)
        XCTAssertEqual(hitchLorem[3], 101)
    }
    
    func testContainsSingle() {
        let hitchLorem = lorem.hitch()
        XCTAssertTrue(hitchLorem.contains(111))
        XCTAssertFalse(hitchLorem.contains(16))
    }
    
    func testHashable() {
        let swiftKey1 = "key1"
        let hitchKey1 = swiftKey1.hitch()
        
        let swiftKey2 = "key2"
        let hitchKey2 = swiftKey2.hitch()
        
        var swiftDict: [String: Int] = [:]
        var hitchDict: [Hitch: Int] = [:]
        
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
        let hitchLorem = lorem.hitch()
        
        XCTAssertTrue(Hitch.empty == Hitch.empty)
        XCTAssertTrue(HalfHitch.empty == HalfHitch.empty)
        
        XCTAssertTrue(swiftLorem == swiftLorem)
        XCTAssertTrue(swiftLorem == hitchLorem)
        XCTAssertTrue(hitchLorem == swiftLorem)
        XCTAssertTrue(hitchLorem == hitchLorem)
    }
    
    func testEpoch() {
        XCTAssertEqual("4/30/2021 12:00:00 AM".hitch().toEpoch(), 1619740800)
        XCTAssertEqual("4/30/2021 1:00:00 AM".hitch().toEpoch(), 1619744400)
        XCTAssertEqual("4/30/2021 8:19:27 AM".hitch().toEpoch(), 1619770767)
        XCTAssertEqual("4/30/2021 8:19:27 PM".hitch().toEpoch(), 1619813967)
        XCTAssertEqual("4/30/2021 12:00:00 PM".hitch().toEpoch(), 1619784000)
        XCTAssertEqual("4/30/2021 1:19:27 PM".hitch().toEpoch(), 1619788767)
        XCTAssertEqual("4/30/2021 11:59:59 PM".hitch().toEpoch(), 1619827199)
        
    }
    
    func testData() {
        let hitchLorem = lorem.hitch()
        
        let loremData = hitchLorem.dataNoCopy()
        let hitchLorem2 = Hitch(data: loremData)
        
        XCTAssertEqual(hitchLorem, hitchLorem2)
    }
    
    func testSubdata() {
        let hitchLorem = lorem.hitch()
        
        let loremData = hitchLorem.dataNoCopy(start: 6,
                                              end: 11)
        let hitchLorem2 = Hitch(data: loremData)
        
        XCTAssertEqual("ipsum", hitchLorem2)
        
        let loremData2 = hitchLorem.dataNoCopy(start: 6)
        
        XCTAssertEqual(439, loremData2.count)
    }
    
    func testExtract() {
        let test1 = """
        "value1": 27,
        "value2": 27,
        value3: 27,
        "value4": "6.0",
        """.hitch()
        
        XCTAssertEqual(test1.extract(#""value1""#, ",")?.toInt(fuzzy: true) ?? 0, 27)
        XCTAssertEqual(test1.extract(#""value2""#, ",")?.toInt(fuzzy: true) ?? 0, 27)
        XCTAssertEqual(test1.extract(#"value3"#, ",")?.toInt(fuzzy: true) ?? 0, 27)
        XCTAssertEqual(test1.extract(#""value4": ""#, "\""), "6.0")
    }
    
    func testIndexOf() {
        let hitchLorem = lorem.hitch()
        let hitchNeedle = Hitch(string: "nulla pariatur")
        
        XCTAssertEqual(hitchLorem.firstIndex(of: hitchNeedle), 319)
    }
    
    func testLastIndexOf() {
        let hitchLorem = "/true|false/".hitch()
        let hitchNeedle = Hitch(string: "/")
        
        XCTAssertEqual(hitchLorem.lastIndex(of: hitchNeedle), 11)
    }
    
    func testLastIndexOf2() {
        let hitchLorem = "/true|false/".hitch()
        XCTAssertEqual(hitchLorem.lastIndex(of: UInt8.forwardSlash), 11)
    }
    
    func testIndexOf3() {
        let hitchLorem = lorem.hitch()
        let hitchNeedle = Hitch(string: "nulla pariatur")
        
        XCTAssertEqual(hitchLorem.lastIndex(of: hitchNeedle), 319)
    }
    
    func testHalfHitchEquality() {
        let hitch = "Hello world again".hitch()
        let halfHitch = hitch.halfhitch()
        XCTAssertTrue(hitch == halfHitch)
    }
    
    func testHalfHitch0() {
        let hitch = "Hello world again".hitch()
        XCTAssertEqual(hitch.halfhitch(6, 11).description, "world")
    }
    
    func testHalfHitchAppend0() {
        let hitch0 = "Hello world again".hitch()
        let hitch1 = "Hello world again".hitch()
        let hh = hitch1.halfhitch(5, 11)
        hitch0.append(hh)
        XCTAssertEqual(hitch0, "Hello world again world")
    }
    
    func testHalfHitchToInt0() {
        let hitch = "Hello 123456 again".hitch()
        XCTAssertEqual(hitch.halfhitch(6, 12).toInt(), 123456)
    }
    
    func testHalfHitchToDouble0() {
        let hitch = "Hello 123456.123456 again".hitch()
        XCTAssertEqual(hitch.halfhitch(6, 19).toDouble(), 123456.123456)
    }
    
    func testSubstring0() {
        let hitch = "Hello world again".hitch()
        XCTAssertEqual(hitch.substring(6, 11), "world")
    }
    
    func testSubstring1() {
        let hitch = "Hello world again".hitch()
        XCTAssertNil(hitch.substring(99, 11))
    }
    
    func testSubstring2() {
        let hitch = "Hello world again".hitch()
        XCTAssertNil(hitch.substring(99, 120))
    }
    
    func testSubstring3() {
        let hitch = "Hello world again".hitch()
        XCTAssertNil(hitch.substring(-100, 120))
    }
    
    func testStartsWith1() {
        let hitch = "Hello world again".hitch()
        XCTAssertTrue(hitch.starts(with: "Hello "))
    }
    
    func testStartsWith2() {
        let hitch = "Hello world again".hitch()
        XCTAssertFalse(hitch.starts(with: "ello "))
    }
    
    func testStartsWith3() {
        let hitch = "Hello world again".hitch()
        XCTAssertFalse(hitch.starts(with: "world"))
    }
    
    func testStartsWith4() {
        let hitch = "Hello world again".hitch()
        XCTAssertTrue(hitch.starts(with: Hitch(string: "Hello world agai")))
    }
    
    func testEndsWith1() {
        let hitch = "Hello world again".hitch()
        XCTAssertTrue(hitch.ends(with: " again"))
    }
    
    func testEndsWith2() {
        let hitch = "Hello world again".hitch()
        XCTAssertFalse(hitch.ends(with: "ello "))
    }
    
    func testEndsWith3() {
        let hitch = "Hello world again".hitch()
        XCTAssertFalse(hitch.ends(with: "world"))
    }
    
    func testEndsWith4() {
        let hitch = "Hello world again".hitch()
        XCTAssertTrue(hitch.ends(with: Hitch(string: "ello world again")))
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
        XCTAssertEqual(hitch1, "A ö Ж € 𝄞")
        
        var hitch2 = #"\u0041 \u00F6 \u0416 \u20AC \u{1D11E}"#.halfhitch()
        hitch2.unescape()
        XCTAssertEqual(hitch2, "A ö Ж € 𝄞")
        
    }
    
    func testEscaping() {
        let hitch0 = "\\ \' \" \t \n \r".hitch().escaped(unicode: true,
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
        
        let hitch1 = "A ö Ж € 𝄞".hitch()
        XCTAssertEqual(hitch1.escaped(unicode: true,
                                      singleQuotes: true), #"A \u00F6 \u0416 \u20AC \u{1D11E}"#)
        XCTAssertEqual(hitch1.halfhitch().escaped(unicode: true,
                                                  singleQuotes: true), #"A \u00F6 \u0416 \u20AC \u{1D11E}"#)
    }
    
    func testInsert() {
        let hitch = "".hitch()
        let values: [UInt8] = [53, 52, 51, 50, 49]
        
        for value in values {
            hitch.insert(value, index: 0)
        }
        
        XCTAssertEqual(hitch, "12345")
    }
    
    func testInsert2() {
        let hitch = "".hitch()
        let values: [UInt8] = [53, 52, 51, 50, 49]
        
        for value in values {
            hitch.insert(value, index: 99)
        }
        
        XCTAssertEqual(hitch, "54321")
    }
    
    func testInsert3() {
        let hitch = "store.book".hitch()
        XCTAssertEqual(hitch.insert("$.", index: 0), "$.store.book")
        XCTAssertEqual(hitch.insert("$.", index: -99), "$.$.store.book")
        XCTAssertEqual(hitch.insert("$.", index: 99), "$.$.store.book$.")
    }
    
    func testComparable() {
        let hitch1 = "Apple".hitch()
        let hitch2 = "apple".hitch()
        
        XCTAssertEqual(hitch1 < hitch2, "Apple" < "apple")
        
        XCTAssertEqual(Hitch(string: "5") < Hitch(string: "5.1.2"), "5" < "5.1.2")
        XCTAssertEqual(Hitch(string: "5") > Hitch(string: "5.1.2"), "5" > "5.1.2")
    }
    
    func testAppendValue() {
        let values = [
            12345,
            0,
            -12345
        ]
        for value in values {
            XCTAssertEqual("hello: ".hitch().append(number: value), "hello: \(value)".hitch())
        }
    }
    
    func testInsertValue() {
        let values = [
            12345,
            0,
            -12345
        ]
        for value in values {
            XCTAssertEqual("hello  world".hitch().insert(number: value, index: 6), "hello \(value) world".hitch())
        }
    }
    
    func testAppendDouble() {
        let values = [
            12345.012345,
            0,
            0.5,
            -12345.012345,
            8.01234567890123456789,
            8.0123456789,
            12345.12345
        ]
        for value in values {
            XCTAssertEqual("hello: ".hitch().append(double: value), "hello: \(value)".hitch())
        }
    }
    
    func testInsertDouble() {
        let values = [
            12345.012345,
            0,
            0.5,
            -12345.012345,
            8.01234567890123456789,
            8.0123456789,
            12345.12345
        ]
        for value in values {
            XCTAssertEqual("hello  world".hitch().insert(double: value, index: 6), "hello \(value) world".hitch())
        }
    }
    
    func testTrim() {        
        XCTAssertEqual(Hitch(string: "Hello   \t\n\r  ").trim(), "Hello")
        XCTAssertEqual(Hitch(string: "   \t\n\r  Hello").trim(), "Hello")
        XCTAssertEqual(Hitch(string: "   \t\n\r  Hello   \t\n\r  ").trim(), "Hello")
        XCTAssertEqual(Hitch(string: "Hello").trim(), "Hello")
    }
    
    func testInitFromHitch() {
        let hitch = "Hello world again".hitch()
        XCTAssertEqual(Hitch(hitch: hitch), "Hello world again")
    }
    
    func testSplitToInt() {
        let hitch = "1,2,3,4,52345,-6,7,8134,9,-72,  5  ,  2  4  ".hitch()
        var array = [Int]()
            
        let parts = hitch.split(separator: 44)
        for part in parts {
            guard let part = part.toInt() else { continue }
            array.append(part)
        }
        
        let result = array.map { String($0) }.joined(separator: ",").hitch()
        XCTAssertEqual(result, "1,2,3,4,52345,-6,7,8134,9,-72,5".hitch())
    }
    
    func testToInt() {
        let hitch = "  5  ".hitch()
        XCTAssertEqual(hitch.toInt(), 5)
        
        XCTAssertNil("A".hitch().toInt())
        XCTAssertNil("B".hitch().toInt())
    }
    
    func testToIntFuzzy() {
        XCTAssertEqual("22".hitch().toInt(fuzzy: true), 22)
        XCTAssertEqual("39".hitch().toInt(fuzzy: true), 39)
        XCTAssertEqual("40012".hitch().toInt(fuzzy: true), 40012)

        XCTAssertEqual("  sdf asdf22asdfasd f".hitch().toInt(fuzzy: true), 22)
        XCTAssertEqual("gsdg39sdf .sdfsd".hitch().toInt(fuzzy: true), 39)
        XCTAssertEqual("sdfsdf40012sdfg ".hitch().toInt(fuzzy: true), 40012)
    }
    
    func testToDoubleFuzzy() {
        XCTAssertEqual("2.2".hitch().toDouble(fuzzy: true), 2.2)
        XCTAssertEqual("3.9".hitch().toDouble(fuzzy: true), 3.9)
        XCTAssertEqual("4.0012".hitch().toDouble(fuzzy: true), 4.0012)

        XCTAssertEqual("  sdf asdf2.2asdfasd f".hitch().toDouble(fuzzy: true), 2.2)
        XCTAssertEqual("gsdg3.9sdf .sdfsd".hitch().toDouble(fuzzy: true), 3.9)
        XCTAssertEqual("sdfsdf4.0012sdfg ".hitch().toDouble(fuzzy: true), 4.0012)
    }
    
    func testSplitToDouble() {
        //let hitch = "1,2.2,3.9,4.0012,52345.24,-6.0,7.12,8134.99,9.320547,-72.25,  5.6  ,  2.2  4.4  ".hitch()
        XCTAssertEqual("2.2".hitch().toDouble(), 2.2)
        XCTAssertEqual("3.9".hitch().toDouble(), 3.9)
        XCTAssertEqual("4.0012".hitch().toDouble(), 4.0012)
        XCTAssertEqual("52345.24".hitch().toDouble(), 52345.24)
        XCTAssertEqual("-6.0".hitch().toDouble(), -6.0)
        XCTAssertEqual("7.12".hitch().toDouble(), 7.12)
        XCTAssertEqual("8134.99".hitch().toDouble(), 8134.99)
        XCTAssertEqual("9.320547".hitch().toDouble(), 9.320547)
        XCTAssertEqual("-72.25".hitch().toDouble(), -72.25)
        XCTAssertEqual("  5.6  ".hitch().toDouble(), 5.6)
        XCTAssertNil("  2.2  4.4  ".hitch().toDouble())
        
        XCTAssertNil("A".hitch().toDouble())
        XCTAssertNil("B".hitch().toDouble())
    }
    
    func testToDouble() {
        let hitch = "  5.2567  ".hitch()
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
    
    private func splitTest(_ separator: Hitch, _ hitch: Hitch, _ result: [Hitch]) {
        let hhresult = result.map { $0.halfhitch() }
        let stringJoinedResult = result.map { $0.description }.joined(separator: "!")
        
        let parts: [Hitch] = hitch.components(separatedBy: separator)
        XCTAssertEqual(parts, result)
        XCTAssertEqual(parts.joined(separator: "!"), stringJoinedResult.hitch())
        
        let parts2: [HalfHitch] = hitch.halfhitch().components(separatedBy: separator)
        XCTAssertEqual(parts2, hhresult)
        XCTAssertEqual(parts2.joined(separator: "!"), stringJoinedResult.hitch())
        
        let parts3: [HalfHitch] = hitch.halfhitch().components(separatedBy: separator.halfhitch())
        XCTAssertEqual(parts3, hhresult)
        XCTAssertEqual(parts3.joined(separator: "!"), stringJoinedResult.hitch())
    }
    
    func testSplit0() {
        splitTest("\n", "hello world", ["hello world"])
        splitTest(",", "1,2,3,4,5,6,7,8,9,10,11,12,13,14", ["1","2","3","4","5","6","7","8","9","10","11","12","13","14"])
        splitTest(" ", "   hello       world   again   ", ["hello","world","again"])
        splitTest("<->", "   hello<->world<->again   ", ["   hello","world","again   "])
    }
    
    func testExportAsData() {
        let hitch = "Hello World".hitch()
        let data = hitch.exportAsData()
        
        XCTAssertEqual(String(data: data, encoding: .utf8), "Hello World")
        XCTAssertEqual(hitch.count, 0)
    }
    
    func testHitchAsKeys() {
        
        var info = [HalfHitch: Int]()
        
        let hitch = "Hello CrUeL world".hitch()
        
        info[HalfHitch(source: hitch, from: 0, to: 5)] = 0
        info[HalfHitch(source: hitch, from: 6, to: 11)] = 1
        info[HalfHitch(source: hitch, from: 12, to: 17)] = 2
        
        let key = "Hello".hitch()
        XCTAssertNotNil(info[key.halfhitch()])
    }
    
    func testNullHalfHitch() {
        let halfHitch = HalfHitch()
        for _ in halfHitch {
            XCTFail()
        }
        
        let _ = halfHitch[1]
    }
    
    func testHitchEqualityPerf() {
        let sourceHitches = [
            "George the seventh123".hitch(),
            "John the third1234567".hitch(),
            "Henry the twelveth123".hitch(),
            "Dennis the mennis1234".hitch(),
            "Calvin and the Hobbes".hitch()
        ]
        
        let match = "John the third1234567".hitch()
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
    
    func testHalfHitchEqualityPerf() {
        let sourceHitches = [
            "George the seventh123".halfhitch(),
            "John the third1234567".halfhitch(),
            "Henry the twelveth123".halfhitch(),
            "Dennis the mennis1234".halfhitch(),
            "Calvin and the Hobbes".halfhitch()
        ]
        
        let match = "John the third1234567".hitch().halfhitch()
        var numMatches = 0
        
        // bisec: 0.606
        // blkequalblk: 0.319
        // CHitch.swift: 0.160
        
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
    
    func testHitchToHalfHitchEqualityPerf() {
        let sourceHitches = [
            "George the seventh123".hitch().halfhitch(),
            "John the third1234567".hitch().halfhitch(),
            "Henry the twelveth123".hitch().halfhitch(),
            "Dennis the mennis1234".hitch().halfhitch(),
            "Calvin and the Hobbes".hitch().halfhitch()
        ]
        
        let match = "John the third1234567".hitch()
        var numMatches = 0
                
        // blkequalblk: 0.298
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
