/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights resvered.
 */

package svg

public class SVGParserImpl <: SVGParser {
    private var enableInternalEntities: Bool = true

    private var externalFileResolver: ?SVGExternalFileResolver = None

    public func parseString(str: String): SVGBase {
        return SVGBase(false, SVGExternalFileResolver())
    }

    public func setInternalEntitiesEnabled(enable: Bool): SVGParser {
        this.enableInternalEntities = enable
        return this
    }

    public func setExternalFileResolver(fileResolver: SVGExternalFileResolver): SVGParser {
        this.externalFileResolver = fileResolver
        return this
    }
}
