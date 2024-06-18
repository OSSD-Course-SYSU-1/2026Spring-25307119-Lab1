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
import { Prompt } from '@kit.ArkUI';
import HiAdLog from '../log/HiAdLog';
import { AdStatus } from './AdStatus';

const KEY_REWARD_DATA = "reward_ad_data";
const KEY_REWARD_STATUS = "reward_ad_status";
const TAG = 'Ads Demo-RewardAdStatusHandler';

export class RewardAdStatusHandler {
  // 用于保存创建成功的订阅者对象，后续使用其完成订阅及退订的动作
  private subscriber: commonEventManager.CommonEventSubscriber | null = null;

  public registerPPSReceiver(): void {
    if (this.subscriber) {
      this.unRegisterPPSReceiver();
    }
    // 订阅者信息
    const subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
      events: ["com.huawei.hms.pps.action.PPS_REWARD_STATUS_CHANGED"],
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
          HiAdLog.i(TAG, `subscribe data, ${JSON.stringify(commonEventData)}`);
          const status: string = commonEventData?.parameters?.[KEY_REWARD_STATUS];
          switch (status) {
            case AdStatus.AD_OPEN:
              HiAdLog.i(TAG, `onAdOpen`);
              Prompt.showToast({
                message: 'reward ad open',
                duration: 1000
              });
              break;
            case AdStatus.AD_CLICKED:
              HiAdLog.i(TAG, `onAdClick`);
              Prompt.showToast({
                message: 'reward ad click',
                duration: 1000
              });
              break;
            case AdStatus.AD_CLOSED:
              HiAdLog.i(TAG, `onAdClose`);
              Prompt.showToast({
                message: 'reward ad close',
                duration: 1000
              });
              this.unRegisterPPSReceiver();
              break;
            case AdStatus.AD_REWARDED:
              const rewardData: Record<string, string | number> = commonEventData?.parameters?.[KEY_REWARD_DATA];
              const rewardType: string = rewardData?.rewardType as string;
              const rewardAmount: number = rewardData?.rewardAmount as number;
              HiAdLog.i(TAG, `onAdReward, rewardType: ${rewardType}, rewardAmount: ${rewardAmount}`);
              Prompt.showToast({
                message: `reward ad reward, rewardType: ${rewardType}, rewardAmount: ${rewardAmount}`,
                duration: 1000
              });
              break;
            case AdStatus.AD_VIDEO_START:
              HiAdLog.i(TAG, `onAdVideoStart`);
              Prompt.showToast({
                message: 'reward ad video start',
                duration: 1000
              });
              break;
            case AdStatus.AD_COMPLETED:
              HiAdLog.i(TAG, `onAdCompleted`);
              Prompt.showToast({
                message: 'reward ad completed',
                duration: 1000
              });
              break;
            default:
              break;
          }
        }
      });
    });
  }

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