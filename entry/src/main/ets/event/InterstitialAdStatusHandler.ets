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

import { commonEventManager, BusinessError } from '@kit.BasicServicesKit';
import HiAdLog from '../log/HiAdLog';
import { AdStatus } from './AdStatus';

const KEY_INTERSTITIAL_STATUS = 'interstitial_ad_status';
const TAG = 'Ads Demo-InterstitialAdStatusHandler';

export class InterstitialAdStatusHandler {
  // Used to save the created subscriber object for subsequent subscription and unsubscription.
  private subscriber: commonEventManager.CommonEventSubscriber | null = null;

  // Subscription method, which must be called each time before an ad is displayed.
  public registerPPSReceiver(): void {
    if (this.subscriber) {
      this.unRegisterPPSReceiver();
    }
    // Subscriber information.
    const subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
      events: ['com.huawei.hms.pps.action.PPS_INTERSTITIAL_STATUS_CHANGED'],
      publisherBundleName: 'com.huawei.hms.adsservice'
    };
    // Callback for subscriber creation.
    commonEventManager.createSubscriber(subscribeInfo,
      (err: BusinessError, commonEventSubscriber: commonEventManager.CommonEventSubscriber) => {
        if (err) {
          HiAdLog.e(TAG, `Failed to create subscriber, errorCode: ${err.code}, errorMsg: ${err.message}`);
          return;
        }
        HiAdLog.i(TAG, 'Succeeded in creating subscriber');
        this.subscriber = commonEventSubscriber;
        // Callback for common event subscription.
        if (!this.subscriber) {
          HiAdLog.i(TAG, `need create subscriber`);
          return;
        }
        commonEventManager.subscribe(this.subscriber,
          (err: BusinessError, commonEventData: commonEventManager.CommonEventData) => {
            if (err) {
              HiAdLog.e(TAG, `subscribe error, errorCode: ${err.code}, errorMsg: ${err.message}`);
            } else {
              // The subscriber receives the common event.
              HiAdLog.i(TAG, 'subscribe data');
              // Obtain the status change of the interstitial ad page.
              const status: string = commonEventData?.parameters?.[KEY_INTERSTITIAL_STATUS];
              switch (status) {
                case AdStatus.AD_OPEN:
                  HiAdLog.i(TAG, `onAdOpen`);
                  break;
                case AdStatus.AD_CLICKED:
                  HiAdLog.i(TAG, `onAdClick`);
                  break;
                case AdStatus.AD_CLOSED:
                  HiAdLog.i(TAG, `onAdClose`);
                  this.unRegisterPPSReceiver();
                  break;
                case AdStatus.AD_VIDEO_START:
                  HiAdLog.i(TAG, `onAdVideoStart`);
                  break;
                case AdStatus.AD_COMPLETED:
                  HiAdLog.i(TAG, `onAdCompleted`);
                  break;
                default:
                  break;
              }
            }
          });
      });
  }

  // Cancel the subscription.
  public unRegisterPPSReceiver(): void {
    commonEventManager.unsubscribe(this.subscriber, (err: BusinessError) => {
      if (err) {
        HiAdLog.e(TAG, `Failed to unsubscribe, errorCode: ${err.code}, errorMsg: ${err.message}`);
      } else {
        HiAdLog.i(TAG, `Succeeded in unsubscribing`);
        this.subscriber = null;
      }
    });
  }
}
