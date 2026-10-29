import Foundation

// Foundation-only building blocks shared by the game model. Nothing in the model layer
// imports SwiftUI, so the rules can be tested on their own (see SelfTests.swift).

/// A color stored as plain numbers so catalog data doesn't depend on SwiftUI.
struct RGB: Hashable {
    let r: Double
    let g: Double
    let b: Double

    init(_ hex: UInt32) {
        r = Double((hex >> 16) & 0xFF) / 255
        g = Double((hex >> 8) & 0xFF) / 255
        b = Double(hex & 0xFF) / 255
    }
}

/// A stable pseudo-random number in `0..<1`, so stars and weather stay put between frames.
func hash01(_ index: Int, _ salt: Double) -> Double {
    let value = sin(Double(index) * 12.9898 + salt * 78.233) * 43758.5453
    return value - floor(value)
}

/// A small seedable random generator, so tests are repeatable.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

/// Which calendar day a date falls on, in the player's time zone. Used for once-a-day actions.
/// Missing days never matters: nothing decays.
enum GameDay {
    static func index(_ date: Date, timeZone: TimeZone = .current) -> Int {
        let local = date.timeIntervalSince1970 + Double(timeZone.secondsFromGMT(for: date))
        return Int(floor(local / 86_400))
    }
}

enum TimeOfDay: String, CaseIterable {
    case dawn
    case day
    case dusk
    case night

    static func at(_ date: Date, calendar: Calendar = .current) -> TimeOfDay {
        at(hour: calendar.component(.hour, from: date))
    }

    static func at(hour: Int) -> TimeOfDay {
        switch hour {
        case 5..<8: return .dawn
        case 8..<17: return .day
        case 17..<20: return .dusk
        default: return .night
        }
    }

    var name: String {
        switch self {
        case .dawn: return "Dawn"
        case .day: return "Daytime"
        case .dusk: return "Dusk"
        case .night: return "Night"
        }
    }

    var emoji: String {
        switch self {
        case .dawn: return "🌅"
        case .day: return "☀️"
        case .dusk: return "🌇"
        case .night: return "🌙"
        }
    }
}

/// Seasons rotate every real week, so seasonal bunnies and festivals always come back
/// within a month. Nothing is ever gone for good.
enum Season: String, CaseIterable {
    case spring
    case summer
    case autumn
    case winter

    static let length: TimeInterval = 7 * 86_400

    private static func week(_ date: Date) -> Int {
        Int(floor(date.timeIntervalSince1970 / length))
    }

    static func at(_ date: Date) -> Season {
        let index = ((week(date) % 4) + 4) % 4
        return allCases[index]
    }

    /// Identifies one particular run of a season, so festival rewards can be earned once per run.
    static func cycleID(_ date: Date) -> String {
        "\(at(date).rawValue)-\(week(date))"
    }

    /// Seconds until the next season starts.
    static func timeRemaining(_ date: Date) -> TimeInterval {
        let next = Double(week(date) + 1) * length
        return next - date.timeIntervalSince1970
    }

    var name: String {
        switch self {
        case .spring: return "Spring"
        case .summer: return "Summer"
        case .autumn: return "Autumn"
        case .winter: return "Winter"
        }
    }

    var emoji: String {
        switch self {
        case .spring: return "🌸"
        case .summer: return "🌻"
        case .autumn: return "🍂"
        case .winter: return "❄️"
        }
    }
}

/// Weather changes every few minutes. Rain makes crops grow faster.
enum Weather: String, CaseIterable {
    case sunny
    case cloudy
    case rainy
    case breezy

    static let period: TimeInterval = 240

    static func at(_ date: Date) -> Weather {
        let block = Int(date.timeIntervalSince1970 / period)
        let roll = hash01(block, 7)
        if roll < 0.45 { return .sunny }
        if roll < 0.65 { return .cloudy }
        if roll < 0.85 { return .rainy }
        return .breezy
    }

    var emoji: String {
        switch self {
        case .sunny: return "☀️"
        case .cloudy: return "☁️"
        case .rainy: return "🌧️"
        case .breezy: return "🌸"
        }
    }

    var name: String {
        switch self {
        case .sunny: return "Sunny"
        case .cloudy: return "Cloudy"
        case .rainy: return "Rainy"
        case .breezy: return "Petal Breeze"
        }
    }

    var growthBonus: Double {
        self == .rainy ? 1.25 : 1
    }
}

extension Double {
    /// A short, friendly number: `7.5`, `320`, `12.4K`, `3.1M`.
    var cozy: String {
        if self < 10 {
            let rounded = (self * 10).rounded() / 10
            return rounded == rounded.rounded() ? String(Int(rounded)) : String(rounded)
        }
        if self < 1000 {
            return String(Int(self))
        }
        let units = ["K", "M", "B", "T"]
        var value = self
        var index = -1
        while value >= 1000, index < units.count - 1 {
            value /= 1000
            index += 1
        }
        let text = value < 100 ? String(format: "%.1f", value) : String(Int(value))
        return text + units[index]
    }
}

extension Int {
    var cozy: String { Double(self).cozy }
}

extension TimeInterval {
    /// `45s`, `2m 05s`, `1h 03m`.
    var countdown: String {
        let total = max(Int(rounded(.up)), 0)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return "\(hours)h " + String(format: "%02d", minutes) + "m"
        }
        if minutes > 0 {
            return "\(minutes)m " + String(format: "%02d", seconds) + "s"
        }
        return "\(seconds)s"
    }
}
