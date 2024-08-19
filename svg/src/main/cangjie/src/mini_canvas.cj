/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights resvered.
 */

package svg

public class Paint {
    private var fontSize: Length = vp2px(Length(20)).getOrThrow()

    init() {}

    func getFontSize(): Length {
        return this.fontSize
    }
}
