import XCTest
@testable import Hitch

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
        
        
        let chart = Hitch()
        let format: Hitch = "|{             -?              }|{       ~?.2             }|\n"
        
        chart.append("+-------------------------------+--------------------------+\n")
        chart.append(format: format, "HitchPerformanceTests.swift", "Faster than String")
        chart.append("+-------------------------------+--------------------------+\n")
        for (name,timing) in results.sorted(by: { $0.1 > $1.1 } ) {
            chart.append(format: format, name, "\(timing)x")
        }
        chart.append("+-------------------------------+--------------------------+\n")
        
        print("\n\n")
        print(chart)
    }
    
    func testUTF8IterationPerf() {
        let swiftLorem = lorem
        let hitchLorem = lorem.hitch()
        
        XCTAssert(
            test (1000, "utf8 iterator",
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
    
    func testIterationPerf() {
        let swiftLorem = lorem
        let hitchLorem = lorem.hitch()
        
        XCTAssert(
            test (1000, "string iterator",
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
        var swiftLorem = lorem
        let hitchLorem = lorem.hitch()
        
        XCTAssert(
            test (1000, "uppercase/lowercase",
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
    
    func testFormatStringsPerf() {
        // Note: we're unlike to beat String here, as we're stuck with dynamic casting of the arguments
        XCTAssert(
            test (10, "format strings",
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
        )
    }
    
    func testFormatStrings2Perf() {
        let hitch = Hitch()
        for idx in 1...1000000 {
            hitch.append(format: "{?}{?}{?}{?}{?}{?}{?}", idx+0, idx+1, idx+2, idx+3, idx+4, idx+5, idx+6)
            hitch.clear()
        }
    }
    
    func testContainsPerf() {
        let swiftLorem = lorem
        let hitchLorem = lorem.hitch()
        let swiftNeedle = "nulla pariatur"
        let hitchNeedle = swiftNeedle.hitch()
        
        XCTAssertTrue(swiftLorem.contains(swiftNeedle))
        XCTAssertTrue(hitchLorem.contains(hitchNeedle))
        
        XCTAssert(
            test (1000, "contains",
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
    
    func testFirstIndexOfPerf() {
        let swiftLorem = lorem
        let hitchLorem = lorem.hitch()
        let swiftNeedle = "nulla pariatur"
        let hitchNeedle = swiftNeedle.hitch()
                
        XCTAssert(
            test (1000, "first index of",
            {
                for _ in 1...1000 {
                    _ = swiftLorem.range(of: swiftNeedle)
                }
            }, {
                for _ in 1...1000 {
                    hitchLorem.firstIndex(of: hitchNeedle)
                }
            })
        )
    }
    
    func testLastIndexOfPerf() {
        let swiftLorem = lorem
        let hitchLorem = lorem.hitch()
        let swiftNeedle = "nulla pariatur"
        let hitchNeedle = swiftNeedle.hitch()
                
        XCTAssert(
            test (1000, "first index of",
            {
                for _ in 1...1000 {
                    _ = swiftLorem.range(of: swiftNeedle)
                }
            }, {
                for _ in 1...1000 {
                    hitchLorem.lastIndex(of: hitchNeedle)
                }
            })
        )
    }
        
    func testAppendStaticMemoryPerf() {
        let swiftLorem = lorem
        let hitchLorem = lorem.hitch()
        
        var swiftCombined = ""
        let hitchCombined = Hitch()
        
        swiftCombined.reserveCapacity(swiftLorem.count * 1000)
        hitchCombined.reserveCapacity(hitchLorem.count * 1000)
        
        XCTAssert(
            test (1000, "append (w/ capacity)",
            {
                swiftCombined.append(swiftLorem)
            }, {
                hitchCombined.append(hitchLorem)
            })
        )
    }
    
    func testAppendDynamicMemoryPerf() {
        let swiftLorem = lorem
        let hitchLorem = lorem.hitch()
        
        var swiftCombined = ""
        let hitchCombined = Hitch()
                
        XCTAssert(
            test (1000, "append (w/ capacity)",
            {
                swiftCombined.append(swiftLorem)
            }, {
                hitchCombined.append(hitchLorem)
            })
        )
    }
    
    
}
