import XCTest
import Hitch

final class HitchISO8601Tests: XCTestCase {
    
    private func check(_ date: Date, file: StaticString = #filePath, line: UInt = #line) {
        let plain = ISO8601DateFormatter()
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        XCTAssertEqual(Hitch().append(iso8601: date).toString(),
                       plain.string(from: date), "\(date.timeIntervalSince1970)", file: file, line: line)
        XCTAssertEqual(Hitch().append(iso8601: date, fractionalSeconds: true).toString(),
                       fractional.string(from: date), "\(date.timeIntervalSince1970)", file: file, line: line)
    }
    
    func testKnownValues() {
        XCTAssertEqual(Hitch().append(iso8601: Date(timeIntervalSince1970: 0)).toString(),
                       "1970-01-01T00:00:00Z")
        XCTAssertEqual(Hitch().append(iso8601: Date(timeIntervalSince1970: 1792658740.123)).toString(),
                       "2026-10-22T08:45:40Z")
        XCTAssertEqual(Hitch().append(iso8601: Date(timeIntervalSince1970: 1792658740.123), fractionalSeconds: true).toString(),
                       "2026-10-22T08:45:40.123Z")
        // rounds to the nearest millisecond before dropping the fraction, like the formatter
        XCTAssertEqual(Hitch().append(iso8601: Date(timeIntervalSince1970: 59.9996)).toString(),
                       "1970-01-01T00:01:00Z")
    }
    
    func testMatchesFormatterRandom() {
        // 1900 through 2200, including fractional seconds
        for _ in 0..<50_000 {
            check(Date(timeIntervalSince1970: Double.random(in: -2208988800 ..< 7258118400)))
        }
    }
    
    func testMatchesFormatterBoundaries() {
        // leap days, century rules, day boundaries, negative epoch fractions
        let values: [Double] = [
            -0.0004, -0.0005, -0.001, -1, -86400, -86400.5,
            951782400, 951868800, 951868799.9995,      // 2000-02-29, 2000-03-01
            4107542400, 4107456000,                    // 2100-03-01, 2100-02-28
            1709164800, 1709251199.999,                // 2024-02-29
            -2208988800, 253402300799, 253402300799.9994, // 1900-01-01, 9999-12-31T23:59:59
            -2123618866.7415, -772869572.4235          // negative half-millisecond rounding
        ]
        for value in values {
            check(Date(timeIntervalSince1970: value))
        }
    }
    
    func testOutOfRangeFallsBack() {
        check(Date(timeIntervalSince1970: 253402300800))   // year 10000
        check(Date.distantFuture)
    }
    
    func testAppendsToExistingContent() {
        let hitch = Hitch(string: "id,")
        hitch.append(iso8601: Date(timeIntervalSince1970: 0))
        hitch.append(UInt8(ascii: ","))
        hitch.append(iso8601: Date(timeIntervalSince1970: 86400), fractionalSeconds: true)
        XCTAssertEqual(hitch.toString(), "id,1970-01-01T00:00:00Z,1970-01-02T00:00:00.000Z")
        
        // many appends force the buffer to grow
        let big = Hitch()
        for i in 0..<10_000 {
            big.append(iso8601: Date(timeIntervalSince1970: Double(i)))
        }
        XCTAssertEqual(big.count, 200_000)
        XCTAssertTrue(big.toString().hasSuffix("1970-01-01T02:46:39Z"))
    }
    
    func testPerformance() {
        let date = Date(timeIntervalSince1970: 1792658740)
        let start = Date()
        let hitch = Hitch(capacity: 20)
        for _ in 0..<1_000_000 {
            hitch.count = 0
            hitch.append(iso8601: date)
        }
        let perCall = Date().timeIntervalSince(start)
        print("append(iso8601:) \(perCall)µs per call")
        XCTAssertLessThan(perCall, 5.0)
    }
    
    static var allTests: [(String, (HitchISO8601Tests) -> () throws -> Void)] {
        return [
            ("testKnownValues", testKnownValues),
            ("testMatchesFormatterRandom", testMatchesFormatterRandom),
            ("testMatchesFormatterBoundaries", testMatchesFormatterBoundaries),
            ("testOutOfRangeFallsBack", testOutOfRangeFallsBack),
            ("testAppendsToExistingContent", testAppendsToExistingContent),
            ("testPerformance", testPerformance),
        ]
    }
}
