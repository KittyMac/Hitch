import XCTest

@testable import HitchTests

XCTMain([
    testCase(HalfHitchTests.allTests),
    testCase(HitchFormatTests.allTests),
    testCase(HitchTests.allTests),
    testCase(HitchPerformanceTests.allTests)
])
