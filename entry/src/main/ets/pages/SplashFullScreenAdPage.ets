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
import { AdStatus } from '../event/AdStatus';
import HiAdLog from '../log/HiAdLog';

const TAG = 'Ads Demo-SplashFullScreenAdPage';

@Entry
@Component
export struct SplashFullScreenAdPage {
  private ads: Array<advertising.Advertisement> = [];
  private displayOptions?: advertising.AdDisplayOptions;

  aboutToAppear() {
    HiAdLog.i(TAG, `SplashFullScreenAdPage aboutToAppear`);
    const params: Record<string, Object> = router.getParams() as Record<string, Object>;
    if (params && params.ads as Array<advertising.Advertisement> &&
      params.displayOptions as advertising.AdDisplayOptions) {
      this.ads = params.ads as Array<advertising.Advertisement>;
      this.displayOptions = params.displayOptions as advertising.AdDisplayOptions;
    } else {
      HiAdLog.i(TAG, `empty router params`);
    }
  }

  build() {
    Column() {
      AdComponent({
        ads: this.ads, displayOptions: this.displayOptions,
        interactionListener: {
          onStatusChanged: (status: string, ad: advertising.Advertisement, data: string) => {
            switch (status) {
              case AdStatus.AD_OPEN:
                HiAdLog.i(TAG, `onAdOpen`);
                Prompt.showToast({
                  message: 'splash ad open',
                  duration: 1000
                });
                break;
              case AdStatus.AD_CLICKED:
                HiAdLog.i(TAG, `onAdClick`);
                Prompt.showToast({
                  message: 'splash ad click',
                  duration: 1000
                });
                break;
              case AdStatus.AD_CLOSED:
                HiAdLog.i(TAG, `onAdClose`);
                Prompt.showToast({
                  message: 'splash ad close',
                  duration: 1000
                });
                router.replaceUrl({
                  url: 'pages/AdsServicePage',
                })
                break;
            }
          }
        }
      })
        .width('100%')
        .height('100%')
    }
    .width('100%')
    .height('100%')
  }
}
