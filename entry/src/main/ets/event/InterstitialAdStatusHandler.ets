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
  // 用于保存创建成功的订阅者对象，后续使用其完成订阅及退订的动作
  private subscriber: commonEventManager.CommonEventSubscriber | null = null;

  // 订阅方法，需要在每次展示广告前调用
  public registerPPSReceiver(): void {
    if (this.subscriber) {
      this.unRegisterPPSReceiver();
    }
    // 订阅者信息
    const subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
      events: ['com.huawei.hms.pps.action.PPS_INTERSTITIAL_STATUS_CHANGED'],
      publisherBundleName:"com.huawei.hms.adsservice",
    };
    // 创建订阅者回调
    commonEventManager.createSubscriber(subscribeInfo, (err: BusinessError, commonEventSubscriber: commonEventManager.CommonEventSubscriber) => {
      if (err) {
        HiAdLog.i(TAG, `createSubscriber error, ${JSON.stringify(err)}`);
        return;
      }
      HiAdLog.i(TAG, `succeeded in creating subscriber`);
      this.subscriber = commonEventSubscriber;
      // 订阅公共事件回调
      if (!this.subscriber) {
        HiAdLog.i(TAG, `need create subscriber`);
        return;
      }
      commonEventManager.subscribe(this.subscriber, (err: BusinessError, commonEventData: commonEventManager.CommonEventData) => {
        if (err) {
          HiAdLog.e(TAG, `subscribe error, ${JSON.stringify(err)}`);
        } else {
          // 订阅者成功接收到公共事件
          HiAdLog.i(TAG, `subscribe data, ${JSON.stringify(commonEventData)}`);
          // 获取插屏广告页面变化状态
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

  // 取消订阅
  public unRegisterPPSReceiver(): void {
    commonEventManager.unsubscribe(this.subscriber, (err: BusinessError) => {
      if (err) {
        HiAdLog.e(TAG, `unsubscribe error, ${JSON.stringify(err)}`);
      } else {
        HiAdLog.i(TAG, `succeeded in unsubscribing`);
        this.subscriber = null;
      }
    });
  }
}
