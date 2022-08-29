import XCTest
import Hitch

final class HitchPerformanceTests: XCTestCase {
    
    private var results = [(String,Double)]()
    
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
        
        results.append((functionName, swiftTime/hitchTime))
        
        return hitchTime < swiftTime
    }
    
    func testCreateChart() {
        results = [(String,Double)]()
        testAppendDynamicMemoryPerf()
        testAppendStaticMemoryPerf()
        testUTF8IterationPerf()
        testIterationPerf()
        testToUpperAndToLowerPerf()
        testContainsPerf()
        testFirstIndexOfPerf()
        testLastIndexOfPerf()
        testReplacePerf()
        
        
        let chart = Hitch()
        let format: StaticString = "|{             -?              }|{       ~?.2             }|\n"
        
        chart.append("+-------------------------------+--------------------------+\n")
        chart.append(format << ["HitchPerformanceTests.swift", "Faster than String"])
        chart.append("+-------------------------------+--------------------------+\n")
        for (name,timing) in results.sorted(by: { $0.1 > $1.1 } ) {
            chart.append(format << [name, "\(timing)x"])
        }
        chart.append("+-------------------------------+--------------------------+\n")
        
        print("\n\n")
        print(chart)
    }
    
    func testUTF8IterationPerf() {
        XCTAssert(
            test (100000, "utf8 iterator",
            {
                var i = 0
                for x in swiftLorem.utf8 {
                    i += Int(x)
                }
            }, {
                var i = 0
                for x in hitchLorem {
                    i += Int(x)
                }
            })
        )
    }
    
    func testHashingPerf() {
        // Note: we're currently slower on hashing performance because Hitch is required to
        // be a subclass of NSObject to avoid a runtime fatal error on Linux.
        XCTAssert(
            test (1000, "utf8 iterator",
            {
                let key = "12345678910"
                for _ in 0..<100000 {
                    _ = key.hashValue
                }
            }, {
                let key: Hitch = "12345678910"
                for _ in 0..<100000 {
                    _ = key.hashValue
                }
            })
        )
    }
    
    func testIterationPerf() {
        XCTAssert(
            test (1000000, "string iterator",
            {
                var i = 0
                for x in swiftLorem {
                    i += Int(x.asciiValue ?? 0)
                }
            }, {
                var i = 0
                for x in hitchLorem {
                    i += Int(x)
                }
            })
        )
    }
    
    func testToUpperAndToLowerPerf() {
        var mutableSwiftLorem = swiftLorem
        let hitchLorem = Hitch(string: swiftLorem)
        XCTAssert(
            test (1000, "uppercase/lowercase",
            {
                for x in 1...1000 {
                    if x % 2 == 0 {
                        mutableSwiftLorem = mutableSwiftLorem.lowercased()
                    } else {
                        mutableSwiftLorem = mutableSwiftLorem.uppercased()
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
    
    func testFormatStringsPerf() {
        // Note: we're unlikely to beat String here, as we're stuck with dynamic casting of the arguments
        //XCTAssert(
            _ = test (10, "format strings",
            {
                var total = 0
                for idx in 1...100000 {
                    let value = "\(idx+0)\(idx+1)\(idx+2)\(idx+3)\(idx+4)\(idx+5)\(idx+6)"
                    total += value.count
                }
            }, {
                var total = 0
                let hitch = Hitch()
                for idx in 1...100000 {
                    hitch.append(format: "{?}{?}{?}{?}{?}{?}{?}", idx+0, idx+1, idx+2, idx+3, idx+4, idx+5, idx+6)
                    hitch.clear()
                    total += hitch.count
                }
            })
        //)
    }
    
    func testFormatStrings2Perf() {
        let hitch = Hitch()
        for idx in 1...1000000 {
            hitch.append(format: "{?}{?}{?}{?}{?}{?}{?}", idx+0, idx+1, idx+2, idx+3, idx+4, idx+5, idx+6)
            hitch.clear()
        }
    }
    
    func testStaticStringVsNonStaticString() {
        XCTAssert(
            test (10, "string literals",
            {
                for _ in 1...100000 {
                    let _ = Hitch(string: "Hello World!")
                }
            }, {
                for _ in 1...100000 {
                    let _ = Hitch(stringLiteral: "Hello World!")
                }
            })
        )
    }
    
    func testContainsPerf() {
        // OLD: 0.020
        // 0.018
        // 0.010
        XCTAssertTrue(swiftLorem.contains("ea commodo consequat"))
        XCTAssertTrue(hitchLorem.contains("ea commodo consequat"))
        
        let halfHitch: HalfHitch = "ea commodo consequat"
        measure {
            for _ in 1...100000 {
                hitchLorem.contains(halfHitch)
            }
        }
        
        XCTAssert(
            test (1000, "contains",
            {
                for _ in 1...1000 {
                    _ = swiftLorem.contains("ea commodo consequat")
                }
            }, {
                for _ in 1...1000 {
                    hitchLorem.contains("ea commodo consequat")
                }
            })
        )
    }
    
    func testFirstIndexOfPerf() {
        XCTAssert(
            test (1000, "first index of",
            {
                for _ in 1...1000 {
                    _ = swiftLorem.range(of: "nulla pariatur")
                }
            }, {
                for _ in 1...1000 {
                    hitchLorem.firstIndex(of: "nulla pariatur")
                }
            })
        )
    }
    
    func testLastIndexOfPerf() {
        XCTAssert(
            test (1000, "last index of",
            {
                for _ in 1...1000 {
                    _ = swiftLorem.range(of: "nulla pariatur")
                }
            }, {
                for _ in 1...1000 {
                    hitchLorem.lastIndex(of: "nulla pariatur")
                }
            })
        )
    }
    
    func testReplacePerf() {
        let hitchLoremCopy = Hitch(hitch: hitchLorem)
        XCTAssert(
            test (1000, "replace occurrences of",
            {
                for _ in 1...1000 {
                    var replace0 = swiftLorem.replacingOccurrences(of: "nulla pariatur", with: "hello world, goodbye world")
                    replace0 = replace0.replacingOccurrences(of: "hello world, goodbye world", with: "nulla pariatur")
                }
            }, {
                for _ in 1...1000 {
                    hitchLoremCopy.replace(occurencesOf: "nulla pariatur", with: "hello world, goodbye world")
                    hitchLoremCopy.replace(occurencesOf: "hello world, goodbye world", with: "nulla pariatur")
                }
            })
        )
    }
        
    func testAppendStaticMemoryPerf() {
        var swiftCombined = ""
        let hitchCombined = Hitch()
        
        swiftCombined.reserveCapacity(swiftLorem.count * 100000)
        hitchCombined.reserveCapacity(hitchLorem.count * 100000)

        XCTAssert(
            test (100000, "append (static capacity)",
            {
                swiftCombined.append(swiftLorem)
            }, {
                hitchCombined.append(hitchLorem)
            })
        )
    }
    
    func testAppendDynamicMemoryPerf() {
        var swiftCombined = ""
        let hitchCombined = Hitch()
                
        XCTAssert(
            test (1000, "append (dynamic capacity)",
            {
                swiftCombined.append(swiftLorem)
            }, {
                hitchCombined.append(hitchLorem)
            })
        )
    }
}

extension HitchPerformanceTests {
    static var allTests: [(String, (HitchPerformanceTests) -> () throws -> Void)] {
        return [
            // Performance tests cannot be run without XCode because we cannot test using release configuration
            //("testCreateChart", testCreateChart),
            //("testUTF8IterationPerf", testUTF8IterationPerf),
            //("testHashingPerf", testHashingPerf),
            //("testIterationPerf", testIterationPerf),
            //("testToUpperAndToLowerPerf", testToUpperAndToLowerPerf),
            //("testFormatStringsPerf", testFormatStringsPerf),
            //("testFormatStrings2Perf", testFormatStrings2Perf),
            //("testStaticStringVsNonStaticString", testStaticStringVsNonStaticString),
            //("testContainsPerf", testContainsPerf),
            //("testFirstIndexOfPerf", testFirstIndexOfPerf),
            //("testLastIndexOfPerf", testLastIndexOfPerf),
            //("testReplacePerf", testReplacePerf),
            //("testAppendStaticMemoryPerf", testAppendStaticMemoryPerf),
            //("testAppendDynamicMemoryPerf", testAppendDynamicMemoryPerf)
        ]
    }
}
