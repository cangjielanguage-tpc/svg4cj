/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights resvered.
 */

package svg

/*
    This is just a link to CSSParser class. As CSSParser is package-protected and we don't want it
    to leak as a public API, we just gaining access through this inheritance.
 */
public open class CSSBase {
    var cssRuleset: RuleSet

    init(css: String) {
        this.cssRuleset = CSSParser(source: Source.RenderOptions).parse(css)
    }
}
