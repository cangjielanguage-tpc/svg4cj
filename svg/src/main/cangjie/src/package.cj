/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights resvered.
 */

package svg

internal import std.regex.Regex
internal import std.convert.*
internal import std.collection.HashMap
internal import std.collection.HashSet
internal import std.collection.ArrayList
internal import std.math.*
internal import ohos.base.*
internal import ohos.component.*
internal import ohos.state_manage.*
internal import ohos.image.PixelMap
internal import ohos.display.*
internal import ohos.resource_manager.ResourceManager
internal import ohos.resource_manager.Resource as OhosResource

internal import ohos.ability.*

extend<T> Option<T> {
    operator func ()(): T {
        this.getOrThrow()
    }
}