/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights resvered.
 */

package svg

class NumberParser {
    private var pos: Int64 = 0

    func getEndPos(): Int64 {
        return this.pos
    }

    func parseNumber(input: String, startpos: Int64, len: Int64): Float64 {
        var isNegative: Bool = false
        var significand: Int64 = 0
        var numDigits: Int64 = 0
        var numLeadingZeroes: Int64 = 0
        var numTrailingZeroes: Int64 = 0
        var decimalSeen: Bool = false
        var sigStart: Int64
        var decimalPos: Int64 = 0
        var exponent: Int64

        let TOO_BIG_L: Float64 = Float64.Max / 10.0
        let TOO_BIG_I: Int64 = Int64.Max / 10

        pos = startpos

        if (pos >= len) {
            return Float64.NaN
        }

        var ch: Rune = input.toRuneArray()[pos]
        match (ch) {
            case '-' => isNegative = true
            case '+' => pos++
            case _ => ()
        }

        sigStart = pos

        while (pos < len) {
            ch = input.toRuneArray()[pos]
            if (ch == r'0') {
                if (numDigits == 0) {
                    numLeadingZeroes++
                } else {
                    numTrailingZeroes++
                }
            } else if (ch >= r'1' && ch <= r'9') {
                numDigits += numTrailingZeroes
                while (numTrailingZeroes > 0) {
                    if (significand > Int64(TOO_BIG_L)) {
                        return Float64.NaN
                    }
                    significand *= 10
                    numTrailingZeroes--
                }

                if (significand > Int64(TOO_BIG_L)) {
                    return Float64.NaN
                }
                significand = significand * 10 + (Int64.parse(String(ch)) - 0)
                numDigits++
                if (significand < 0) {
                    return Float64.NaN
                }
            } else if (ch == r'.') {
                if (decimalSeen) {
                    break
                }
                decimalPos = pos - sigStart
                decimalSeen = true
            } else {
                break
            }
            pos++
        }

        if (decimalSeen && pos == (decimalPos + 1)) {
            return Float64.NaN
        }

        if (numDigits == 0) {
            if (numLeadingZeroes == 0) {
                return Float64.NaN
            }
            numDigits = 1
        }

        if (decimalSeen) {
            exponent = decimalPos - numLeadingZeroes - numDigits
        } else {
            exponent = numTrailingZeroes
        }

        if (pos < len) {
            ch = input.toRuneArray()[pos]
            if (ch == r'E' || ch == r'e') {
                var expIsNegative: Bool = false
                var expVal: Int64 = 0
                var abortExponent: Bool = false

                pos++
                if (pos == len) {
                    return Float64.NaN
                }

                match (input.toRuneArray()[pos]) {
                    case '-' => expIsNegative = true
                    case '+' => pos++
                    case '0' => ()
                    case '1' => ()
                    case '2' => ()
                    case '3' => ()
                    case '4' => ()
                    case '5' => ()
                    case '6' => ()
                    case '7' => ()
                    case '8' => ()
                    case '9' => ()
                    case _ =>
                        abortExponent = true
                        pos--
                }

                if (!abortExponent) {
                    var expStart: Int64 = pos

                    while (pos < len) {
                        ch = input.toRuneArray()[pos]
                        if (ch >= r'0' && ch <= r'9') {
                            if (expVal > TOO_BIG_I) {
                                return Float64.NaN
                            }
                            expVal = expVal * 10 + (Int64.parse(String(ch)) - 0)
                            pos++
                        } else {
                            break
                        }
                    }

                    if (pos == expStart) {
                        return Float64.NaN
                    }

                    if (expIsNegative) {
                        exponent -= expVal
                    } else {
                        exponent += expVal
                    }
                }
            }
        }

        if ((exponent + numDigits) > 39 || (exponent + numDigits) < -44) {
            return Float64.NaN
        }

        var f: Float64 = Float64(significand)
        if (significand != 0) {
            if (exponent > 0) {
                f *= positivePowersOf10[exponent]
            } else if (exponent < 0) {
                if (exponent < -38) {
                    f *= 1e-20
                    exponent += 20
                }
                f *= negativePowersOf10[-exponent]
            }
        }
        if (isNegative) {
            return -f
        } else {
            return f
        }
    }

    private static let positivePowersOf10: Array<Float64> = [1e0, 1e1, 1e2, 1e3, 1e4, 1e5, 1e6, 1e7, 1e8, 1e9, 1e10,
        1e11, 1e12, 1e13, 1e14, 1e15, 1e16, 1e17, 1e18, 1e19, 1e20, 1e21, 1e22, 1e23, 1e24, 1e25, 1e26, 1e27, 1e28,
        1e29, 1e30, 1e31, 1e32, 1e33, 1e34, 1e35, 1e36, 1e37, 1e38]

    private static let negativePowersOf10: Array<Float64> = [1e0, 1e-1, 1e-2, 1e-3, 1e-4, 1e-5, 1e-6, 1e-7, 1e-8, 1e-9,
        1e-10, 1e-11, 1e-12, 1e-13, 1e-14, 1e-15, 1e-16, 1e-17, 1e-18, 1e-19, 1e-20, 1e-21, 1e-22, 1e-23, 1e-24, 1e-25,
        1e-26, 1e-27, 1e-28, 1e-29, 1e-30, 1e-31, 1e-32, 1e-33, 1e-34, 1e-35, 1e-36, 1e-37, 1e-38]
}
