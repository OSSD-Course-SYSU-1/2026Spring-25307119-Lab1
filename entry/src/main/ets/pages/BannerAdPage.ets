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
import { advertising, AutoAdComponent } from '@kit.AdsKit';
import HiAdLog from '../log/HiAdLog';
import { AdStatus } from '../event/AdStatus';

const TAG = 'Ads Demo-BannerAdPage';

@Preview
@Entry
@Component
struct BannerAdPage {
  private adParam: advertising.AdRequestParams | undefined = undefined;
  private adOptions: advertising.AdOptions | undefined = undefined;
  private displayOptions: advertising.AdDisplayOptions | undefined = undefined;
  private ratio: number = 1;
  private adWidth: number = -1;
  private adHeight: number = -1;
  @State visibilityState: Visibility = Visibility.Visible;

  aboutToAppear() {
    HiAdLog.i(TAG, `aboutToAppear`);
    const params: Record<string, Object> = router.getParams() as Record<string, Object>;
    if (params && params.adRequestParams as advertising.AdRequestParams &&
      params.displayOptions as advertising.AdDisplayOptions && params.adOptions as advertising.AdOptions) {
      this.adParam = params.adRequestParams as advertising.AdRequestParams;
      this.displayOptions = params.displayOptions as advertising.AdDisplayOptions;
      this.adOptions = params.adOptions as advertising.AdOptions;
    } else {
      HiAdLog.i(TAG, `empty router params`);
    }

    if (this.adParam?.adWidth && typeof (this.adParam?.adWidth) == 'number' && this.adParam?.adWidth > 0) {
      this.adWidth = this.adParam?.adWidth;
    }
    HiAdLog.i(TAG, `adWidth :${this.adWidth}`);
    if (this.adParam?.adHeight && typeof (this.adParam?.adHeight) == 'number' && this.adParam?.adHeight > 0) {
      this.adHeight = this.adParam?.adHeight;
    }
    HiAdLog.i(TAG, `adHeight :${this.adHeight}`);

    if (this.adWidth > 0 && this.adHeight > 0) {
      this.ratio = this.adWidth / this.adHeight;
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      this.buildImageView();
      this.buildBannerView();
    }
  }

  @Builder
  buildImageView() {
    Image($r('app.media.banner_background'))
      .objectFit(ImageFit.Cover)
      .onError(() => {
        HiAdLog.e(TAG, `buildImageView image load error`);
      })
      .onComplete(() => {
        HiAdLog.i(TAG, `buildImageView image load complete`);
      })
  }

  @Builder
  buildBannerView() {
    Row() {
      AutoAdComponent({
        adParam: this.adParam,
        adOptions: this.adOptions,
        displayOptions: this.displayOptions,
        interactionListener: {
          onStatusChanged: (status: string, ad: advertising.Advertisement, data: string) => {
            HiAdLog.i(TAG, `status is ${status}`);
            switch (status) {
              case AdStatus.AD_OPEN:
                HiAdLog.i(TAG, `onAdOpen`);
                Prompt.showToast({
                  message: 'banner ad open',
                  duration: 1000
                });
                break;
              case AdStatus.AD_CLICKED:
                HiAdLog.i(TAG, `onAdClick`);
                Prompt.showToast({
                  message: 'banner ad click',
                  duration: 1000
                });
                break;
              case AdStatus.AD_CLOSED:
                HiAdLog.i(TAG, `onAdClose`);
                this.visibilityState = Visibility.None;
                Prompt.showToast({
                  message: 'banner ad close',
                  duration: 1000
                });
                break;
              case AdStatus.AD_LOAD:
                HiAdLog.i(TAG, `onAdLoad`);
                Prompt.showToast({
                  message: 'banner ad load',
                  duration: 1000
                });
                break;
              case AdStatus.AD_FAIL:
                HiAdLog.i(TAG, `onAdFail`);
                this.visibilityState = Visibility.None;
                Prompt.showToast({
                  message: 'banner ad fail',
                  duration: 1000
                });
                break;
            }
          }
        }
      })
    }
    .width('100%')
    .aspectRatio(this.ratio)
    .padding({ bottom: 5 })
    .visibility(this.visibilityState)
  }
}
