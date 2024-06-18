/*
 * Copyright 2023. Huawei Technologies Co., Ltd. All rights reserved.

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
 */

import { router, Prompt } from '@kit.ArkUI';
import { advertising, AdComponent } from '@kit.AdsKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'Ads Demo-SelfRenderAdPage';

@Entry
@Component
export struct SelfRenderAdPage {
  private ads: Array<advertising.Advertisement> = [];
  scroller: Scroller = new Scroller();
  private controller: VideoController | undefined;
  private adDisplayOptions: advertising.AdDisplayOptions = {
    // 是否静音，默认不静音
    mute: false,
  }

  aboutToAppear() {
    hilog.info(0x0000, TAG, '%{public}s', `SelfRenderAdPage aboutToAppear`);
    const params: Record<string, Object> = router.getParams() as Record<string, Object>;
    if(params && params.ads as Array<advertising.Advertisement> && params.displayOptions as advertising.AdDisplayOptions) {
      this.ads = params.ads as Array<advertising.Advertisement>;
      this.adDisplayOptions = params.displayOptions as advertising.AdDisplayOptions;
    } else {
      hilog.error(0x0000, TAG, '%{public}s', `empty router params`);
    }
  }

  @Builder
  componentBuilder() {
    Column() {
      Video({
        src: this.ads[0].video['url'],
        controller: this.controller,

      }).autoPlay(true)
        .width('90%')
        .height('90%')
    }
  }

  build() {
    Scroll(this.scroller) {
      Column({ space: 2 }) {
        Column() {
          Text(this.ads[0]?.title as string)
            .fontSize(16)
        }.width('90%')
        .alignItems(HorizontalAlign.Start)
        .margin({ left: '5%' })

        Column() {
          AdComponent({
            adRenderer: this.componentBuilder,
            ads: this.ads,
            displayOptions: this.adDisplayOptions,
            interactionListener: {
              onStatusChanged: (status: string, ad: advertising.Advertisement, data: string) => {
                switch (status) {
                  case "onAdClick":
                    hilog.info(0x0000, TAG, '%{public}s', `onAdClick`);
                    Prompt.showToast({
                      message: 'self render ad click',
                      duration: 1000
                    });
                    break;
                  default:
                    hilog.info(0x0000, TAG, `default`);
                }
              }
            }
          })
            .width('100%')
            .height('100%')

        }
        .height('35%')
        .width('100%')

        Row() {
          Column() {
            Row() {
              Text(this.ads[0]?.app?.['appName'])
                .fontSize(10)
                .fontColor("#66000000")
              Text("广告")
                .fontSize(10)
                .fontColor("#66000000")
                .margin({ left: 5 })
              Text("华为终端有限公司")
                .fontSize(10)
                .fontColor("#66000000")
                .margin({ left: 5 })
            }.justifyContent(FlexAlign.Start)

            Row() {
              Text(`版本${this.ads[0]?.app?.['versionName']}`)
                .fontSize(10)
                .fontColor("#66000000")
              Text("|")
                .fontSize(10)
                .fontColor("#66000000")
                .margin({ left: 5 })
              Text("介绍")
                .fontSize(10)
                .fontColor("#66000000")
                .margin({ left: 5 })
              Text("|")
                .fontSize(10)
                .fontColor("#66000000")
                .margin({ left: 5 })
              Text("隐私")
                .fontSize(10)
                .fontColor("#66000000")
                .margin({ left: 5 })
              Text("|")
                .fontSize(10)
                .fontColor("#66000000")
                .margin({ left: 5 })
              Text("权限")
                .fontSize(10)
                .fontColor("#66000000")
                .margin({ left: 5 })
            }.justifyContent(FlexAlign.Start)
          }.alignItems(HorizontalAlign.Start)

          Blank()
          Text("下载安装")
            .fontSize(13)
            .fontColor(Color.Blue)
          Text(":")
            .fontSize(13)
            .margin({ left: 10 })
        }.alignItems(VerticalAlign.Bottom)
        .width('90%')
        .margin({ left: '5%' })
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ top: '20%' })
      .width('100%')
      .height('100%')
    }.edgeEffect(EdgeEffect.Spring)
  }
}