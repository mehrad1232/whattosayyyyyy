import Foundation

/// Small arbitrary-precision signed integer for exact calculator arithmetic.
/// Values are stored as a sign (-1, 0, 1) and a decimal magnitude string.
struct BigInteger: Equatable, CustomStringConvertible {
    private let sign: Int
    private let magnitude: String

    var description: String {
        sign < 0 ? "-" + magnitude : magnitude
    }

    init(_ rawValue: String) {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let negative = trimmed.hasPrefix("-")
        let positive = trimmed.hasPrefix("+")
        let body = (negative || positive) ? String(trimmed.dropFirst()) : trimmed
        let valid = !body.isEmpty && body.allSatisfy { $0 >= "0" && $0 <= "9" }
        guard valid else {
            self.sign = 0
            self.magnitude = "0"
            return
        }

        let cleaned = BigInteger.normalizeMagnitude(body)
        self.magnitude = cleaned
        self.sign = cleaned == "0" ? 0 : (negative ? -1 : 1)
    }

    private init(sign: Int, magnitude: String) {
        let cleaned = BigInteger.normalizeMagnitude(magnitude)
        self.magnitude = cleaned
        self.sign = cleaned == "0" ? 0 : (sign < 0 ? -1 : 1)
    }

    static func + (lhs: BigInteger, rhs: BigInteger) -> BigInteger {
        if lhs.sign == 0 { return rhs }
        if rhs.sign == 0 { return lhs }

        if lhs.sign == rhs.sign {
            return BigInteger(sign: lhs.sign, magnitude: addMagnitudes(lhs.magnitude, rhs.magnitude))
        }

        let comparison = compareMagnitudes(lhs.magnitude, rhs.magnitude)
        if comparison == 0 { return BigInteger("0") }
        if comparison > 0 {
            return BigInteger(sign: lhs.sign, magnitude: subtractMagnitudes(lhs.magnitude, rhs.magnitude))
        }
        return BigInteger(sign: rhs.sign, magnitude: subtractMagnitudes(rhs.magnitude, lhs.magnitude))
    }

    static func - (lhs: BigInteger, rhs: BigInteger) -> BigInteger {
        return lhs + BigInteger(sign: -rhs.sign, magnitude: rhs.magnitude)
    }

    func multiplied(by other: BigInteger) -> BigInteger {
        guard sign != 0, other.sign != 0 else { return BigInteger("0") }
        return BigInteger(
            sign: sign * other.sign,
            magnitude: BigInteger.multiplyMagnitudes(magnitude, other.magnitude)
        )
    }

    /// Integer division, truncating toward zero. Returns nil when divisor is zero.
    func divided(by other: BigInteger) -> BigInteger? {
        guard other.sign != 0 else { return nil }
        guard sign != 0 else { return BigInteger("0") }
        let quotient = BigInteger.divideMagnitudes(magnitude, other.magnitude)
        return BigInteger(sign: sign * other.sign, magnitude: quotient)
    }

    private static func normalizeMagnitude(_ value: String) -> String {
        let trimmed = value.drop(while: { $0 == "0" })
        return trimmed.isEmpty ? "0" : String(trimmed)
    }

    /// Returns -1, 0, or 1 depending on the unsigned magnitudes.
    private static func compareMagnitudes(_ lhs: String, _ rhs: String) -> Int {
        if lhs.count != rhs.count { return lhs.count < rhs.count ? -1 : 1 }
        if lhs == rhs { return 0 }
        return lhs < rhs ? -1 : 1
    }

    private static func addMagnitudes(_ lhs: String, _ rhs: String) -> String {
        let a = Array(lhs.utf8.reversed()).map { Int($0) - 48 }
        let b = Array(rhs.utf8.reversed()).map { Int($0) - 48 }
        let count = max(a.count, b.count)
        var result: [Int] = []
        result.reserveCapacity(count + 1)
        var carry = 0

        for index in 0..<count {
            let left = index < a.count ? a[index] : 0
            let right = index < b.count ? b[index] : 0
            let sum = left + right + carry
            result.append(sum % 10)
            carry = sum / 10
        }
        if carry > 0 { result.append(carry) }
        return result.reversed().map { String($0) }.joined()
    }

    /// Requires lhs magnitude >= rhs magnitude.
    private static func subtractMagnitudes(_ lhs: String, _ rhs: String) -> String {
        let a = Array(lhs.utf8.reversed()).map { Int($0) - 48 }
        let b = Array(rhs.utf8.reversed()).map { Int($0) - 48 }
        var result: [Int] = []
        result.reserveCapacity(a.count)
        var borrow = 0

        for index in 0..<a.count {
            let right = index < b.count ? b[index] : 0
            var difference = a[index] - borrow - right
            if difference < 0 {
                difference += 10
                borrow = 1
            } else {
                borrow = 0
            }
            result.append(difference)
        }

        while result.count > 1 && result.last == 0 { result.removeLast() }
        return normalizeMagnitude(result.reversed().map { String($0) }.joined())
    }

    private static func multiplyMagnitudes(_ lhs: String, _ rhs: String) -> String {
        let a = Array(lhs.utf8.reversed()).map { Int($0) - 48 }
        let b = Array(rhs.utf8.reversed()).map { Int($0) - 48 }
        var result = [Int](repeating: 0, count: a.count + b.count)

        for i in 0..<a.count {
            var carry = 0
            for j in 0..<b.count {
                let index = i + j
                let value = result[index] + a[i] * b[j] + carry
                result[index] = value % 10
                carry = value / 10
            }
            var index = i + b.count
            while carry > 0 && index < result.count {
                let value = result[index] + carry
                result[index] = value % 10
                carry = value / 10
                index += 1
            }
        }
        while result.count > 1 && result.last == 0 { result.removeLast() }
        return normalizeMagnitude(result.reversed().map { String($0) }.joined())
    }

    private static func divideMagnitudes(_ dividend: String, _ divisor: String) -> String {
        var remainder = "0"
        var quotient = ""

        for digit in dividend {
            remainder = normalizeMagnitude(remainder == "0" ? String(digit) : remainder + String(digit))
            var quotientDigit = 0
            while compareMagnitudes(remainder, divisor) >= 0 {
                remainder = subtractMagnitudes(remainder, divisor)
                quotientDigit += 1
            }
            quotient += String(quotientDigit)
        }
        return normalizeMagnitude(quotient)
    }
}
