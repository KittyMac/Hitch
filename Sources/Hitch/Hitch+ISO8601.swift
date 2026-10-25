import Foundation

@inline(__always)
private func writeDigits(_ out: UnsafeMutablePointer<UInt8>, _ value: Int, _ count: Int) {
    var value = value
    var idx = count - 1
    while idx >= 0 {
        out[idx] = UInt8(48 + value % 10)
        value /= 10
        idx -= 1
    }
}

extension Hitch {
    
    @discardableResult
    public func append(iso8601 date: Date, fractionalSeconds: Bool = false) -> Self {
        // ISO8601DateFormatter rounds to whole milliseconds before formatting, with
        // halves rounding up (towards the future, also for dates before 1970)
        let totalMilliseconds = (date.timeIntervalSince1970 * 1000 + 0.5).rounded(.down)
        guard totalMilliseconds.isFinite,
              abs(totalMilliseconds) < 1e15 else {
            return appendISO8601Fallback(date, fractionalSeconds)
        }
        let ms = Int(totalMilliseconds)
        let seconds = ms >= 0 ? ms / 1000 : (ms - 999) / 1000
        let milliseconds = ms - seconds * 1000
        let days = seconds >= 0 ? seconds / 86400 : (seconds - 86399) / 86400
        let secondOfDay = seconds - days * 86400
        
        // civil_from_days (Howard Hinnant)
        let z = days + 719468
        let era = (z >= 0 ? z : z - 146096) / 146097
        let doe = z - era * 146097
        let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365
        let doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
        let mp = (5 * doy + 2) / 153
        let day = doy - (153 * mp + 2) / 5 + 1
        let month = mp < 10 ? mp + 3 : mp - 9
        let year = yoe + era * 400 + (month <= 2 ? 1 : 0)
        
        guard year >= 0 && year <= 9999 else {
            return appendISO8601Fallback(date, fractionalSeconds)
        }
        
        let length = fractionalSeconds ? 24 : 20
        
        lastHash = 0
        chitch_make_mutable(&chitch)
        chitch_sanity(&chitch, chitch.count + length)
        guard let data = chitch.mutableData else { return self }
        
        let out = data + chitch.count
        writeDigits(out, year, 4)
        out[4] = UInt8(ascii: "-")
        writeDigits(out + 5, month, 2)
        out[7] = UInt8(ascii: "-")
        writeDigits(out + 8, day, 2)
        out[10] = UInt8(ascii: "T")
        writeDigits(out + 11, secondOfDay / 3600, 2)
        out[13] = UInt8(ascii: ":")
        writeDigits(out + 14, (secondOfDay / 60) % 60, 2)
        out[16] = UInt8(ascii: ":")
        writeDigits(out + 17, secondOfDay % 60, 2)
        if fractionalSeconds {
            out[19] = UInt8(ascii: ".")
            writeDigits(out + 20, milliseconds, 3)
            out[23] = UInt8(ascii: "Z")
        } else {
            out[19] = UInt8(ascii: "Z")
        }
        
        chitch.count += length
        nullify(&chitch)
        return self
    }
    
    private func appendISO8601Fallback(_ date: Date, _ fractionalSeconds: Bool) -> Self {
        let formatter = ISO8601DateFormatter()
        if fractionalSeconds {
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        }
        return append(formatter.string(from: date))
    }
}
