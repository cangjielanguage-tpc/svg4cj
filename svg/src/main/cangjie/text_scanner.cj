/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
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

    func isWhitespace(b: Byte): Bool {
        return (b == b' ' || b == b'\n' || b == b'\r' || b == b'\t')
    }

    public func skipWhitespace(): Unit {
        while (this.position < this.inputLength) {
            if (!this.isWhitespace(this.input[this.position])) {
                break
            }
            this.position++
        }
    }

    func isEOL(b: Byte): Bool {
        return (b == b'\n' || b == b'\r')
    }

    public func skipCommaWhitespace(): Bool {
        skipWhitespace()
        if (this.position == this.inputLength) {
            return false
        }
        if (!(this.input[this.position] == b',')) {
            return false
        }
        this.position++
        skipWhitespace()
        return true
    }

    public func nextFloat(): Float64 {
        let val: Float64 = this.numberParser.parseNumber(this.input, this.position, this.inputLength)
        if (!val.isNaN()) {
            this.position = this.numberParser.getEndPos()
        }
        return val
    }

    func nextInteger(withSign: Bool): Int64 {
        let ip: IntegerParser = IntegerParser.parseInt(input, position, inputLength, withSign)
        if (ip == IntegerParser(0, 0)) {
            return 0
        }
        position = ip.getEndPos()
        return ip.getValue()
    }

    func possibleNextFloat(): Float64 {
        skipCommaWhitespace()
        let val: Float64 = this.numberParser.parseNumber(this.input, this.position, this.inputLength)
        if (!val.isNaN()) {
            this.position = this.numberParser.getEndPos()
        }
        return val
    }

    func checkedNextFloat(lastRead: Float64): Float64 {
        if (lastRead.isNaN()) {
            return Float64.NaN
        }
        skipCommaWhitespace()
        return nextFloat()
    }

    func checkedNextFloat(_: Bool): Float64 {
        skipCommaWhitespace()
        return nextFloat()
    }

    func nextChar(): Byte {
        if (this.position == this.inputLength) {
            return b' '
        }
        let res = this.input[this.position]
        this.position++
        return res
    }

    func nextLength(): ?SVGLength {
        let scalar: Float64 = nextFloat()
        let unit: String = nextUnit()
        if (scalar.isNaN()) {
        	return None
        }
        if (unit == "") {
            return SVGLength(scalar, u: Units.px)
        } else {
            return SVGLength(scalar, u: unit)
        }
    }

    func nextFlag(): Bool {
        if (this.position == this.inputLength) {
            return false
        }
        let byte: Byte = this.input[this.position]
        if (byte == b'0' || byte == b'1') {
            this.position++
            return (byte == b'1')
        }
        return false
    }

    func checkedNextFlag(lastRead: ?Any): Bool {
        if (lastRead.isNone()) {
            return false
        }
        skipCommaWhitespace()
        return this.nextFlag()
    }

    public func consume(str: String): Bool {
        if (str.size == 1) {
            let found: Bool = (this.position < this.inputLength && this.input[this.position] ==
                str[0])
            if (found) {
                this.position++
            }
            return found
        } else {
            let len: Int64 = str.size
            let found: Bool = (position <= (inputLength - len) && input[position..position + len] == (str))
            if (found) {
                this.position += len
            }
            return found
        }
    }

    func advanceChar(): Byte {
        if (this.position == this.inputLength) {
            return b' '
        }
        this.position++
        if (this.position < this.inputLength) {
            return input[this.position]
        } else {
            return b' '
        }
    }

    func nextTokenWithWhitespace(terminator: String): String {
        return nextToken(terminator: terminator, allowWhitespace: true)
    }

    func nextToken(terminator!: String = " ", allowWhitespace!: Bool = false): String {
        if (empty()) {
            return ""
        }
        var byte: Byte = this.input[this.position]
        if ((!allowWhitespace && isWhitespace(byte)) || byte.toString() == terminator) {
            return ""
        }
        let start: Int64 = this.position
        byte = advanceChar()
        while (byte != b' ') {
            0
            if (byte.toString() == terminator) {
                break
            }
            if (!allowWhitespace && this.isWhitespace(byte)) {
                break
            }
            byte = advanceChar()
        }
        return this.input[start..this.position]
    }

    public func nextWord(): String {
        if (empty()) {
            return ""
        }
        let start: Int64 = this.position
        var byte: Byte = this.input[this.position]
        if ((byte >= b'A' && byte <= b'Z') || (byte >= b'a' && byte <= b'z')) {
            byte = advanceChar()
            while ((byte >= b'A' && byte <= b'Z') || (byte >= b'a' && byte <= b'z')) {
                byte = advanceChar()
            }
            return input[start..this.position]
        }
        this.position = start
        return ""
    }

    func nextFunction(): String {
        if (empty()) {
            return ""
        }
        let start: Int64 = this.position
        var byte: Byte = this.input[this.position]
        while ((byte >= b'a' && byte <= b'z') || (byte >= b'A' && byte <= b'Z')) {
            byte = advanceChar()
        }
        let end: Int64 = this.position
        while (isWhitespace(byte)) {
            byte = advanceChar()
        }
        if (byte == b'(') {
            this.position++
            return this.input[start..end]
        }
        this.position = start
        return ""
    }

    func ahead(): String {
        let start: Int64 = this.position
        while (!empty() && !isWhitespace(this.input[this.position])) {
            this.position++
        }
        let str: String = this.input[start..this.position]
        this.position = start
        return str
    }

    func nextUnit(): String {
        if (empty()) {
            return ""
        }
        var byte = this.input[this.position]
        if (byte == b'%') {
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
        let byte: Byte = this.input[this.position]
        return ((byte >= b'a' && byte <= b'z') || (byte >= b'A' && byte <= b'Z'))
    }

    public func nextQuotedString(): String {
        if (empty()) {
            return ""
        }
        let start: Int64 = this.position
        var byte: Byte = this.input[this.position]
        let endQuote: Byte = byte
        if (byte != b'\'' && byte != b'"') {
            return ""
        }
        byte = advanceChar()
        while (byte != endQuote) {
            if (this.position >= this.inputLength) {
                this.position = start
                return ""
            }
            byte = advanceChar()
        }
        this.position++
        return this.input[(start + 1)..(this.position - 1)]
    }

    func restOfText(): String {
        if (empty()) {
            return ""
        }
        let start: Int64 = this.position
        this.position = this.inputLength
        return this.input[start..]
    }
}
