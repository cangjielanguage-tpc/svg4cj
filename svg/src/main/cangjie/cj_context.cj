/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025-2025. All rights reserved.
 */
package svg

import ohos.base.*
import ohos.component.*
import ohos.state_manage.*
import ohos.state_macro_manage.*
import ohos.ark_interop.*
import ohos.ark_interop_helper.*
import std.collection.*

/**
 * JSContext
 */
public var ctx: ?JSContext = None

/**
 * 定义一个全局的 Context 获取类，方便后续其他业务使用
 */
public class GlobalContext {
    static var _context: Option<StageContext> = None

    /**
     * 设置StageContext
     *
     * @param context StageContext
     */
    public static func setContext(context: StageContext) {
        _context = context
    }

    /**
     * 获取StageContext
     *
     * @return Option<StageContext> StageContext
     */
    public static func getContext(): Option<StageContext> {
        return _context
    }
}

/**
 * 设置StageContext互操作函数
 *
 * @param runtime JSContext
 * @param callInfo 接口数据
 * @return JSValue 返回值
 */
func setGlobalContext(runtime: JSContext, callInfo: JSCallInfo): JSValue {
    let jsEnv = runtime.getNapiEnv()
    let jsValue = arkTsValuetoNapiValue(jsEnv, callInfo[0])
    if (isStageMode(jsEnv, jsValue)) {
        GlobalContext.setContext(getContextStageMode(jsEnv, jsValue))
    } else {
    }
    return runtime.undefined().toJSValue()
}

public func getLoadCJPage(ctx: JSContext, callInfo: JSCallInfo): JSValue {
    let cssValue: String = callInfo[0].asString().toString()
    var model: ?CJSVGImageViewModel = None
    if (callInfo[1].typeof() != JSType.UNDEFINED) {
        let cfgObj: JSObject = callInfo[1].asObject(ctx)
        let cfgExt: Option<JSExternal> = cfgObj.getAttachInfo()
        if (let Some(v) <- cfgExt) {
            model = v.cast<CJSVGImageViewModel>()
        }
    }
    let elmetId = ViewStackProcessor.AllocateNewElmetIdForNextComponent()
    ViewStackProcessor.StartGetAccessRecordingFor(elmetId)
    let comp = CJSVGImageView(
        Option<CustomView>.None,
        cssValue: ObservedProperty<String>("", cssValue),
        cjmodel: ObservedProperty<Option<CJSVGImageViewModel>>("", model)
    )
    CustomView.create(comp)
    ViewStackProcessor.StopGetAccessRecording()
    return ctx
        .function(
            {
                ctx1: JSContext, callInfo1: JSCallInfo =>
                let input = callInfo1[0].asString().toString()
                comp.updateCssValue(input)
                return ctx.undefined().toJSValue()
            }
        )
        .toJSValue()
}

var imageResource: ?OhosResource = None

public func getCJResource(ctx: JSContext, callInfo: JSCallInfo): JSValue {
    if (callInfo[0].typeof() != JSType.UNDEFINED) {
        imageResource = arktsRes2CJResource(ctx, callInfo[0])
    }
    return ctx.undefined().toJSValue()
}

func arktsRes2CJResource(ctx: JSContext, value: JSValue): OhosResource {
    let obj = value.asObject()
    OhosResource(
        String.fromJSValue(ctx, obj["bundleName"]),
        String.fromJSValue(ctx, obj["moduleName"]),
        Int32.fromJSValue(ctx, obj["id"]),
        params:[],
        resType: Int32.fromJSValue(ctx, obj["type"]),
    )
}
