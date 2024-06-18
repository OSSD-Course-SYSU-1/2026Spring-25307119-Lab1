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

import { window, router, Prompt } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { advertising, AdComponent } from '@kit.AdsKit';
import { AdStatus } from '../event/AdStatus';
import HiAdLog from '../log/HiAdLog';

const TAG = 'Ads Demo-PlacementAdPage';


@Entry
@Component
export struct PlacementAdPage {
  portrait: boolean = true;
  private ads: Array<advertising.Advertisement> = [];
  private displayOptions?: advertising.AdDisplayOptions;
  private adOptions?: advertising.AdOptions;
  // 用于渲染右上角倒计时
  private countDownTxtPlaceholder: string = '%d | %s';
  @State countDownTxt: string = '';

  aboutToAppear() {
    HiAdLog.i(TAG, `PlacementAdPage aboutToAppear`);
    const params: Record<string, Object> = router.getParams() as Record<string, Object>;
    if(params && params.ads as Array<advertising.Advertisement> && params.displayOptions as advertising.AdDisplayOptions) {
      this.ads = params.ads as Array<advertising.Advertisement>;
      this.displayOptions = params.displayOptions as advertising.AdDisplayOptions;
      this.adOptions = params.adOptions as advertising.AdOptions;
      this.initData();
    } else {
      HiAdLog.i(TAG, `empty router params`);
    }
  }

  build() {
    Stack({ alignContent: Alignment.TopEnd }) {
      AdComponent({ ads: this.ads, displayOptions: this.displayOptions,
        interactionListener: {
          onStatusChanged: (status: string, ad: advertising.Advertisement, data: string) => {
            switch (status) {
              case AdStatus.PORTRAIT:
                HiAdLog.i(TAG, `onPortrait`);
                Prompt.showToast({
                  message: 'placement ad onPortrait',
                  duration: 1000
                });
                this.setWindowPortrait();
                break;
              case AdStatus.LANDSCAPE:
                HiAdLog.i(TAG, `onLandscape`);
                Prompt.showToast({
                  message: 'placement ad onLandscape',
                  duration: 1000
                });
                this.setWindowLandscape();
                break;
              case AdStatus.VIP_CLICKED:
                HiAdLog.i(TAG, `onVipClicked`);
                Prompt.showToast({
                  message: 'placement ad onVipClicked',
                  duration: 1000
                });
                break;
              case AdStatus.MEDIA_PROGRESS:
                HiAdLog.i(TAG, `onMediaProgress, data: ${JSON.stringify(data)}`);
                Prompt.showToast({
                  message: 'placement ad onMediaProgress',
                  duration: 1000
                });
                break;
              case AdStatus.MEDIA_START:
                HiAdLog.i(TAG, `onMediaStart, data: ${JSON.stringify(data)}`);
                Prompt.showToast({
                  message: 'placement ad onMediaStart',
                  duration: 1000
                });
                break;
              case AdStatus.MEDIA_PAUSE:
                HiAdLog.i(TAG, `onMediaPause, data: ${JSON.stringify(data)}`);
                Prompt.showToast({
                  message: 'placement ad onMediaPause',
                  duration: 1000
                });
                break;
              case AdStatus.MEDIA_STOP:
                HiAdLog.i(TAG, `onMediaStop, data: ${JSON.stringify(data)}`);
                Prompt.showToast({
                  message: 'placement ad onMediaStop',
                  duration: 1000
                });
                break;
              case AdStatus.MEDIA_COMPLETE:
                HiAdLog.i(TAG, `onMediaComplete, data: ${JSON.stringify(data)}`);
                Prompt.showToast({
                  message: 'placement ad onMediaComplete',
                  duration: 1000
                });
                break;
              case AdStatus.MEDIA_ERROR:
                HiAdLog.i(TAG, `onMediaError, data: ${JSON.stringify(data)}`);
                Prompt.showToast({
                  message: 'placement ad onMediaError',
                  duration: 1000
                });
                break;
              case AdStatus.MEDIA_COUNTDOWN:
                try {
                  HiAdLog.i(TAG, `onMediaCountdown, data: ${JSON.stringify(data)}`);
                  const parseData: Record<string, number> = JSON.parse(JSON.stringify(data));
                  this.updateCountDownTxt(parseData.countdownTime);
                } catch(e) {
                  HiAdLog.e(TAG, `parse error code: ${e.code}, msg: ${e.message}`);
                }
                break;
            }
          } } })
        .width('100%')
        .height('100%')


      Row() {
        if (this.countDownTxt) {
          Text(this.countDownTxt.split('').join('\u200B'))
            .fontSize(12)
            .textAlign(TextAlign.Center)
            .maxLines(1)
            .fontColor(Color.White)
            .lineHeight(12)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .maxLines(1)
            .backgroundColor('#66000000')
            .border({ radius: 25 })
            .padding({ left: 8, right: 8, top: 6, bottom: 6 })
            .margin({ right: 16, top: 16 })
            .height(24)
            .constraintSize({ minWidth: 60, maxWidth: 100 })
            .onClick((event: ClickEvent) => {
              HiAdLog.i(TAG, 'onVipClicked, do something...');
            })
        }
      }
      .alignItems(VerticalAlign.Top)
      .justifyContent(FlexAlign.End)

    }.width('100%').height('100%')
  }

  /**
   * 设置竖屏
   */
  private setWindowPortrait() {
    HiAdLog.i(TAG, `setWindowPortrait, portrait: ${this.portrait}`);
    if (!this.portrait) {
      window.getLastWindow(getContext(this), (err: BusinessError, win)=>{
        win.setPreferredOrientation(window.Orientation.PORTRAIT);
      });
      this.portrait = true;
    } else {
      router.back();
    }
  }

  /**
   * 设置横屏（正向）
   */
  private setWindowLandscape() {
    HiAdLog.i(TAG, `setWindowLandscape, portrait: ${this.portrait}`);
    if (this.portrait) {
      window.getLastWindow(getContext(this), (err: BusinessError, win)=>{
        win.setPreferredOrientation(window.Orientation.LANDSCAPE);
      });
      this.portrait = false;
    }
  }

  private initData() {
    this.initCountDownText();
  }

  private initCountDownText() {
    const decodeText = this.decodeString(this.adOptions?.placementAdCountDownDesc as string);
    if (!this.isBlank(decodeText)) {
      this.countDownTxtPlaceholder = this.countDownTxtPlaceholder.replace('%s', decodeText);
    } else {
      this.countDownTxtPlaceholder = '%d';
    }
  }

  private updateCountDownTxt(leftTime: number) {
    HiAdLog.i(TAG, `showLeftTime: ${leftTime}`);
    this.countDownTxt = this.countDownTxtPlaceholder.replace('%d', leftTime + '');
  }

  private decodeString(str: string): string {
    if (!str) {
      return str;
    }

    let decodeUrl = str;
    try {
      // 防止空格被替换为+号导致解码失败
      decodeUrl = decodeURIComponent(str.replace(/\+/g, '%20'));
    } catch (e) {
      HiAdLog.e(TAG, `decodeURIComponent error code, ${e.code}, msg: ${e.message}`);
    }

    return decodeUrl;
  }

  private isBlank(str: string): boolean {
    if (str === null || str === undefined) {
      return true;
    }

    if (typeof str === "string") {
      return str.trim().length === 0;
    }
    return false;
  }
}