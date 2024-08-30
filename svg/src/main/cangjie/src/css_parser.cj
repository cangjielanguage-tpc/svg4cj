/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights resvered.
 */

package svg

class CSSParser {
    private static let TAG: String = "CSSParser"
    static let CSS_MIME_TYPE: String = "text/css"
    static let ID: String = "id"
    static let CLASS: String = "class"
    public static let SPECIFICITY_ID_ATTRIBUTE: Int64 = 1000000
    public static let SPECIFICITY_ATTRIBUTE_OR_PSEUDOCLASS: Int64 = 1000
    public static let SPECIFICITY_ELEMENT_OR_PSEUDOELEMENT: Int64 = 1
    private var deviceMediaType: String
    private let externalFileResolver: SVGExternalFileResolver
    private var source: Source
    private var inMediaRule: Bool = false

    init(rendererMediaType!: String = "screen", source!: Source = Source.Document,
        externalFileResolver!: SVGExternalFileResolver = SVGExternalFileResolver()) {
        this.deviceMediaType = rendererMediaType
        this.source = source
        this.externalFileResolver = externalFileResolver
    }

    func parse(sheet: String): RuleSet {
        let scan: CSSTextScanner = CSSTextScanner(sheet)
        scan.skipWhitespace()
        return parseRuleSet(scan)
    }

    static func mediaMatches(mediaListStr: String, rendererMediaType: String): Bool {
        let scan: CSSTextScanner = CSSTextScanner(mediaListStr)
        scan.skipWhitespace()
        let mediaList: ArrayList<String> = CSSParser.parseMediaList(scan)
        return mediaMatchesArray(mediaList, rendererMediaType)
    }

    private static func mediaMatchesArray(mediaList: ArrayList<String>, rendererMediaType: String): Bool {
        if (mediaList.size == 0) {
            return true
        }
        for (i in 0..mediaList.size) {
            if (mediaList[i] == "all" || mediaList[i] == rendererMediaType) {
                return true
            }
        }
        return false
    }

    private static func parseMediaList(scan: CSSTextScanner): ArrayList<String> {
        let typeList: ArrayList<String> = ArrayList<String>()
        while (!scan.empty()) {
            let types: String = scan.nextWord()
            if (types == "") {
                break
            }
            try {
                typeList.append(types)
            } catch (e: Exception) {}
            if (!scan.skipCommaWhitespace()) {
                break
            }
        }
        return typeList
    }

    private func parseAtRule(ruleset: RuleSet, scan: CSSTextScanner): Unit {
        let atKeyword: String = scan.nextIdentifier()
        scan.skipWhitespace()
        if (atKeyword == "") {
            throw Exception("Invalid '@' rule")
        }
        if (!this.inMediaRule && atKeyword == "media") {
            let mediaList: ArrayList<String> = CSSParser.parseMediaList(scan)
            if (!scan.consume("{")) {
                throw Exception("Invalid @media rule: missing rule set")
            }
            scan.skipWhitespace()
            if (CSSParser.mediaMatchesArray(mediaList, this.deviceMediaType)) {
                this.inMediaRule = true
                ruleset.addAll(parseRuleSet(scan))
                this.inMediaRule = false
            } else {
                parseRuleSet(scan)
            }

            if (!scan.empty() && !scan.consume("}")) {
                throw Exception("Invalid @media rule: expected '}' at end of rule set")
            }
        } else if (!this.inMediaRule && atKeyword == "import") {
            var files: String = scan.nextURL()
            if (files == "") {
                files = scan.nextCSSString()
            }
            if (files == "") {
                throw Exception("Invalid @import rule: expected string or url()")
            }
            scan.skipWhitespace()
            let mediaList: ArrayList<String> = CSSParser.parseMediaList(scan)
            if (!scan.empty() && !scan.consume(";")) {
                throw Exception("Invalid @media rule: expected '}' at end of rule set")
            }
            if (CSSParser.mediaMatchesArray(mediaList, this.deviceMediaType)) {
                let css: String = externalFileResolver.resolveCSSStyleSheet(files)
                if (css == "") {
                    return
                }
                ruleset.addAll(parse(css))
            }
        } else {
            skipAtRule(scan)
        }
        scan.skipWhitespace()
    }

    private func skipAtRule(scan: CSSTextScanner): Unit {
        var depth: Int64 = 0
        while (!scan.empty()) {
            let ch = scan.nextChar()
            if (ch == r';' && depth == 0) {
                return
            }
            if (ch == r'{') {
                depth++
            } else if (ch == r'}' && depth > 0) {
                depth--
                if (depth == 0) {
                    return
                }
            }
        }
    }

    private func parseRuleSet(scan: CSSTextScanner): RuleSet {
        let ruleSet: RuleSet = RuleSet()
        try {
            while (!scan.empty()) {
                if (scan.consume("<!--")) {
                    continue
                }
                if (scan.consume("-->")) {
                    continue
                }
                if (scan.consume("@")) {
                    parseAtRule(ruleSet, scan)
                    continue
                }
                if (parseRule(ruleSet, scan)) {
                    continue
                }
                break
            }
        } catch (e: Exception) {
            println(CSSParser.TAG + "CSS parser terminated early due to error: " + "${e.printStackTrace()}")
        }
        return ruleSet
    }

    private func parseRule(ruleSet: RuleSet, scan: CSSTextScanner): Bool {
        let selectors: ?ArrayList<Selector> = scan.nextSelectorGroup()
        if (selectors.isSome() && selectors().size > 0) {
            if (!scan.consume("{")) {
                throw Exception("Malformed rule block: expected '{'")
            }
            scan.skipWhitespace()
            let ruleStyle: Style = parseDeclarations(scan)
            scan.skipWhitespace()
            for (i in 0..selectors().size) {
                ruleSet.add(Rule(selectors()[i], ruleStyle, source))
            }
            return true
        } else {
            return false
        }
    }

    private func parseDeclarations(scan: CSSTextScanner): Style {
        let ruleStyle: Style = Style()
        do {
            let propertyName: String = scan.nextIdentifier()
            scan.skipWhitespace()
            if (!scan.consume(":")) {
                throw Exception("Expected ':'")
            }
            scan.skipWhitespace()
            let propertyValue: String = scan.nextPropertyValue()
            if (propertyValue == "") {
                throw Exception("Expected property value")
            }
            scan.skipWhitespace()
            if (scan.consume("!")) {
                scan.skipWhitespace()
                if (!scan.consume("important")) {
                    throw Exception("Malformed rule set: found unexpected '!'")
                }
                scan.skipWhitespace()
            }
            scan.consume(";")
            Style.processStyleProperty(ruleStyle, propertyName, propertyValue)
            scan.skipWhitespace()
        } while (!scan.empty() && !scan.consume("}"))
        return ruleStyle
    }

    public static func parseClassAttribute(val: String): ArrayList<String> {
        let scan: CSSTextScanner = CSSTextScanner(val)
        var classNameList: ArrayList<String> = ArrayList<String>()
        while (!scan.empty()) {
            let className = scan.nextToken("", false)
            if (className == "") {
                continue
            }
            classNameList.append(className)
            scan.skipWhitespace()
        }
        return classNameList
    }

    static func ruleMatch(ruleMatchContext: RuleMatchContext, selector: Selector, obj: SvgElementBase): Bool {
        if (selector.size() == 1) {
            return selectorMatch(ruleMatchContext, selector.get(0), obj)
        }
        let ancestors: ArrayList<SvgContainer> = ArrayList<SvgContainer>()
        var parent: ?SvgContainer = obj.parent
        while (let Some(v) <- parent) {
            ancestors.append(v)
            // @ts-ignore
            if (let Some(k) <- v as SvgObject) {
                parent = k.parent
            }
        }
        return ruleMatch2(ruleMatchContext, selector, selector.size() - 1, ancestors, ancestors.size - 1, obj)
    }

    private static func ruleMatch2(ruleMatchContext: RuleMatchContext, selector: Selector, selPartPos: Int64,
        ancestors: ArrayList<SvgContainer>, anc: Int64, obj: SvgElementBase): Bool {
        var ancestorsPos: Int64 = anc
        let sel: SimpleSelector = selector.get(selPartPos)
        if (!selectorMatch(ruleMatchContext, sel, obj)) {
            return false
        }
        if (sel.combinator == Combinator.DESCENDANT) {
            if (selPartPos == 0) {
                return true
            }
            while (ancestorsPos >= 0) {
                if (ruleMatchOnAncestors(ruleMatchContext, selector, selPartPos - 1, ancestors, ancestorsPos)) {
                    return true
                }
                ancestorsPos--
            }
            return false
        } else if (sel.combinator == Combinator.CHILD) {
            return ruleMatchOnAncestors(ruleMatchContext, selector, selPartPos - 1, ancestors, ancestorsPos)
        } else {
            let childPos = getChildPosition(ancestors, ancestorsPos, obj)
            if (childPos <= 0) {
                return false
            }
            let prevSibling: SvgElementBase = (obj.parent().getChildren()[childPos - 1] as SvgElementBase).getOrThrow()
            return ruleMatch2(ruleMatchContext, selector, selPartPos - 1, ancestors, ancestorsPos, prevSibling)
        }
    }

    private static func ruleMatchOnAncestors(ruleMatchContext: RuleMatchContext, selector: Selector, selPartPos: Int64,
        ancestors: ArrayList<SvgContainer>, atp: Int64): Bool {
        var ancestorsPos: Int64 = atp
        let sel: SimpleSelector = selector.get(selPartPos)
        // @ts-ignore
        let obj: SvgElementBase = (ancestors[ancestorsPos] as SvgElementBase)()
        if (!selectorMatch(ruleMatchContext, sel, obj)) {
            return false
        }
        if (sel.combinator == Combinator.DESCENDANT) {
            if (selPartPos == 0) {
                return true
            }
            while (ancestorsPos > 0) {
                ancestorsPos--
                if (ruleMatchOnAncestors(ruleMatchContext, selector, selPartPos - 1, ancestors, ancestorsPos)) {
                    return true
                }
            }
            return false
        } else if (sel.combinator == Combinator.CHILD) {
            return ruleMatchOnAncestors(ruleMatchContext, selector, selPartPos - 1, ancestors, ancestorsPos - 1)
        } else {
            let childPos: Int64 = getChildPosition(ancestors, ancestorsPos, obj)
            if (childPos <= 0) {
                return false
            }
            let prevSibling: SvgElementBase = (obj.parent().getChildren()[childPos - 1] as SvgElementBase)()
            return ruleMatch2(ruleMatchContext, selector, selPartPos - 1, ancestors, ancestorsPos, prevSibling)
        }
    }

    private static func getChildPosition(ancestors: ArrayList<SvgContainer>, ancestorsPos: Int64, obj: SvgElementBase): Int64 {
        if (ancestorsPos < 0) {
            return 0
        }
        var childPos = 0
        for (child in obj.parent().getChildren()) {
            if (child as SvgElementBase == obj) {
                return childPos
            }
            childPos++
        }
        return -1
    }

    private static func selectorMatch(ruleMatchContext: RuleMatchContext, sel: SimpleSelector, obj: SvgElementBase): Bool {
        if (!sel.tag.isEmpty() && sel.tag != obj.getNodeName().toAsciiLower()) {
            return false
        }
        if (!sel.attribs.isEmpty()) {
            let count: Int64 = sel.attribs.size
            for (i in 0..count) {
                let attr: Attrib = sel.attribs[i]
                match (attr.name) {
                    case ID => if (attr.value != obj.id) {
                        return false
                    }
                    case CLASS =>
                        if (obj.classNames.isEmpty()) {
                            return false
                        }
                        if (obj.classNames.toArray().indexOf(attr.value).isNone()) {
                            return false
                        }
                    case _ => return false
                }
            }
        }

        if (!sel.pseudos.isEmpty()) {
            let count: Int64 = sel.pseudos.size
            for (i in 0..count) {
                let pseudo: PseudoClass = sel.pseudos[i]
                if (!pseudo.matches(ruleMatchContext, obj)) {
                    return false
                }
            }
        }
        return true
    }
}

class RuleSet {
    private let rules: ArrayList<Rule> = ArrayList<Rule>()

    func add(rule: Rule) {
        for (i in 0..this.rules.size) {
            let nextRule: Rule = this.rules[i]
            if (nextRule.selector.specificity > rule.selector.specificity) {
                this.rules.append(rule)
                return
            }
        }
        this.rules.append(rule)
    }

    func addAll(rules: RuleSet): Unit {
        if (rules.rules.isEmpty()) {
            return
        }
        for (i in 0..rules.rules.size) {
            add(rules.rules[i])
        }
    }

    func getRules(): ArrayList<Rule> {
        return this.rules
    }

    func isEmpty(): Bool {
        return this.rules.isEmpty() || this.rules.size == 0
    }

    func removeFromSource(sourceToBeRemoved: Source) {
        for (i in 0..this.rules.size) {
            if (this.rules[i].source == sourceToBeRemoved) {
                this.rules.slice(i..1)
            }
        }
    }
}

class Rule {
    var selector: Selector
    var style: Style
    var source: Source

    init(selector: Selector, style: Style, source: Source) {
        this.selector = selector
        this.style = style
        this.source = source
    }
}

interface PseudoClass {
    func matches(ruleMatchContext: RuleMatchContext, obj: SvgElementBase): Bool
}

class PseudoClassNot <: PseudoClass {
    private let selectorGroup: ArrayList<Selector>

    init(selectorGroup: ArrayList<Selector>) {
        this.selectorGroup = selectorGroup
    }

    public func matches(ruleMatchContext: RuleMatchContext, obj: SvgElementBase): Bool {
        for (i in 0..this.selectorGroup.size) {
            if (CSSParser.ruleMatch(ruleMatchContext, this.selectorGroup[i], obj)) {
                return false
            }
        }
        return true
    }

    func getSpecificity(): Int64 {
        var highest: Int64 = Int64.Min
        for (i in 0..this.selectorGroup.size) {
            if (this.selectorGroup[i].specificity > highest) {
                highest = this.selectorGroup[i].specificity
            }
        }
        return highest
    }
}

class PseudoClassTarget <: PseudoClass {
    public func matches(ruleMatchContext: RuleMatchContext, obj: SvgElementBase): Bool {
        return obj == ruleMatchContext.targetElement
    }
}

class PseudoClassNotSupported <: PseudoClass {
    private var clazz: String

    init(clazz: String) {
        this.clazz = clazz
    }

    public func matches(ruleMatchContext: RuleMatchContext, obj: SvgElementBase): Bool {
        return false
    }
}

class PseudoClassAnPlusB <: PseudoClass {
    private var a: Int64
    private var b: Int64
    private var isFromStart: Bool
    private var isOfType: Bool
    private var nodeName: String

    init(a: Int64, b: Int64, isFromStart: Bool, isOfType: Bool, nodeName: String) {
        this.a = a
        this.b = b
        this.isFromStart = isFromStart
        this.isOfType = isOfType
        this.nodeName = nodeName
    }

    public func matches(ruleMatchContext: RuleMatchContext, obj: SvgElementBase): Bool {
        var nodeNameToCheck: String = if (this.isOfType && this.nodeName == "") {
            obj.getNodeName()
        } else {
            this.nodeName
        }
        var childPos: Int64 = 0
        var childCount: Int64 = 1
        if (obj.parent.isSome()) {
            childCount = 0
            for (child in obj.parent().getChildren()) {
                if (child as SvgElementBase == obj) {
                    childPos = childCount
                }
                if (nodeNameToCheck == "" || child.getNodeName() == nodeNameToCheck) {
                    childCount++
                }
            }
        }
        childPos = if (this.isFromStart) {
            childPos + 1
        } else {
            childCount - childPos
        }
        if (this.a == 0) {
            return childPos == this.b
        }
        let condition1: Bool = ((childPos - this.b) % this.a) == 0
        let condition2a: Bool = childPos - this.b == 0
        var result1: Int64 = if (childPos - this.b > 0) {
            1
        } else {
            -1
        }
        var result2: Int64 = if (this.a > 0) {
            1
        } else {
            -1
        }
        let condition2b: Bool = result1 == result2
        let condition2: Bool = condition2a || condition2b
        return condition1 && condition2
    }
}

class Selector {
    var specificity: Int64 = 0
    let simpleSelectors: ArrayList<SimpleSelector> = ArrayList<SimpleSelector>()

    func isEmpty(): Bool {
        return this.simpleSelectors.size == 0
    }

    func add(part: SimpleSelector): Unit {
        this.simpleSelectors.append(part)
    }

    func size(): Int64 {
        if (this.simpleSelectors.isEmpty()) {
            return 0
        }
        return this.simpleSelectors.size
    }

    func get(i: Int64): SimpleSelector {
        return this.simpleSelectors[i]
    }

    func addedElement(): Unit {
        this.specificity += CSSParser.SPECIFICITY_ELEMENT_OR_PSEUDOELEMENT
    }

    func addedIdAttribute(): Unit {
        this.specificity += CSSParser.SPECIFICITY_ID_ATTRIBUTE
    }

    func addedAttributeOrPseudo(): Unit {
        this.specificity += CSSParser.SPECIFICITY_ATTRIBUTE_OR_PSEUDOCLASS
    }
}

class RuleMatchContext {
    var targetElement: SvgElementBase = SvgElementBase()
}

class Attrib {
    public var name: String
    var operation: AttribOp
    public var value: String

    init(name: String, op: AttribOp, value: String) {
        this.name = name
        this.operation = op
        this.value = value
    }
}

class SimpleSelector {
    var combinator: Combinator
    var tag: String
    let attribs: ArrayList<Attrib> = ArrayList<Attrib>()
    let pseudos: ArrayList<PseudoClass> = ArrayList<PseudoClass>()

    init(combinator: ?Combinator, tag: String) {
        if (let Some(v) <- combinator) {
            this.combinator = v
        } else {
            this.combinator = Combinator.DESCENDANT
        }
        this.tag = tag
    }

    func addAttrib(attrName: String, op: AttribOp, attrValue: String): Unit {
        this.attribs.append(Attrib(attrName, op, attrValue))
    }

    func addPseudo(pseudo: PseudoClass): Unit {
        this.pseudos.append(pseudo)
    }
}

enum Source {
    | Document
    | RenderOptions

    public operator func ==(that: Source): Bool {
        match ((this, that)) {
            case (Document, Document) => true
            case (RenderOptions, RenderOptions) => true
            case _ => false
        }
    }
}

enum Combinator {
    | DESCENDANT
    | CHILD
    | FOLLOWS

    public operator func ==(that: Combinator): Bool {
        match ((this, that)) {
            case (DESCENDANT, DESCENDANT) => true
            case (CHILD, CHILD) => true
            case (FOLLOWS, FOLLOWS) => true
            case _ => false
        }
    }
}

enum AttribOp {
    | EXISTS
    | EQUALS
    | INCLUDES
    | DASHMATCH

    public operator func ==(that: AttribOp): Bool {
        match ((this, that)) {
            case (EXISTS, EXISTS) => true
            case (EQUALS, EQUALS) => true
            case (INCLUDES, INCLUDES) => true
            case (DASHMATCH, DASHMATCH) => true
            case _ => false
        }
    }
}

class PseudoClassIdents {
    static let target: String = "target"
    static let root: String = "root"
    static let nth_child: String = "nth_child"
    static let nth_last_child: String = "nth_last_child"
    static let nth_of_type: String = "nth_of_type"
    static let nth_last_of_type: String = "nth_last_of_type"
    static let first_child: String = "first_child"
    static let last_child: String = "last_child"
    static let first_of_type: String = "first_of_type"
    static let last_of_type: String = "last_of_type"
    static let only_child: String = "only_child"
    static let only_of_type: String = "only_of_type"
    static let empty: String = "empty"
    static let not: String = "not"
    static let link: String = "link"
    static let visited: String = "visited"
    static let hover: String = "hover"
    static let active: String = "active"
    static let focus: String = "focus"
    static let enabled: String = "enabled"
    static let disabled: String = "disabled"
    static let checked: String = "checked"
    static let indeterminate: String = "indeterminate"
    static let lang: String = "lang"
}

class PseudoClassOnlyChild <: PseudoClass {
    private var isOfType: Bool
    private var nodeName: String

    public init(isOfType: Bool, nodeName: String) {
        this.isOfType = isOfType
        this.nodeName = nodeName
    }

    public func matches(ruleMatchContext: RuleMatchContext, obj: SvgElementBase): Bool {
        let nodeNameToCheck: String = if (this.isOfType && this.nodeName == "") {
            obj.getNodeName()
        } else {
            this.nodeName
        }
        var childCount: Int64 = 1
        if (obj.parent.isSome()) {
            childCount = 0
            for (child in obj.parent().getChildren()) {
                if (nodeNameToCheck == "" || child.getNodeName() == nodeNameToCheck) {
                    childCount++
                }
            }
        }
        return (childCount == 1)
    }
}

class PseudoClassRoot <: PseudoClass {
    public func matches(ruleMatchContext: RuleMatchContext, obj: SvgElementBase): Bool {
        return obj.parent.isNone()
    }
}

class PseudoClassEmpty <: PseudoClass {
    public func matches(ruleMatchContext: RuleMatchContext, obj: SvgElementBase): Bool {
        // @ts-ignore
        if (obj is SvgContainer) {
            return (obj as SvgContainer)().getChildren().size == 0
        } else {
            return true
        }
    }
}
