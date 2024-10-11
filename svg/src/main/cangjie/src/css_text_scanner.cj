/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights resvered.
 */

package svg

public class CSSTextScanner <: TextScanner {
    static let PATTERN_BLOCK_COMMENTS: Regex = Regex("/\\/\\*[\\s\\S]*?\\*\\//")
    let DEFAULT_INTEGER_PARSER: IntegerParser = IntegerParser(0, 0)
    let DEFAULT_ANPLUSB: AnPlusB = AnPlusB(0, 0)

    public init(input: String) {
        super(PATTERN_BLOCK_COMMENTS.matcher(input).replaceAll(""))
    }

    public func nextIdentifier(): String {
        let end: Int64 = scanForIdentifier()
        if (end == position) {
            return ""
        }
        let result: String = input[position..end]
        position = end
        return result
    }

    private func scanForIdentifier(): Int64 {
        if (empty()) {
            return position
        }
        var start: Int64 = position
        var lastValidPos: Int64 = position
        var byte: Byte = input[position]
        if (byte == b'-') {
            byte = advanceChar()
        }
        if ((byte >= b'A' && byte <= b'Z') || (byte >= b'a' && byte <= b'z') || (byte == b'-') || (byte == b'_') || (byte >=
            0x80)) {
            byte = advanceChar()
            while ((byte >= b'A' && byte <= b'Z') || (byte >= b'a' && byte <= b'z') || (byte >= b'0' && byte <= b'9') ||
                    (byte == b'-') || (byte == b'_') || (byte >= 0x80)) {
                byte = advanceChar()
            }
            lastValidPos = position
        }
        position = start
        return lastValidPos
    }

    func nextSelectorGroup(): ArrayList<Selector> {
        if (empty()) {
            return ArrayList<Selector>()
        }
        let selectorGroup: ArrayList<Selector> = ArrayList<Selector>()
        var selector: Selector = Selector()
        while (!empty()) {
            if (nextSimpleSelector(selector)) {
                if (!skipCommaWhitespace()) {
                    continue
                }
                selectorGroup.append(selector)
                selector = Selector()
            } else {
                break
            }
        }
        if (!selector.isEmpty()) {
            selectorGroup.append(selector)
        }
        return selectorGroup
    }

    func nextSimpleSelector(selector: Selector): Bool {
        if (empty()) {
            return false
        }
        var start: Int64 = position
        var combinator: ?Combinator = None
        var selectorPart: ?SimpleSelector = None
        if (!selector.isEmpty()) {
            if (consume('>')) {
                combinator = Combinator.CHILD
                skipWhitespace()
            } else if (consume('+')) {
                combinator = Combinator.FOLLOWS
                skipWhitespace()
            }
        }
        if (consume('*')) {
            selectorPart = SimpleSelector(combinator, "")
        } else {
            let tag: String = nextIdentifier()
            if (tag != "") {
                selectorPart = SimpleSelector(combinator, tag)
                selector.addedElement()
            }
        }

        while (!empty()) {
            if (consume('.')) {
                if (selectorPart.isNone()) {
                    selectorPart = SimpleSelector(combinator, "")
                }
                let value: String = nextIdentifier()
                if (value == "") {
                    throw CSSParseException("Invalid \".class\" simpleSelectors")
                }
                selectorPart().addAttrib(CSSParser.CLASS, AttribOp.EQUALS, value)
                selector.addedAttributeOrPseudo()
                continue
            }

            if (consume('#')) {
                if (selectorPart.isNone()) {
                    selectorPart = SimpleSelector(combinator, "")
                }
                let value: String = nextIdentifier()
                if (value == "") {
                    throw CSSParseException("Invalid \"#id\" simpleSelectors")
                }
                selectorPart().addAttrib(CSSParser.ID, AttribOp.EQUALS, value)
                selector.addedIdAttribute()
                continue
            }

            // Now check for attribute selection and pseudo selectors
            if (consume('[')) {
                if (selectorPart.isNone()) {
                    selectorPart = SimpleSelector(combinator, "")
                }
                skipWhitespace()
                let attrName: String = nextIdentifier()
                var attrValue: String = ""
                if (attrName == "") {
                    throw CSSParseException("Invalid attribute simpleSelectors")
                }
                skipWhitespace()
                var op: ?AttribOp = None
                if (consume('=')) {
                    op = AttribOp.EQUALS
                } else if (consume("~=")) {
                    op = AttribOp.INCLUDES
                } else if (consume("|=")) {
                    op = AttribOp.DASHMATCH
                }
                if (op.isSome()) {
                    skipWhitespace()
                    attrValue = nextAttribValue()
                    if (attrValue == "") {
                        throw CSSParseException("Invalid attribute simpleSelectors")
                    }
                    skipWhitespace()
                }
                if (!consume(']')) {
                    throw CSSParseException("Invalid attribute simpleSelectors")
                }
                if (op.isNone()) {
                    selectorPart().addAttrib(attrName, AttribOp.EXISTS, attrValue)
                } else {
                    selectorPart().addAttrib(attrName, op(), attrValue)
                }
                selector.addedAttributeOrPseudo()
                continue
            }

            if (consume(':')) {
                if (selectorPart.isNone()) {
                    selectorPart = SimpleSelector(combinator, "")
                }
                parsePseudoClass(selector, selectorPart())
                continue
            }
            break
        }

        if (selectorPart.isSome()) {
            selector.add(selectorPart())
            return true
        }

        position = start
        return false
    }

    private func nextAnPlusB(): AnPlusB {
        if (empty()) {
            return DEFAULT_ANPLUSB
        }
        var start: Int64 = position
        if (!consume("(")) {
            return DEFAULT_ANPLUSB
        }
        skipWhitespace()
        var result: AnPlusB
        if (consume("odd")) {
            result = AnPlusB(2, 1)
        } else if (consume("even")) {
            result = AnPlusB(2, 0)
        } else {
            // Parse an expression of the form +An+B
            // First check for an optional leading sign
            var aSign: Int64 = 1
            var bSign: Int64 = 1
            if (consume('+')) {
            // do nothing
            } else if (consume('-')) {
                bSign = -1
            }
            // Then an integer
            var a: IntegerParser = DEFAULT_INTEGER_PARSER
            var b: IntegerParser = IntegerParser.parseInt(input, position, inputLength, false)
            if (b != DEFAULT_INTEGER_PARSER) {
                position = b.getEndPos()
            }
            // If an 'n' is next then that last part was the 'a' part. Now check for the 'b' part.
            if (consume('n') || consume('N')) {
                if (b != DEFAULT_INTEGER_PARSER) {
                    a = b
                } else {
                    a = IntegerParser(1, position)
                }
                aSign = bSign
                b = DEFAULT_INTEGER_PARSER
                bSign = 1
                skipWhitespace()
                // Check for the sign for the b part
                var hasB: Bool = consume('+')
                if (!hasB) {
                    hasB = consume('-')
                    if (hasB) {
                        bSign = -1
                    }
                }
                // If there was a sign, then the b integer should follow next
                if (hasB) {
                    skipWhitespace()
                    b = IntegerParser.parseInt(input, position, inputLength, false)
                    if (b != DEFAULT_INTEGER_PARSER) {
                        position = b.getEndPos()
                    } else {
                        position = start
                        return DEFAULT_ANPLUSB
                    }
                }
            }
            // Construct the result in anticipation that we will get the end bracket next
            if (b == DEFAULT_INTEGER_PARSER) {
                result = AnPlusB(aSign * a.getValue(), 0)
            } else {
                result = AnPlusB(aSign * a.getValue(), bSign * b.getValue())
            }
        }
        skipWhitespace()
        if (consume(')')) {
            return result
        }
        position = start
        return DEFAULT_ANPLUSB
    }

    /*
     * Parse a list of identifiers from a pseudo class parameter set.
     * Eg. for :lang(en)
     */
    private func nextIdentListParam(): ArrayList<String> {
        if (empty()) {
            return ArrayList<String>()
        }
        var start: Int64 = position
        var result: ArrayList<String> = ArrayList<String>()

        if (!consume('(')) {
            return ArrayList<String>()
        }
        skipWhitespace()
        do {
            var ident: String = nextIdentifier()
            if (ident == "") {
                position = start
                return ArrayList<String>()
            }
            result.append(ident)
            skipWhitespace()
        } while (skipCommaWhitespace())
        if (consume(')')) {
            return result
        }
        position = start
        return ArrayList<String>()
    }

    /*
     * Parse a simpleSelectors group inside a pair of brackets.  For the :not pseudo class.
     */
    private func nextPseudoNotParam(): ArrayList<Selector> {
        if (empty()) {
            return ArrayList<Selector>()
        }
        var start: Int64 = position
        if (!consume('(')) {
            return ArrayList<Selector>()
        }
        skipWhitespace()
        // Parse the parameter contents
        let result: ArrayList<Selector> = nextSelectorGroup()

        if (result.isEmpty()) {
            position = start
            return ArrayList<Selector>()
        }
        if (!consume(')')) {
            position = start
            return ArrayList<Selector>()
        }
        // Nesting a :not() pseudo class within a :not() is not allowed.
        for (selector in result) {
            if (selector.simpleSelectors.isEmpty()) {
                break
            }
            for (simpleSelector in selector.simpleSelectors) {
                if (simpleSelector.pseudos.isEmpty()) {
                    break
                }
                for (pseudo in simpleSelector.pseudos) {
                    if (pseudo is PseudoClassNot) {
                        return ArrayList<Selector>()
                    }
                }
            }
        }
        return result
    }

    /*
     * Parse a pseudo class (such as ":first-child")
     */
    private func parsePseudoClass(selector: Selector, selectorPart: SimpleSelector): Unit {
        let ident: String = nextIdentifier()
        if (ident == "") {
            throw CSSParseException("Invalid pseudo class")
        }
        var pseudo: PseudoClass = PseudoClassEmpty()
        if (ident == PseudoClassIdents.first_child) {
            pseudo = PseudoClassAnPlusB(0, 1, true, false, "")
            selector.addedAttributeOrPseudo()
        } else if (ident == PseudoClassIdents.last_child) {
            pseudo = PseudoClassAnPlusB(0, 1, false, false, "")
            selector.addedAttributeOrPseudo()
        } else if (ident == PseudoClassIdents.only_child) {
            pseudo = PseudoClassOnlyChild(false, "")
            selector.addedAttributeOrPseudo()
        } else if (ident == PseudoClassIdents.first_of_type) {
            pseudo = PseudoClassAnPlusB(0, 1, true, true, selectorPart.tag)
            selector.addedAttributeOrPseudo()
        } else if (ident == PseudoClassIdents.last_of_type) {
            pseudo = PseudoClassAnPlusB(0, 1, false, true, selectorPart.tag)
            selector.addedAttributeOrPseudo()
        } else if (ident == PseudoClassIdents.only_of_type) {
            pseudo = PseudoClassOnlyChild(true, selectorPart.tag)
            selector.addedAttributeOrPseudo()
        } else if (ident == PseudoClassIdents.root) {
            pseudo = PseudoClassRoot()
            selector.addedAttributeOrPseudo()
        } else if (ident == PseudoClassIdents.empty) {
            pseudo = PseudoClassEmpty()
            selector.addedAttributeOrPseudo()
        } else if (ident == PseudoClassIdents.nth_child) {
        } else if (ident == PseudoClassIdents.nth_last_child) {
        } else if (ident == PseudoClassIdents.nth_of_type) {
        } else if (ident == PseudoClassIdents.nth_last_of_type) {
            let fromStart: Bool = ident == PseudoClassIdents.nth_child || ident == PseudoClassIdents.nth_of_type
            let ofType: Bool = ident == PseudoClassIdents.nth_of_type || ident == PseudoClassIdents.nth_last_of_type
            let ab: AnPlusB = nextAnPlusB()
            if (ab == DEFAULT_ANPLUSB) {
                throw CSSParseException("Invalid or missing parameter section for pseudo class: " + ident)
            }
            pseudo = PseudoClassAnPlusB(ab.a, ab.b, fromStart, ofType, selectorPart.tag)
            selector.addedAttributeOrPseudo()
        } else if (ident == PseudoClassIdents.not) {
            let notSelectorGroup: ArrayList<Selector> = nextPseudoNotParam()
            if (notSelectorGroup.isEmpty()) {
                throw CSSParseException("Invalid or missing parameter section for pseudo class: " + ident)
            }
            pseudo = PseudoClassNot(notSelectorGroup)
            selector.specificity = (pseudo as PseudoClassNot)().getSpecificity()
        } else if (ident == PseudoClassIdents.target) {
            //TODO
            pseudo = PseudoClassTarget()
            selector.addedAttributeOrPseudo()
        } else if (ident == PseudoClassIdents.lang) {
            let langs: ArrayList<String> = nextIdentListParam()
            pseudo = PseudoClassNotSupported(ident)
            selector.addedAttributeOrPseudo()
        } else if (ident == PseudoClassIdents.link) {
        } else if (ident == PseudoClassIdents.visited) {
        } else if (ident == PseudoClassIdents.hover) {
        } else if (ident == PseudoClassIdents.active) {
        } else if (ident == PseudoClassIdents.focus) {
        } else if (ident == PseudoClassIdents.enabled) {
        } else if (ident == PseudoClassIdents.disabled) {
        } else if (ident == PseudoClassIdents.checked) {
        } else if (ident == PseudoClassIdents.indeterminate) {
            pseudo = PseudoClassNotSupported(ident)
            selector.addedAttributeOrPseudo()
        } else {
            throw CSSParseException("Unsupported pseudo class: " + ident)
        }
        selectorPart.addPseudo(pseudo)
    }

    /*
     * The value (bar) part of "[foo="bar"]".
     */
    private func nextAttribValue(): String {
        if (empty()) {
            return ""
        }
        var result: String = nextQuotedString()
        if (result != "") {
            return result
        }
        return nextIdentifier()
    }

    /*
     * Scans for a CSS property value.
     */
    public func nextPropertyValue(): String {
        if (empty()) {
            return ""
        }
        var start: Int64 = position
        var lastValidPos: Int64 = position
        var byte = input[position]
        while (byte != b' ' && byte != b';' && byte != b'}' && byte != b'!') {
            if (!isWhitespace(byte)) {
                // don't include an spaces at the end
                lastValidPos = position + 1
            }
            byte = advanceChar()
        }
        if (position > start) {
            return input[start..lastValidPos]
        }
        position = start
        return ""
    }

    /*
     * Scans for a string token
     */
    public func nextCSSString(): String {
        if (empty()) {
            return ""
        }
        var byte = input[position]
        let endQuote = byte
        if (byte != b'\'' && byte != b'"') {
            return ""
        }
        let arr: ArrayList<Byte> = ArrayList<Byte>()
        position++
        byte = nextChar()
        while (byte != endQuote) {
            if (byte == b'\\') {
                // Escaped char sequence
                byte = nextChar()
                if (byte == b' ') {
                    // EOF: do nothing
                    continue
                }
                if (byte == b'\n' || byte == b'\r' || byte == b'\f') { // a CSS newline
                    byte = nextChar()
                    continue // Newline: consume it
                }
                var hc: Int64 = hexChar(byte)
                if (hc != -1) {
                    var codepoint: Int64 = hc
                    for (i in 0..5) {
                        byte = nextChar()
                        hc = hexChar(byte)
                        if (hc == -1) {
                            break
                        }
                        codepoint = codepoint * 16 + hc
                    }
                    arr.appendAll(codepoint.toString().toArray())
                }
                // Other chars just unescape to themselves
                // Fall through to append
            }
            arr.append(byte)
            byte = nextChar()
        }
        return unsafe { String.fromUtf8Unchecked(arr.getRawArray()[..arr.size]) }
    }

    private func hexChar(byte: Byte): Int64 {
        if (byte >= b'0' && byte <= b'9') {
            return Int64(byte) - 48
        }
        if (byte >= b'A' && byte <= b'F') {
            return Int64(byte) - 65 + 10
        }
        if (byte >= b'a' && byte <= b'f') {
            return Int64(byte) - 97 + 10
        }
        return -1
    }

    /*
     * Scans for a url("...")
     * Called a <url> in the CSS spec.
     */
    public func nextURL(): String {
        if (empty()) {
            return ""
        }
        var start: Int64 = this.position
        if (!consume("url(")) {
            return ""
        }
        skipWhitespace()
        var url: String = nextCSSString()
        if (url == "") {
            url = nextLegacyURL() // legacy quote-less url(...).  Called a <url-token> in the CSS3 spec.
        }
        if (url == "") {
            this.position = start
            return ""
        }
        skipWhitespace()
        if (empty() || consume(")")) {
            return url
        }
        position = start
        return ""
    }

    /*
     * Scans for a legacy URL string
     * See nextURLToken().
     */
    func nextLegacyURL(): String {
        let arr: ArrayList<Byte> = ArrayList<Byte>()
        while (!empty()) {
            var byte = input[position]
            if (byte == b'\'' || byte == b'"' || byte == b'(' || byte == b')' || isWhitespace(byte)) {
                break
            }
            this.position++
            if (byte == b'\\') {
                if (empty()) { // EOF: do nothing
                    continue
                }
                // Escaped char sequence

                byte = input[position]
                this.position++
                if (byte == b'\n' || byte == b'\r' || byte == b'\f') { // a CSS newline
                    continue // Newline: consume it
                }
                var hc: Int64 = hexChar(byte)
                if (hc != -1) {
                    var codepoint: Int64 = hc
                    for (i in 1..5) {
                        if (empty()) {
                            break
                        }
                        hc = hexChar(input[position])
                        if (hc == -1) { // Not a hex char
                            break
                        }
                        position++
                        codepoint = codepoint * 16 + hc
                    }
                    arr.appendAll(codepoint.toString().toArray())
                    continue
                }
                // Other chars just unescape to themselves
                // Fall through to append
            }
            arr.append(byte)
        }
        if (arr.size == 0) {
            return ""
        }
        return unsafe { String.fromUtf8Unchecked(arr.getRawArray()[..arr.size]) }
    }
}

class AnPlusB <: Equatable<AnPlusB> {
    public var a: Int64
    public var b: Int64

    init(a: Int64, b: Int64) {
        this.a = a
        this.b = b
    }

    public operator func ==(that: AnPlusB): Bool {
        return this.a == that.a && this.b == that.b
    }

    public operator func !=(that: AnPlusB): Bool {
        return !(this == that)
    }
}
