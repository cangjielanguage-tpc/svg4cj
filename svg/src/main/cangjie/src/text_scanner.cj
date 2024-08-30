/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights resvered.
 */

package svg

public open class TextScanner {
    var input: String
    var position: Int64 = 0
    var inputLength: Int64
    private let numberParser: NumberParser = NumberParser()

    public init(input: String) {
        this.input = input.trimAscii()
        this.inputLength = this.input.size
    }

    public func empty(): Bool {
        return (this.position == this.inputLength)
    }

    func isWhitespace(c: Rune): Bool {
        return (c == r' ' || c == r'\n' || c == r'\r' || c == r'\t')
    }

    public func skipWhitespace(): Unit {
        while (this.position < this.inputLength) {
            if (!this.isWhitespace(this.input.toRuneArray()[this.position])) {
                break
            }
            this.position++
        }
    }

    func isEOL(c: Rune): Bool {
        return (c == r'\n' || c == r'\r')
    }

    public func skipCommaWhitespace(): Bool {
        this.skipWhitespace()
        if (this.position == this.inputLength) {
            return false
        }
        if (!(this.input.toRuneArray()[this.position] == r',')) {
            return false
        }
        this.position++
        this.skipWhitespace()
        return true
    }

    public func nextFloat(): Float64 {
        let val: Float64 = this.numberParser.parseNumber(this.input, this.position, this.inputLength)
        this.position = this.numberParser.getEndPos()
        return val
    }

    func nextInteger(withSign: Bool): Int64 {
        let ip: ?IntegerParser = IntegerParser.parseInt(input, position, inputLength, withSign)
        if (ip.isNone()) {
            return 0
        }
        position = ip().getEndPos()
        return ip().getValue()
    }

    func possibleNextFloat(): Float64 {
        this.skipCommaWhitespace()
        let val: Float64 = this.numberParser.parseNumber(this.input, this.position, this.inputLength)
        this.position = this.numberParser.getEndPos()
        return val
    }

    func checkedNextFloat(lastRead: Float64): Float64 {
        skipCommaWhitespace()
        return nextFloat()
    }

    func nextChar(): Rune {
        if (this.position == this.inputLength) {
            return r' '
        }
        let res = this.input.toRuneArray()[this.position]
        this.position++
        return res
    }

    func nextLength(): SVGLength {
        let scalar: Float64 = this.nextFloat()
        let unit: String = this.nextUnit()
        if (unit == "") {
            return SVGLength(scalar, u: Units.px)
        } else {
            return SVGLength(scalar, u: unit)
        }
    }

    func nextFlag(): ?Bool {
        if (this.position == this.inputLength) {
            return None
        }
        let ch: Rune = this.input.toRuneArray()[this.position]
        if (ch == r'0' || ch == r'1') {
            this.position++
            return (ch == r'1')
        }
        return None
    }

    func checkedNextFlag(lastRead: ?Object): ?Bool {
        if (lastRead.isNone()) {
            return None
        }
        this.skipCommaWhitespace()
        return this.nextFlag()
    }

    public func consume(str: String): Bool {
        if (str.size == 1) {
            let found: Bool = (this.position < this.inputLength && this.input.toRuneArray()[this.position] ==
                str.toRuneArray()[0])
            if (found) {
                this.position++
            }
            return found
        } else {
            let len: Int64 = str.size
            let found: Bool = (position <= (inputLength - len) && input[position..position + len] == (str))
            if (found) {
                this.position++
            }
            return found
        }
    }

    func advanceChar(): Rune {
        if (this.position == this.inputLength) {
            return r' '
        }
        this.position++
        if (this.position < this.inputLength) {
            return input.toRuneArray()[this.position]
        } else {
            return r' '
        }
    }

    func nextTokenWithWhitespace(terminator: String): String {
        return this.nextToken(terminator, true)
    }

    func nextToken(terminator: String, allowWhitespace: Bool): String {
        if (this.empty()) {
            return ""
        }
        var ch: Rune = this.input.toRuneArray()[this.position]
        if ((!allowWhitespace && this.isWhitespace(ch)) || ch.toString() == terminator) {
            return ""
        }
        let start: Int64 = this.position
        ch = this.advanceChar()
        while (ch != r" ") {
            0
            if (ch.toString() == terminator) {
                break
            }
            if (!allowWhitespace && this.isWhitespace(ch)) {
                break
            }
            ch = this.advanceChar()
        }
        return this.input[start..this.position]
    }

    public func nextWord(): String {
        if (this.empty()) {
            return ""
        }
        let start: Int64 = this.position
        var ch: Rune = this.input.toRuneArray()[this.position]
        if ((ch >= r'A' && ch <= r'Z') || (ch >= r'a' && ch <= r'z')) {
            ch = this.advanceChar()
            while ((ch >= r'A' && ch <= r'Z') || (ch >= r'a' && ch <= r'z')) {
                ch = this.advanceChar()
            }
            return input[start..this.position]
        }
        this.position = start
        return ""
    }

    func nextFunction(): String {
        if (this.empty()) {
            return ""
        }
        let start: Int64 = this.position
        var ch: Rune = this.input.toRuneArray()[this.position]
        while ((ch >= r'a' && ch <= r'z') || (ch >= r'A' && ch <= r'Z')) {
            ch = this.advanceChar()
        }
        let end: Int64 = this.position
        while (this.isWhitespace(ch)) {
            ch = this.advanceChar()
        }
        if (ch == r'(') {
            this.position++
            return this.input[start..end]
        }
        this.position = start
        return ""
    }

    func ahead(): String {
        let start: Int64 = this.position
        while (!this.empty() && !this.isWhitespace(this.input.toRuneArray()[this.position])) {
            this.position++
        }
        let str: String = this.input[start..this.position]
        this.position = start
        return str
    }

    func nextUnit(): String {
        if (this.empty()) {
            return ""
        }
        var ch = this.input.toRuneArray()[this.position]
        if (ch == r'%') {
            this.position++
            return Units.percent
        }
        if (this.position > (this.inputLength - 2)) {
            return ""
        }
        try {
            let str: String = this.input[this.position..this.position + 2]
            if (Character.isLetter(str)) {
                let result = str.toAsciiLower()
                this.position += 2
                return result
            } else {
                return ""
            }
        } catch (e: Exception) {
            return ""
        }
    }

    func hasLetter(): Bool {
        if (this.position == this.inputLength) {
            return false
        }
        let ch: Rune = this.input.toRuneArray()[this.position]
        return ((ch >= r'a' && ch <= r'z') || (ch >= r'A' && ch <= r'Z'))
    }

    public func nextQuotedString(): String {
        if (this.empty()) {
            return ""
        }
        let start: Int64 = this.position
        var ch: Rune = this.input.toRuneArray()[this.position]
        let endQuote: Rune = ch
        if (ch != r'\'' && ch != r'"') {
            return ""
        }
        ch = this.advanceChar()
        while (ch != r' ' && ch != endQuote) {
            ch = this.advanceChar()
        }

        if (ch == r' ') {
            this.position = start
            return ""
        }
        this.position++
        return this.input[(start + 1)..(this.position - 1)]
    }

    func restOfText(): String {
        if (this.empty()) {
            return ""
        }
        let start: Int64 = this.position
        this.position = this.inputLength
        return this.input[start..]
    }
}
