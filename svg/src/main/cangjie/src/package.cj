/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */

package svg

internal import std.regex.Regex
internal import std.convert.*
internal import std.collection.HashMap
internal import std.collection.HashSet
internal import std.collection.ArrayList
internal import std.collection.LinkedList
internal import std.math.*
internal import encoding.base64.*
internal import ohos.base.*
internal import ohos.image.PixelMap
internal import ohos.image.createPixelMap
internal import ohos.image.createImageSource
internal import ohos.image.ImageSource
internal import ohos.component.*
internal import ohos.state_manage.*
internal import ohos.image.PixelMap
internal import ohos.display.*
internal import ohos.resource_manager.ResourceManager
internal import ohos.resource_manager.AppResource as OhosResource
internal import ohos.resource_manager.RawFileDescriptor
internal import ohos.ability.*
internal import ohos.hilog.*
internal import ohos.prompt_action.*
internal import std.io.*
internal import svg.xml.*

extend<T> Option<T> {
    operator func ()(): T {
        this.getOrThrow()
    }
}
