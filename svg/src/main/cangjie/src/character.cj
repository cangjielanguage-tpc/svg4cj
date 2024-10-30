/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */

package svg

public class Character {
    public static func isLetter(str: String): Bool {
        let reg: Regex = Regex("^[a-zA-Z]*$")
        if (reg.matcher(str).fullMatch().isSome()) {
            return true
        }
        return false
    }
}
