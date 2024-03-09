import XCTest

import Hitch

let loremStatic: StaticString = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
let lorem = loremStatic.description
let swiftLorem = lorem
let hitchLorem = Hitch(stringLiteral: loremStatic)
let halfhitchLorem = HalfHitch(stringLiteral: loremStatic)

struct TestHitchCodable: Codable {
    let x: Hitch
}

final class HitchTests: XCTestCase {
    
    func testCastAnyToHitch() {
        let unknown: Any? = [
            "test": Hitch(string: "test2")
        ]
        
        // note: linux will "crash" in here with
        // Could not cast value of type 'Hitch.Hitch' (0x56093e670f90) to 'Foundation.NSObject' (0x7f4ca74c5bd8).
        // From research it appears that any class type in swift on Linux which can be stored in a hashable (like
        // a set or a dictionary) must inherit from NSObject. This is super unfortunate and annoying, hopefully
        // it will be fixed in the future. Until them, Hitch is now a subclass of NSObject to avoid
        // this runtime crash
        if let unknown = unknown {
            switch unknown {
            case _ as NSNull:
                return
            case let _ as Hitch:
                break
            default:
                print("DEFAULT")
                break
            }
        }
    }
    
    func testNullifyTest() {
        let hitch = Hitch(string: "")
        
        hitch.append(number: 1)
        XCTAssertEqual(strcmp(hitch.raw()!, "1"), 0)
        hitch.append(number: 2)
        XCTAssertEqual(strcmp(hitch.raw()!, "12"), 0)
        hitch.append(number: 3)
        XCTAssertEqual(strcmp(hitch.raw()!, "123"), 0)
        hitch.append(number: 4)
        XCTAssertEqual(strcmp(hitch.raw()!, "1234"), 0)
        hitch.append(number: 5)
        XCTAssertEqual(strcmp(hitch.raw()!, "12345"), 0)
        
        XCTAssertEqual(hitch, "12345")
    }
    
    func testHitchInSet() {
        var collection = Set<Hitch>()
        
        collection.insert("12345")
        collection.insert("54321")
        
        XCTAssertEqual(collection.contains("12345"), true)
        XCTAssertEqual(collection.contains("54321"), true)
        XCTAssertEqual(collection.contains("HELLO"), false)
    }
    
    func testContentsOfFileError() {
        XCTAssertNil(Hitch(contentsOfFile: "/tmp/doesnotexist1343.html"))
    }
        
    func testSimpleCreate() {
        let hello = "Hello"
        XCTAssertEqual(hello.description, hello)
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
        let hello = Hitch(string: "Hello")
        XCTAssertEqual(hello.lowercase().description, "hello")
    }
    
    func testToUpper() {
        let hello = Hitch(string: "Hello")
        XCTAssertEqual(hello.uppercase().description, "HELLO")
    }
    
    func testIteration() {
        let hello: Hitch = "Hello"
        
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
        let hello: Hitch = "Hello"
        
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
        hitchLorem.using { (bytes) in
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
        let hitchKey1 = Hitch(string: swiftKey1)
        
        let swiftKey2 = "key2"
        let hitchKey2 = Hitch(string: swiftKey2)
        
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
        
    func testHashableInSet() {
        var stuff = Set<Hitch>()
        stuff.insert("Hitch1")
        stuff.insert("Hitch2")
        stuff.insert("Hitch3")
        stuff.insert("Hitch4")
        stuff.insert("Hitch5")
        stuff.insert("Hitch1")
        stuff.insert("Hitch2")
        stuff.insert("Hitch3")
        stuff.insert("Hitch4")
        stuff.insert("Hitch5")
        var array = Array(stuff)
        array.sort()
        XCTAssertEqual(array.description, "[Hitch1, Hitch2, Hitch3, Hitch4, Hitch5]")
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
        XCTAssertEqual(Hitch("4/30/2021 12:00:00 AM").toEpoch(), 1619740800)
        XCTAssertEqual(Hitch("4/30/2021 1:00:00 AM").toEpoch(), 1619744400)
        XCTAssertEqual(Hitch("4/30/2021 8:19:27 AM").toEpoch(), 1619770767)
        XCTAssertEqual(Hitch("4/30/2021 8:19:27 PM").toEpoch(), 1619813967)
        XCTAssertEqual(Hitch("4/30/2021 12:00:00 PM").toEpoch(), 1619784000)
        XCTAssertEqual(Hitch("4/30/2021 1:19:27 PM").toEpoch(), 1619788767)
        XCTAssertEqual(Hitch("4/30/2021 11:59:59 PM").toEpoch(), 1619827199)
        
        XCTAssertEqual(Hitch("2023-03-16 20:59:32.808000").toEpoch2(), 1679000372)
    }
    
    func testData() {
        let loremData = hitchLorem.dataNoCopy()
        let hitchLorem2 = Hitch(data: loremData)
        
        XCTAssertEqual(hitchLorem, hitchLorem2)
    }
    
    func testSubdata() {
        let loremData = hitchLorem.dataNoCopy(start: 6,
                                              end: 11)
        let hitchLorem2 = Hitch(data: loremData)
        
        XCTAssertEqual("ipsum", hitchLorem2)
        
        let loremData2 = hitchLorem.dataNoCopy(start: 6)
        
        XCTAssertEqual(439, loremData2.count)
    }
    
    func testExtract() {
        let test1: Hitch = """
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
        let hitchLorem: Hitch = "/true|false/"
        XCTAssertEqual(hitchLorem.lastIndex(of: "/"), 11)
    }
    
    func testLastIndexOf2() {
        let hitchLorem: Hitch = "/true|false/"
        XCTAssertEqual(hitchLorem.lastIndex(of: UInt8.forwardSlash), 11)
    }
    
    func testIndexOf3() {
        XCTAssertEqual(hitchLorem.lastIndex(of: "nulla pariatur"), 319)
    }
        
    func testHalfHitchFromData0() {
        let data = "Hello world again".data(using: .utf8)!
        HalfHitch.using(data: data, from: 6, to: 11) { hh in
            XCTAssertEqual(hh.description, "world")
        }
    }
    
    func testHalfHitchEquality() {
        let hitch: Hitch = "Hello world again"
        let halfHitch: HalfHitch = hitch.halfhitch()
        XCTAssertTrue(hitch == halfHitch)
    }
    
    func testHalfHitch0() {
        let hitch: Hitch = "Hello world again"
        XCTAssertEqual(hitch.halfhitch(6, 11).description, "world")
    }
    
    func testHalfHitchAppend0() {
        let hitch0 = Hitch(string: "Hello world again")
        let hitch1 = Hitch(string: "Hello world again")
        let hh = hitch1.halfhitch(5, 11)
        hitch0.append(hh)
        XCTAssertEqual(hitch0, "Hello world again world")
    }
    
    func testHalfHitchToInt0() {
        let hitch: Hitch = "Hello 123456 again"
        XCTAssertEqual(hitch.halfhitch(6, 12).toInt(), 123456)
    }
    
    func testHalfHitchToDouble0() {
        let hitch: Hitch = "Hello 123456.123456 again"
        XCTAssertEqual(hitch.halfhitch(6, 19).toDouble(), 123456.123456)
    }
    
    func testSubstring0() {
        let hitch: Hitch = "Hello world again"
        XCTAssertEqual(hitch.substring(6, 11), "world")
    }
    
    func testSubstring1() {
        let hitch: Hitch = "Hello world again"
        XCTAssertNil(hitch.substring(99, 11))
    }
    
    func testSubstring2() {
        let hitch: Hitch = "Hello world again"
        XCTAssertNil(hitch.substring(99, 120))
    }
    
    func testSubstring3() {
        let hitch: Hitch = "Hello world again"
        XCTAssertNil(hitch.substring(-100, 120))
    }
    
    func testStartsWith1() {
        let hitch: Hitch = "Hello world again"
        XCTAssertTrue(hitch.starts(with: "Hello "))
    }
    
    func testStartsWith2() {
        let hitch: Hitch = "Hello world again"
        XCTAssertFalse(hitch.starts(with: "ello "))
    }
    
    func testStartsWith3() {
        let hitch: Hitch = "Hello world again"
        XCTAssertFalse(hitch.starts(with: "world"))
    }
    
    func testStartsWith4() {
        let hitch: Hitch = "Hello world again"
        XCTAssertTrue(hitch.starts(with: Hitch(string: "Hello world agai")))
    }
    
    func testEndsWith1() {
        let hitch: Hitch = "Hello world again"
        XCTAssertTrue(hitch.ends(with: " again"))
    }
    
    func testEndsWith2() {
        let hitch: Hitch = "Hello world again"
        XCTAssertFalse(hitch.ends(with: "ello "))
    }
    
    func testEndsWith3() {
        let hitch: Hitch = "Hello world again"
        XCTAssertFalse(hitch.ends(with: "world"))
    }
    
    func testEndsWith4() {
        let hitch: Hitch = "Hello world again"
        XCTAssertTrue(hitch.ends(with: Hitch(string: "ello world again")))
    }
    
    func testUnescaping() {
        // A, ö, Ж, €, 𝄞
        let hitch0: Hitch = Hitch(string: #"\\ \' \" \t \n \r"#)
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
    
    func testEscaping() {
        let hitch0 = Hitch("\\ \' \" \t \n \r").escaped(unicode: true,
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
        
        let hitch1: Hitch = "A ö Ж € 𝄞"
        XCTAssertEqual(hitch1.escaped(unicode: true,
                                      singleQuotes: true), #"A \u00F6 \u0416 \u20AC \u{1D11E}"#)
        XCTAssertEqual(hitch1.halfhitch().escaped(unicode: true,
                                                  singleQuotes: true), #"A \u00F6 \u0416 \u20AC \u{1D11E}"#)
    }
    
    func testInsert() {
        let hitch = Hitch()
        let values: [UInt8] = [53, 52, 51, 50, 49]
        
        for value in values {
            hitch.insert(value, index: 0)
        }
        
        XCTAssertEqual(hitch, "12345")
    }
    
    func testInsert2() {
        let hitch = Hitch(stringLiteral: "", copyOnWrite: true)
        let values: [UInt8] = [53, 52, 51, 50, 49]
        
        for value in values {
            hitch.insert(value, index: 99)
        }
        
        XCTAssertEqual(hitch, "54321")
    }
    
    func testInsert3() {
        let hitch = Hitch(string: "store.book")
        XCTAssertEqual(hitch.insert("$.", index: 0), "$.store.book")
        XCTAssertEqual(hitch.insert("$.", index: -99), "$.$.store.book")
        XCTAssertEqual(hitch.insert("$.", index: 99), "$.$.store.book$.")
    }
    
    func testComparable() {
        let hitch1: Hitch = "Apple"
        let hitch2: Hitch = "apple"
        
        XCTAssertEqual(hitch1 < hitch2, "Apple" < "apple")
        
        XCTAssertTrue(Hitch(string: "Hitch1") < Hitch(string: "Hitch2"))
        XCTAssertTrue(Hitch(string: "Hitch2") < Hitch(string: "Hitch3"))
        XCTAssertTrue(Hitch(string: "Hitch3") < Hitch(string: "Hitch4"))
        
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
            XCTAssertEqual(Hitch(string: "hello: ").append(number: value).description, "hello: \(value)")
        }
    }
    
    func testInsertValue() {
        let values = [
            12345,
            0,
            -12345
        ]
        for value in values {
            XCTAssertEqual(Hitch(string: "hello  world").insert(number: value, index: 6).description, "hello \(value) world")
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
            XCTAssertEqual(Hitch(stringLiteral: "hello: ", copyOnWrite: true).append(double: value).description, "hello: \(value)")
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
            XCTAssertEqual(Hitch(string: "hello  world").insert(double: value, index: 6).description, "hello \(value) world")
        }
    }
    
    func testTrim() {        
        XCTAssertEqual(Hitch(string: "Hello   \t\n\r  ").trim(), "Hello")
        XCTAssertEqual(Hitch(string: "   \t\n\r  Hello").trim(), "Hello")
        XCTAssertEqual(Hitch(string: "   \t\n\r  Hello   \t\n\r  ").trim(), "Hello")
        XCTAssertEqual(Hitch(string: "Hello").trim(), "Hello")
    }
    
    func testInitFromHitch() {
        let hitch: Hitch = "Hello world again"
        XCTAssertEqual(hitch, "Hello world again")
    }
    
    func testSplitToInt() {
        let hitch: Hitch = "1,2,3,4,52345,-6,7,8134,9,-72,  5  ,  2  4  "
        var array = [Int]()
            
        let parts = hitch.split(separator: 44)
        for part in parts {
            guard let part = part.toInt() else { continue }
            array.append(part)
        }
        
        let result = array.map { String($0) }.joined(separator: ",")
        XCTAssertEqual(result, "1,2,3,4,52345,-6,7,8134,9,-72,5")
    }
        
    func testToInt() {
        let hitch: Hitch = "  5  "
        XCTAssertEqual(hitch.toInt(), 5)
        
        XCTAssertNil(Hitch("A").toInt())
        XCTAssertNil(Hitch("B").toInt())
    }
    
    func testToIntFuzzy() {
        XCTAssertEqual(Hitch("22").toInt(fuzzy: true), 22)
        XCTAssertEqual(Hitch("39").toInt(fuzzy: true), 39)
        XCTAssertEqual(Hitch("40012").toInt(fuzzy: true), 40012)

        XCTAssertEqual(Hitch("  sdf asdf22asdfasd f").toInt(fuzzy: true), 22)
        XCTAssertEqual(Hitch("gsdg39sdf .sdfsd").toInt(fuzzy: true), 39)
        XCTAssertEqual(Hitch("sdfsdf40012sdfg ").toInt(fuzzy: true), 40012)
    }
    
    func testToDoubleFuzzy() {
        XCTAssertEqual(Hitch("2.2").toDouble(fuzzy: true), 2.2)
        XCTAssertEqual(Hitch("3.9").toDouble(fuzzy: true), 3.9)
        XCTAssertEqual(Hitch("4.0012").toDouble(fuzzy: true), 4.0012)

        XCTAssertEqual(Hitch("  sdf asdf2.2asdfasd f").toDouble(fuzzy: true), 2.2)
        XCTAssertEqual(Hitch("gsdg3.9sdf .sdfsd").toDouble(fuzzy: true), 3.9)
        XCTAssertEqual(Hitch("sdfsdf4.0012sdfg ").toDouble(fuzzy: true), 4.0012)
    }
    
    func testSplitToDouble() {
        //let hitch = "1,2.2,3.9,4.0012,52345.24,-6.0,7.12,8134.99,9.320547,-72.25,  5.6  ,  2.2  4.4  "
        XCTAssertEqual(Hitch("2.2").toDouble(), 2.2)
        XCTAssertEqual(Hitch("3.9").toDouble(), 3.9)
        XCTAssertEqual(Hitch("4.0012").toDouble(), 4.0012)
        XCTAssertEqual(Hitch("52345.24").toDouble(), 52345.24)
        XCTAssertEqual(Hitch("-6.0").toDouble(), -6.0)
        XCTAssertEqual(Hitch("7.12").toDouble(), 7.12)
        XCTAssertEqual(Hitch("8134.99").toDouble(), 8134.99)
        XCTAssertEqual(Hitch("9.320547").toDouble(), 9.320547)
        XCTAssertEqual(Hitch("-72.25").toDouble(), -72.25)
        XCTAssertEqual(Hitch("  5.6  ").toDouble(), 5.6)
        XCTAssertNil(Hitch("  2.2  4.4  ").toDouble())
        
        XCTAssertNil(Hitch("A").toDouble())
        XCTAssertNil(Hitch("B").toDouble())
    }
    
    func testToDouble() {
        let hitch: Hitch = "  5.2567  "
        XCTAssertEqual(hitch.toDouble(), 5.2567)
    }
    
    func testReplaceRange() {
        // replace(occurencesOf hitch: Hitch, with: Hitch, ignoreCase: Bool = false)
        XCTAssertEqual(Hitch(string: "Hello CrUeL world").replace(from: 6, to: 11, with: "happy"), "Hello happy world")
        XCTAssertEqual(Hitch(string: "Hello CrUeL world").replace(from: 6, to: 12, with: Hitch()), "Hello world")
        XCTAssertEqual(Hitch(string: "Hello CrUeL world").replace(from: 6, to: 17, with: "happy"), "Hello happy")
        XCTAssertEqual(Hitch(string: "Hello CrUeL world").replace(from: 0, to: 11, with: "happy"), "happy world")
        XCTAssertEqual(Hitch(string: "Hello CrUeL world").replace(from: 6, to: 99, with: "happy"), "Hello CrUeL world")
        XCTAssertEqual(Hitch(string: "Hello CrUeL world").replace(from: -5, to: 11, with: "happy"), "Hello CrUeL world")
    }
    
    func testReplace1() {
        // replace(occurencesOf hitch: Hitch, with: Hitch, ignoreCase: Bool = false)
        XCTAssertEqual(Hitch(string: "Hello CrUeL world").replace(occurencesOf: "CrUeL", with: "happy"), "Hello happy world")
        XCTAssertEqual(Hitch(string: "Hello CrUeL world").replace(occurencesOf: "cRuEl", with: "happy", ignoreCase: true), "Hello happy world")
        
        XCTAssertEqual(Hitch(string: "Hello CrUeL world").replace(occurencesOf: "CrUeL", with: ""), "Hello  world")
        XCTAssertEqual(Hitch(string: "Hello CrUeL world").replace(occurencesOf: "CrUeL", with: Hitch()), "Hello  world")
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
    
    private func splitTest(_ separator: HalfHitch, _ hitch: Hitch, _ result: [Hitch]) {
        let hhresult = result.map { $0.halfhitch() }
        let stringJoinedResult = result.map { $0.description }.joined(separator: "!")
                
        let parts: [String] = hitch.description.components(separatedBy: separator.description)
        XCTAssertEqual(parts, hhresult.map { $0.toString() })
        XCTAssertEqual(parts.map { $0.description }.joined(separator: "!").description, stringJoinedResult)
        
        let parts1: [HalfHitch] = hitch.components(separatedBy: separator)
        XCTAssertEqual(parts1, hhresult)
        XCTAssertEqual(parts1.map { $0.description }.joined(separator: "!").description, stringJoinedResult)
        
        let parts2: [HalfHitch] = hitch.halfhitch().components(separatedBy: separator)
        XCTAssertEqual(parts2, hhresult)
        XCTAssertEqual(parts2.map { $0.description }.joined(separator: "!").description, stringJoinedResult)
        
        let parts3: [HalfHitch] = hitch.halfhitch().components(separatedBy: separator)
        XCTAssertEqual(parts3, hhresult)
        XCTAssertEqual(parts3.map { $0.description }.joined(separator: "!").description, stringJoinedResult)
    }
    
    func testSplit0() {
        splitTest("\n", "hello world", ["hello world"])
        splitTest(",", "1,2,3,4,5,6,7,8,9,10,11,12,13,14", ["1","2","3","4","5","6","7","8","9","10","11","12","13","14"])
        splitTest(" ", "   hello       world   again   ", ["", "", "", "hello", "", "", "", "", "", "", "world", "", "", "again", "", "", ""])
        splitTest("<->", "   hello<->world<->again   ", ["   hello","world","again   "])
        splitTest(",", "-111.6721066,35.2336899,3111,W SHANNON DR,,,,,86001,,a7d9e14ded9387d9", ["-111.6721066","35.2336899","3111","W SHANNON DR","","","","","86001","","a7d9e14ded9387d9"])
    }
    
    func testExportAsData() {
        let hitch: Hitch = "Hello World"
        let data = hitch.exportAsData()
        
        XCTAssertEqual(String(data: data, encoding: .utf8), "Hello World")
        XCTAssertEqual(hitch.count, 0)
    }
    
    func testHitchAsKeys() {
        
        var info = [HalfHitch: Int]()
        
        let hitch: Hitch = "Hello CrUeL world"
        
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
    
    func testEpochPerf() {
        // DateFormatter: 0.027s
        // Custom: 0.000s
        let hitch = Hitch("4/30/2021 11:59:59 PM")
        
        XCTAssertEqual(hitch.toEpoch(), 1619827199)
        
        measure {
            var numMatches = 0
            for _ in 0..<1000 {
                if hitch.toEpoch() == 1619827199 {
                    numMatches += 1
                }
            }
            XCTAssertEqual(numMatches, 1000)
        }
    }
    
    func testHitchEqualityPerf() {
        let sourceHitches = [
            "George the seventh123",
            "John the third1234567",
            "Henry the twelveth123",
            "Dennis the mennis1234",
            "Calvin and the Hobbes"
        ]
        
        let match = "John the third1234567"
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
        let sourceHitches: [HalfHitch] = [
            "George the seventh123",
            "John the third1234567",
            "Henry the twelveth123",
            "Dennis the mennis1234",
            "Calvin and the Hobbes"
        ]
        
        let match: HalfHitch = "John the third1234567"
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
        let sourceHitches: [HalfHitch] = [
            "George the seventh123",
            "John the third1234567",
            "Henry the twelveth123",
            "Dennis the mennis1234",
            "Calvin and the Hobbes"
        ]
        
        let match: Hitch = "John the third1234567"
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
}

extension HitchTests {
    static var allTests: [(String, (HitchTests) -> () throws -> Void)] {
        return [
            ("testCastAnyToHitch", testCastAnyToHitch),
            ("testSimpleCreate", testSimpleCreate),
            ("testAppendToEmpty", testAppendToEmpty),
            ("testToLower", testToLower),
            ("testToUpper", testToUpper),
            ("testIteration", testIteration),
            ("testIterationRange", testIterationRange),
            ("testDirectAccess", testDirectAccess),
            ("testSubscript", testSubscript),
            ("testContainsSingle", testContainsSingle),
            ("testHashable", testHashable),
            ("testEquality", testEquality),
            ("testEpoch", testEpoch),
            ("testData", testData),
            ("testSubdata", testSubdata),
            ("testExtract", testExtract),
            ("testIndexOf", testIndexOf),
            ("testLastIndexOf", testLastIndexOf),
            ("testLastIndexOf2", testLastIndexOf2),
            ("testIndexOf3", testIndexOf3),
            ("testHalfHitchFromData0", testHalfHitchFromData0),
            ("testHalfHitchEquality", testHalfHitchEquality),
            ("testHalfHitch0", testHalfHitch0),
            ("testHalfHitchAppend0", testHalfHitchAppend0),
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
            ("testEndsWith1", testEndsWith1),
            ("testEndsWith2", testEndsWith2),
            ("testEndsWith3", testEndsWith3),
            ("testEndsWith4", testEndsWith4),
            ("testUnescaping", testUnescaping),
            ("testEscaping", testEscaping),
            ("testInsert", testInsert),
            ("testInsert2", testInsert2),
            ("testInsert3", testInsert3),
            ("testComparable", testComparable),
            ("testAppendValue", testAppendValue),
            ("testInsertValue", testInsertValue),
            ("testAppendDouble", testAppendDouble),
            ("testInsertDouble", testInsertDouble),
            ("testTrim", testTrim),
            ("testInitFromHitch", testInitFromHitch),
            ("testSplitToInt", testSplitToInt),
            ("testToInt", testToInt),
            ("testToIntFuzzy", testToIntFuzzy),
            ("testToDoubleFuzzy", testToDoubleFuzzy),
            ("testSplitToDouble", testSplitToDouble),
            ("testToDouble", testToDouble),
            ("testReplaceRange", testReplaceRange),
            ("testReplace1", testReplace1),
            ("testReplace2", testReplace2),
            ("testSplit0", testSplit0),
            ("testExportAsData", testExportAsData),
            ("testHitchAsKeys", testHitchAsKeys),
            ("testNullHalfHitch", testNullHalfHitch),
            
            ("testEpochPerf", testEpochPerf),
            
            // Performance tests cannot be run without XCode because we cannot test using release configuration
            //("testHitchEqualityPerf", testHitchEqualityPerf),
            //("testHalfHitchEqualityPerf", testHalfHitchEqualityPerf),
            //("testHitchToHalfHitchEqualityPerf", testHitchToHalfHitchEqualityPerf)
        ]
    }
}
