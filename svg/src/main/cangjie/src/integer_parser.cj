/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights resvered.
 */

package svg

public class IntegerParser {
    var pos: Int64
    var value: Int64

    init(value: Int64, pos: Int64) {
        this.value = value
        this.pos = pos
    }

    func getEndPos(): Int64 {
        return pos
    }

    static func parseInt(input: String, startpos: Int64, len: Int64, includeSign: Bool): ?IntegerParser {
        var pos: Int64 = startpos
        var isNegative: Bool = false
        var value: Int64 = 0
        var ch: String
        if (pos >= len) {
            return None
        }
        if (includeSign) {
            ch = input[pos].toString()
            match (ch) {
                case "-" => isNegative = true
                case "+" => pos++
                case _ => ()
            }
        }
        var sigStart: Int64 = pos
        while (pos < len) {
            ch = input[pos].toString()
            if (ch >= "0" && ch <= "9") {
                if (isNegative) {
                    value = value * 10 - Int64.parse(ch)
                    if (value < Int64.Min) {
                        return None
                    }
                } else {
                    value = value * 10 + Int64.parse(ch)
                    if (value > Int64.Max) {
                        return None
                    }
                }
            } else {
                break
            }
            pos++
        }

        if (pos == sigStart) {
            return None
        }
        return IntegerParser(value, pos)
    }

    func getValue(): Int64 {
        return value
    }

    static func parseHex(input: String, startpos: Int64, len: Int64): ?IntegerParser {
        var pos: Int64 = startpos
        var value: Int64 = 0
        var ch: String
        if (pos >= len) {
            return None
        }
        while (pos < len) {
            ch = input[pos].toString()
            if (ch >= "0" && ch <= "9") {
                value = value * 16 + Int64.parse(ch)
            } else if (ch >= "A" && ch <= "F") {
                value = value * 16 + Int64.parse(ch) - 65 + 10
            } else if (ch >= "a" && ch <= "f") {
                value = value * 16 + Int64.parse(ch) - 97 + 10
            } else {
                break
            }
            if (value > 0xffffffff) {
                return None
            }
            pos++
        }
        if (pos == startpos) {
            return None
        }
        return IntegerParser(value, pos)
    }
}
