/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */

package ohos_app_cangjie_entry

import ohos.state_macro_manage.*
internal import ohos.resource_manager.Resource as OhosResource

@Entry
@Component
class SetImageResourceSample {
    @State var model: SVGImageViewModel = SVGImageViewModel()

    func build() {
        Stack() {
            SVGImageView(model: getData())
        }
        .height(100.percent)
        .padding(top: 40)
        .margin(bottom: 20)
    }

    public func getData(): SVGImageViewModel {
        let resourceManager = ResourceManager.getResourceManager(getStageContext(globalAbilityContext.getOrThrow()))
        let res = @r(app.media.dog_cat)
        let resource = OhosResource("com.cangjie.svg4cj", "entry", Int32(res.id))

        this.model.setImageResource(resource, globalAbilityContext)
        return this.model
    }

}
