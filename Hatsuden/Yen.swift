import Foundation

/// Whole yen, stored exactly even after hundreds of income increases.
struct Yen: Comparable, Codable, ExpressibleByIntegerLiteral, Sendable {
    private static let base: UInt64 = 1_000_000_000
    private static let digitsPerWord = 9
    private var words: [UInt32]

    init(_ value: UInt64) {
        var remaining = value
        var words: [UInt32] = []
        while remaining > 0 {
            words.append(UInt32(remaining % Self.base))
            remaining /= Self.base
        }
        self.words = words
    }

    init(integerLiteral value: UInt64) {
        self.init(value)
    }

    init?(_ digits: String) {
        let bytes = Array(digits.utf8)
        guard !bytes.isEmpty, bytes.allSatisfy({ (48...57).contains($0) }) else { return nil }
        var words: [UInt32] = []
        var end = bytes.count
        while end > 0 {
            let start = max(0, end - Self.digitsPerWord)
            var word: UInt32 = 0
            for digit in bytes[start..<end] {
                word = word * 10 + UInt32(digit - 48)
            }
            words.append(word)
            end = start
        }
        self.init(words: words)
    }

    private init(words: [UInt32]) {
        self.words = words
        while self.words.last == 0 { self.words.removeLast() }
    }

    var digits: String {
        guard let largest = words.last else { return "0" }
        var text = String(largest)
        for word in words.dropLast().reversed() {
            let digits = String(word)
            text += String(repeating: "0", count: Self.digitsPerWord - digits.count) + digits
        }
        return text
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.words.count != rhs.words.count { return lhs.words.count < rhs.words.count }
        for (a, b) in zip(lhs.words.reversed(), rhs.words.reversed()) where a != b {
            return a < b
        }
        return false
    }

    static func + (lhs: Self, rhs: Self) -> Self {
        let count = max(lhs.words.count, rhs.words.count)
        var sum: [UInt32] = []
        sum.reserveCapacity(count + 1)
        var carry: UInt64 = 0
        for index in 0..<count {
            let total = lhs.word(at: index) + rhs.word(at: index) + carry
            sum.append(UInt32(total % Self.base))
            carry = total / Self.base
        }
        if carry != 0 { sum.append(UInt32(carry)) }
        return Self(words: sum)
    }

    static func += (lhs: inout Self, rhs: Self) {
        lhs = lhs + rhs
    }

    static func - (lhs: Self, rhs: Self) -> Self {
        precondition(lhs >= rhs, "A yen amount cannot be negative")
        var difference: [UInt32] = []
        difference.reserveCapacity(lhs.words.count)
        var borrow: UInt64 = 0
        for index in lhs.words.indices {
            let amount = lhs.word(at: index)
            let deduction = rhs.word(at: index) + borrow
            if amount < deduction {
                difference.append(UInt32(amount + Self.base - deduction))
                borrow = 1
            } else {
                difference.append(UInt32(amount - deduction))
                borrow = 0
            }
        }
        return Self(words: difference)
    }

    static func -= (lhs: inout Self, rhs: Self) {
        lhs = lhs - rhs
    }

    static func * (amount: Self, multiplier: UInt64) -> Self {
        guard multiplier > 0, !amount.words.isEmpty else { return 0 }
        var product: [UInt32] = []
        product.reserveCapacity(amount.words.count + 3)
        var carry: UInt64 = 0
        for word in amount.words {
            let highAndLow = UInt64(word).multipliedFullWidth(by: multiplier)
            let addition = highAndLow.low.addingReportingOverflow(carry)
            let high = highAndLow.high + (addition.overflow ? 1 : 0)
            let result = Self.base.dividingFullWidth((high: high, low: addition.partialValue))
            product.append(UInt32(result.remainder))
            carry = result.quotient
        }
        while carry > 0 {
            product.append(UInt32(carry % Self.base))
            carry /= Self.base
        }
        return Self(words: product)
    }

    func divided(by divisor: UInt32) -> (whole: Self, remainder: UInt32) {
        precondition(divisor > 0)
        var quotient = words
        var remainder: UInt64 = 0
        for index in words.indices.reversed() {
            let dividend = remainder * Self.base + UInt64(words[index])
            quotient[index] = UInt32(dividend / UInt64(divisor))
            remainder = dividend % UInt64(divisor)
        }
        return (Self(words: quotient), UInt32(remainder))
    }

    private func word(at index: Int) -> UInt64 {
        words.indices.contains(index) ? UInt64(words[index]) : 0
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let text = try container.decode(String.self)
        guard let amount = Self(text) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid yen amount")
        }
        self = amount
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(digits)
    }
}

enum Currency {
    private static let siPrefixes = ["k", "M", "G", "T", "P", "E", "Z", "Y", "R", "Q"]

    static func wallet(_ amount: Yen) -> String {
        amount < 1_000_000 ? full(amount) : compact(amount)
    }

    static func full(_ amount: Yen) -> String {
        let digits = amount.digits.utf8
        var grouped: [UInt8] = []
        grouped.reserveCapacity(digits.count + digits.count / 3)
        for (offset, digit) in digits.enumerated() {
            if offset > 0, (digits.count - offset).isMultiple(of: 3) { grouped.append(44) }
            grouped.append(digit)
        }
        return String(decoding: grouped, as: UTF8.self)
    }

    static func compact(_ amount: Yen) -> String {
        let digits = Array(amount.digits)
        let exponent = digits.count - 1
        guard exponent >= 3 else { return String(digits) }
        let group = exponent / 3
        let hasPrefix = group <= siPrefixes.count
        let wholeDigits = hasPrefix ? exponent % 3 + 1 : 1
        let whole = String(digits.prefix(wholeDigits))
        var fractionalDigits = Array(digits.dropFirst(wholeDigits).prefix(2))
        while fractionalDigits.last == "0" { fractionalDigits.removeLast() }
        let fraction = fractionalDigits.isEmpty ? "" : "." + String(fractionalDigits)
        let suffix = hasPrefix ? siPrefixes[group - 1] : "e\(exponent)"
        return whole + fraction + suffix
    }
}
