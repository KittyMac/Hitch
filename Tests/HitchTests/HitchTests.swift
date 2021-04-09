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
            print("\(functionName) is \(swiftTime/hitchTime)x faster" )
        } else {
            print("\(functionName) is \(hitchTime/swiftTime)x slower" )
        }
        
        return hitchTime < swiftTime
    }
    
    
    func testToUpperAndToLower() {
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
    
    func testAppendStaticMemory() {
        var swiftLorem = lorem
        let hitchLorem = lorem.hitch()
        
        swiftLorem.reserveCapacity(455682)
        hitchLorem.reserveCapacity(455682)
        
        XCTAssert(
            test (12, #function,
            {
                swiftLorem.append(swiftLorem)
            }, {
                hitchLorem.append(hitchLorem)
            })
        )
    }
    
    func testAppendDynamicMemory() {
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
    
    /*
    func testIteration() {
        let swiftLorem = lorem
        let hitchLorem = lorem.hitch
        
        XCTAssert(
            test (1000, #function,
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
        
    
    
    
    
    */

    static var allTests = [
        ("testSimpleCreate", testSimpleCreate),
    ]
}
