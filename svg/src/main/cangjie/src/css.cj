/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights resvered.
 */

package svg

public class CSS <: CSSBase {
    init(css: String) {
        super(css)
    }

    public static func getFromString(css: String): CSS {
        return CSS(css)
    }
}
