import XCTest
@testable import Hitch

final class HitchTests: XCTestCase {
    
    // Basic tests to confirm the functionality of bstring
    
    func testSimpleCreate() {
        let hello = "Hello"
        XCTAssertEqual(hello.hitch().description, hello)
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
    
    func testIterationPerf() {
        let swiftLorem = lorem
        let hitchLorem = lorem.hitch()
        
        XCTAssert(
            test (1000, #function,
            {
                var i = 0
                for x in swiftLorem.utf8 {
                    i += Int(x)
                }
                //XCTAssertEqual(i, 42248)
            }, {
                var i = 0
                for x in hitchLorem {
                    i += Int(x)
                }
                //XCTAssertEqual(i, 42248)
            })
        )
    }
    
    
    // Performance comparison tests to confirm bstring is faster than Swift strings
    
    let lorem = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
    
    private func test(_ iterations: Int,
                      _ functionName: String,
                      _ swiftString: () -> (),
                      _ hitchString: () -> ()) -> Bool {
        
        let swiftStart = Date()
        for _ in 0..<iterations {
            swiftString()
        }
        let swiftTime = abs(swiftStart.timeIntervalSinceNow / Double(iterations))
        
        let hitchStart = Date()
        for _ in 0..<iterations {
            hitchString()
        }
        let hitchTime = abs(hitchStart.timeIntervalSinceNow / Double(iterations))
        
        if hitchTime < swiftTime {
            print("\(functionName) is \(swiftTime/hitchTime)x faster in Hitch" )
        } else {
            print("\(functionName) is \(hitchTime/swiftTime)x slower in Hitch" )
        }
        
        return hitchTime < swiftTime
    }
    
    func testDirectAccess() {
        lorem.hitch().withBytes { (bytes) in
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
        
        XCTAssertEqual(Hitch("ipsum"), hitchLorem2)
        
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
        
        XCTAssertEqual(test1.extract(#""value1""#, ",")?.toInt() ?? 0, 27)
        XCTAssertEqual(test1.extract(#""value2""#, ",")?.toInt() ?? 0, 27)
        XCTAssertEqual(test1.extract(#"value3"#, ",")?.toInt() ?? 0, 27)
        XCTAssertEqual(test1.extract(#""value4": ""#, "\""), "6.0")
    }
    
    func testToUpperAndToLowerPerf() {
        var swiftLorem = lorem
        let hitchLorem = lorem.hitch()
        
        XCTAssert(
            test (1000, #function,
            {
                for x in 1...1000 {
                    if x % 2 == 0 {
                        swiftLorem = swiftLorem.lowercased()
                    } else {
                        swiftLorem = swiftLorem.uppercased()
                    }
                }
            }, {
                for x in 1...1000 {
                    if x % 2 == 0 {
                        hitchLorem.lowercase()
                    } else {
                        hitchLorem.uppercase()
                    }
                }
            })
        )
    }
    
    func testIndexOf() {
        let hitchLorem = lorem.hitch()
        let hitchNeedle = Hitch("nulla pariatur")
        
        XCTAssertEqual(hitchLorem.firstIndex(of: hitchNeedle), 319)
    }
    
    func testLastIndexOf() {
        let hitchLorem = "/true|false/".hitch()
        let hitchNeedle = Hitch("/")
        
        XCTAssertEqual(hitchLorem.lastIndex(of: hitchNeedle), 11)
    }
    
    func testContainsPerf() {
        let swiftLorem = lorem
        let hitchLorem = lorem.hitch()
        let swiftNeedle = "nulla pariatur"
        let hitchNeedle = swiftNeedle.hitch()
        
        XCTAssertTrue(swiftLorem.contains(swiftNeedle))
        XCTAssertTrue(hitchLorem.contains(hitchNeedle))
        
        XCTAssert(
            test (1000, #function,
            {
                for _ in 1...1000 {
                    _ = swiftLorem.contains(swiftNeedle)
                }
            }, {
                for _ in 1...1000 {
                    hitchLorem.contains(hitchNeedle)
                }
            })
        )
    }
    
    func testAppendStaticMemoryPerf() {
        var swiftLorem = lorem
        let hitchLorem = Hitch(capacity: 455682)
        
        swiftLorem.reserveCapacity(455682)
        
        XCTAssert(
            test (12, #function,
            {
                swiftLorem.append(swiftLorem)
            }, {
                hitchLorem.append(hitchLorem)
            })
        )
    }
    
    func testAppendDynamicMemoryPerf() {
        var swiftLorem = lorem
        let hitchLorem = lorem.hitch()
        XCTAssert(
            test (12, #function,
            {
                swiftLorem.append(swiftLorem)
            }, {
                hitchLorem.append(hitchLorem)
            })
        )
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
        XCTAssertTrue(hitch.starts(with: Hitch("Hello world agai")))
    }
    
    func testUnescaping() {
        // A, ö, Ж, €, 𝄞
        let hitch0 = #"\\ \' \" \t \f \n \r \b"#.hitch()
        hitch0.unescape()
        XCTAssertEqual(hitch0[0], .backSlash)
        XCTAssertEqual(hitch0[1], .space)
        XCTAssertEqual(hitch0[2], .singleQuote)
        XCTAssertEqual(hitch0[3], .space)
        XCTAssertEqual(hitch0[4], .doubleQuote)
        XCTAssertEqual(hitch0[5], .space)
        XCTAssertEqual(hitch0[6], .tab)
        XCTAssertEqual(hitch0[7], .space)
        XCTAssertEqual(hitch0[8], .formFeed)
        XCTAssertEqual(hitch0[9], .space)
        XCTAssertEqual(hitch0[10], .newLine)
        XCTAssertEqual(hitch0[11], .space)
        XCTAssertEqual(hitch0[12], .carriageReturn)
        XCTAssertEqual(hitch0[13], .space)
        XCTAssertEqual(hitch0[14], .bell)
        XCTAssertEqual(hitch0[15], 0)
        
        let hitch1 = #"\u0041 \u00F6 \u0416 \u20AC \u{1D11E}"#.hitch()
        hitch1.unescape()
        XCTAssertEqual(hitch1, "A ö Ж € 𝄞")
    }
    
    func testEscaping() {
        let hitch0 = "\\ \' \" \t \n \r".hitch()
        hitch0.escape(escapeSingleQuote: true)
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
        hitch1.escape()
        XCTAssertEqual(hitch1, #"A \u00F6 \u0416 \u20AC \u{1D11E}"#)
    }
    
    func testInsert() {
        let hitch = "".hitch()
        let values = [53, 52, 51, 50, 49]
        
        for value in values {
            hitch.insert(value, index: 0)
        }
        
        XCTAssertEqual(hitch, "12345")
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
    
    func testTrim() {
        let hitch = "   \t\n\r  Hello   \t\n\r  ".hitch()
        hitch.trim()
        XCTAssertEqual(hitch, "Hello")
    }
    
    func testInitFromHitch() {
        let hitch = "Hello world again".hitch()
        XCTAssertEqual(Hitch(hitch: hitch), "Hello world again")
    }
    
    func testSplitToInt() {
        let hitch = "1,2,3,4,52345,-6,7,8134,9,-72".hitch()
        var array = [Int]()
            
        let parts = hitch.split(separator: 44)
        for part in parts {
            guard let part = part.toInt() else { continue }
            array.append(part)
        }
        
        let result = array.map { String($0) }.joined(separator: ",").hitch()
        XCTAssertEqual(result, hitch)
    }

    static var allTests = [
        ("testSimpleCreate", testSimpleCreate),
    ]
}
