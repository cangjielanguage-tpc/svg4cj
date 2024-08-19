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

    init(rendererMediaType: String, s: ?Source, externalFileResolver: ?SVGExternalFileResolver) {
        var source: ?Source = s
        if (rendererMediaType == "") {
            this.deviceMediaType = "screen"
        }
        if (source.isNone()) {
            source = Source.Document
        }
        this.deviceMediaType = rendererMediaType
        this.source = source
        this.externalFileResolver = externalFileResolver
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
