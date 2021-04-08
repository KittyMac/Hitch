import XCTest
@testable import Hitch

final class HitchTests: XCTestCase {
    
    let lorem = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
    
    private func test(_ functionName: String,
                      _ swiftString: () -> (),
                      _ hitchString: () -> ()) -> Bool {
        let swiftStart = Date()
        swiftString()
        let swiftTime = abs(swiftStart.timeIntervalSinceNow)
        
        let hitchStart = Date()
        hitchString()
        let hitchTime = abs(hitchStart.timeIntervalSinceNow)
        
        if hitchTime < swiftTime {
            print("\(functionName) is \(swiftTime/hitchTime)x faster" )
        } else {
            print("\(functionName) is \(hitchTime/swiftTime)x slower" )
        }
        
        return hitchTime < swiftTime
    }
        
    func testToUpperAndToLower() {
        var switchLorem = lorem
        let hitchLorem = lorem.hitch
        
        XCTAssert(
            test (#function,
            {
                for x in 1...1000 {
                    if x % 2 == 0 {
                        switchLorem = switchLorem.lowercased()
                    } else {
                        switchLorem = switchLorem.uppercased()
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
    
    func testAppend() {
        var switchLorem = lorem
        let hitchLorem = lorem.hitch
        
        XCTAssert(
            test (#function,
            {
                switchLorem.reserveCapacity(1024 * 1024 * 4)
                for _ in 1...10 {
                    switchLorem.append(switchLorem)
                }
            }, {
                hitchLorem.reserveCapacity(1024 * 1024 * 4)
                for _ in 1...10 {
                    hitchLorem.append(hitchLorem)
                }
            })
        )
    }

    static var allTests = [
        ("testToUpperAndToLower", testToUpperAndToLower),
    ]
}
