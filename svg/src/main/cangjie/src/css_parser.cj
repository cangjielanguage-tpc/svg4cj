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
    private let externalFileResolver: ?SVGExternalFileResolver
    private var source: ?Source
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
                    continue
                }
                break
            }
        } catch (e: Exception) {
            println(CSSParser.TAG + "CSS parser terminated early due to error: " + "${e.printStackTrace()}")
        }
        return ruleSet
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
            this.add(rules.rules[i])
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

class SimpleSelector {
    var combinator: Combinator
    var tag: String
    let attribs: ArrayList<Attrib> = ArrayList<Attrib>()
    let pseudos: ArrayList<PseudoClass> = ArrayList<PseudoClass>()

    init(combinator: ?Combinator, tag: String) {
        if (combinator.isSome()) {
            this.combinator = combinator.getOrThrow()
        }
        this.combinator = Combinator.DESCENDANT
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

interface PseudoClass {
    func matches(ruleMatchContext: RuleMatchContext, obj: SvgElementBase): Bool
}

class PseudoClassNot <: PseudoClass {
    private let selectorGroup: ArrayList<Selector>

    init(selectorGroup: ArrayList<Selector>) {
        this.selectorGroup = selectorGroup
    }

    public func matches(ruleMatchContext: RuleMatchContext, obj: SvgElementBase): Bool {
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
            for (child in obj.parent.getOrThrow().getChildren()) {
                if ((child as SvgElementBase).getOrThrow() == obj) {
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

class RuleMatchContext {
    var targetElement: SvgElementBase = SvgElementBase()
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
            for (child in obj.parent.getOrThrow().getChildren()) {
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
            return (obj as SvgContainer).getOrThrow().getChildren().size == 0
        } else {
            return true
        }
    }
}