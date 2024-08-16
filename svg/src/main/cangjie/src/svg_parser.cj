/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights resvered.
 */

package svg

public interface SVGParser {

    func parseString(str: String): SVGBase

    func setInternalEntitiesEnabled(enable: Bool): SVGParser

    func setExternalFileResolver(fileResolver: ?SVGExternalFileResolver): SVGParser
}