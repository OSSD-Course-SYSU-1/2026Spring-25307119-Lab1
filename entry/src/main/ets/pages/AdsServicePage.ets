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
import { advertising, identifier } from '@kit.AdsKit';
import { common, abilityAccessCtrl } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import HiAdLog from '../log/HiAdLog';
import { ActionBar } from '../widgets/action-bar';
import { CustomButton } from '../widgets/custom-button';
import { RewardAdStatusHandler } from '../event/RewardAdStatusHandler';
import { InterstitialAdStatusHandler } from '../event/InterstitialAdStatusHandler';
import { AdType } from '../constant/AdType';

const TAG = 'Ads Demo-LoadAd';

/**
 * Demo UI of Petal Ads Publisher Service.
 */
@Entry
@Component
export struct LoadAd {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  private scroller: Scroller = new Scroller();
  private oaid: string = '';
  // Ad display parameters.
  private adDisplayOptions: advertising.AdDisplayOptions = {
    // Whether to mute the ad. By default, the ad is not muted.
    mute: false
  }
  // Ad configuration.
  private adOptions: advertising.AdOptions = {
    // Whether to allow ad asset download through mobile data. 0: no; 1: yes. If this parameter is not set, the advertiser's setting will be used.
    allowMobileTraffic: 0,
    // Whether you want your ad content to be treated as child-directed according to the regulations of COPPA. -1 (default value): uncertain; 0: no; 1: yes.
    tagForChildProtection: -1,
    // Whether you want the ad request to be processed in a way that is suitable for users in the European Economic Area (EEA) who are below the legal age of consent. -1 (default value): uncertain; 0: no; 1: yes.
    tagForUnderAgeOfPromise: -1,
    // Maximum ad content rating. W: aged 3 and up; PI: aged 7 and up, under parental guidance; J: teenagers aged 12 and up; A: adults aged 16 or 18 and up.
    adContentClassification: 'A'
  }
  // Roll ad configuration.
  private adOptionsPlacementAd: advertising.AdOptions = {
    // Set the roll ad display duration.
    totalDuration: 30,
    // Set the roll ad countdown text.
    placementAdCountDownDesc: encodeURI(this.context.resourceManager.getStringSync($r('app.string.ad_free_for_VIP_members')
      .id)),
    // Whether to allow ad asset download through mobile data. 0: no; 1: yes. If this parameter is not set, the advertiser's setting will be used.
    allowMobileTraffic: 0,
    // Whether you want your ad content to be treated as child-directed according to the regulations of COPPA. -1 (default value): uncertain; 0: no; 1: yes.
    tagForChildProtection: -1,
    // Whether you want the ad request to be processed in a way that is suitable for users in the European Economic Area (EEA) who are below the legal age of consent. -1 (default value): uncertain; 0: no; 1: yes.
    tagForUnderAgeOfPromise: -1,
    // Maximum ad content rating. W: aged 3 and up; PI: aged 7 and up, under parental guidance; J: teenagers aged 12 and up; A: adults aged 16 or 18 and up.
    adContentClassification: 'A'
  }
  // Rewarded ad request parameters.
  private rewardAdReqParams: advertising.AdRequestParams = {
    adId: 'testx9dtjwj8hp',
    adType: AdType.REWARD_AD,
    adCount: 1
  }
  // Native video ad request parameters.
  private nativeVideoAdReqParams: advertising.AdRequestParams = {
    adId: 'testy63txaom86',
    adType: AdType.NATIVE_AD,
    adCount: 1,
    // Custom parameters of native ads. A callback is triggered after all ad assets are downloaded.
    enableDirectReturnVideoAd: true
  }
  // Native large-image ad request parameters.
  private nativeBigImageAdReqParams: advertising.AdRequestParams = {
    adId: 'testu7m3hc4gvm',
    adType: AdType.NATIVE_AD,
    adCount: 1,
    // Custom parameters of native ads. A callback is triggered after all ad assets are downloaded.
    enableDirectReturnVideoAd: true
  }
  // Native three-image ad request parameters.
  private nativeThreeImageAdReqParams: advertising.AdRequestParams = {
    adId: 'testr6w14o0hqz',
    adType: AdType.NATIVE_AD,
    adCount: 1,
    // Custom parameters of native ads. A callback is triggered after all ad assets are downloaded.
    enableDirectReturnVideoAd: true
  }
  // Native small-image ad request parameters.
  private nativeSmallImageAdReqParams: advertising.AdRequestParams = {
    adId: 'testb65czjivt9',
    adType: AdType.NATIVE_AD,
    adCount: 1,
    // Custom parameters of native ads. A callback is triggered after all ad assets are downloaded.
    enableDirectReturnVideoAd: true
  }
  // Splash video ad request parameters.
  private splashVideoAdReqParams: advertising.AdRequestParams = {
    adId: 'testd7c5cewoj6',
    adType: AdType.SPLASH_AD,
    adCount: 1
  }
  // Splash image ad request parameters.
  private splashImageAdReqParams: advertising.AdRequestParams = {
    adId: 'testq6zq98hecj',
    adType: AdType.SPLASH_AD,
    adCount: 1
  }
  // Roll ad request parameters.
  private placementAdReqParams: advertising.AdRequestParams = {
    adId: 'testy3cglm3pj0',
    adType: AdType.PLACEMENT_AD,
    adCount: 1
  }
  // Interstitial video ad request parameters.
  private interstitialVideoAdReqParams: advertising.AdRequestParams = {
    adId: 'testb4znbuh3n2',
    adType: AdType.INTERSTITIAL_AD,
    adCount: 1
  }
  // Interstitial image ad request parameters.
  private interstitialImageAdReqParams: advertising.AdRequestParams = {
    adId: 'teste9ih9j0rc3',
    adType: AdType.INTERSTITIAL_AD,
    adCount: 1
  }
  // Banner ad request parameters.
  private bannerAdReqParams: advertising.AdRequestParams = {
    adId: 'testw6vs28auh3',
    adType: AdType.BANNER_AD,
    adCount: 1,
    adWidth: 360,
    adHeight: 57
  }

  aboutToAppear() {
    HiAdLog.i(TAG, 'Start to aboutToAppear');
    try {
      // Obtain the OAID through a promise callback.
      this.requestOAIDTrackingConsentPermissions(this.context);
    } catch (error) {
      HiAdLog.e(TAG, `Catch err, code: ${error.code}, message: ${error.message}`);
    }
  }

  build() {
    Column() {
      ActionBar({ title: $r('app.string.ads_demo_title') }).height('10%')
      Scroll(this.scroller) {
        Column() {
          // Redirect to the rewarded ad display page.
          CustomButton({
            mText: $r('app.string.request_reward_ad_btn'), mOnClick: () => {
              this.requestAd(this.rewardAdReqParams, this.adOptions);
            }
          });

          // Redirect to the native video ad display page.
          CustomButton({
            mText: $r('app.string.request_native_video_ad_btn'), mOnClick: () => {
              this.requestAd(this.nativeVideoAdReqParams, this.adOptions);
            }
          });

          // Redirect to the native large-image ad display page.
          CustomButton({
            mText: $r('app.string.request_native_big_image_ad_btn'), mOnClick: () => {
              this.requestAd(this.nativeBigImageAdReqParams, this.adOptions);
            }
          });

          // Redirect to the native small-image ad display page.
          CustomButton({
            mText: $r('app.string.request_native_small_image_ad_btn'), mOnClick: () => {
              this.requestAd(this.nativeSmallImageAdReqParams, this.adOptions);
            }
          });

          // Redirect to the native three-image ad display page.
          CustomButton({
            mText: $r('app.string.request_native_three_image_ad_btn'), mOnClick: () => {
              this.requestAd(this.nativeThreeImageAdReqParams, this.adOptions);
            }
          });

          // Redirect to the splash video ad display page.
          CustomButton({
            mText: $r('app.string.request_splash_video_ad_btn'), mOnClick: () => {
              this.requestAd(this.splashVideoAdReqParams, this.adOptions);
            }
          });

          // Redirect to the splash image ad display page.
          CustomButton({
            mText: $r('app.string.request_splash_image_ad_btn'), mOnClick: () => {
              this.requestAd(this.splashImageAdReqParams, this.adOptions);
            }
          });

          // Redirect to the roll ad display page.
          CustomButton({
            mText: $r('app.string.request_placement_ad_btn'), mOnClick: () => {
              this.requestAd(this.placementAdReqParams, this.adOptionsPlacementAd as advertising.AdOptions);
            }
          });

          // Redirect to the interstitial video ad display page.
          CustomButton({
            mText: $r('app.string.request_interstitial_video_ad_btn'), mOnClick: () => {
              this.requestAd(this.interstitialVideoAdReqParams, this.adOptions);
            }
          });

          // Redirect to the interstitial image ad display page.
          CustomButton({
            mText: $r('app.string.request_interstitial_image_ad_btn'), mOnClick: () => {
              this.requestAd(this.interstitialImageAdReqParams, this.adOptions);
            }
          });

          // Redirect to the banner ad display page.
          CustomButton({
            mText: $r('app.string.request_banner_ad_btn'), mOnClick: () => {
              routePageWithoutAds('pages/BannerAdPage', this.oaid, this.bannerAdReqParams, this.adDisplayOptions,
                this.adOptions);
            }
          });

        }.width('100%').justifyContent(FlexAlign.Center)
      }.scrollable(ScrollDirection.Vertical)
      .height('90%')
    }
    .width('100%')
    .height('100%')
  }

  private requestAd(adReqParams: advertising.AdRequestParams, adOptions: advertising.AdOptions): void {
    // Set the oaid parameter for AdRequestParams.
    adReqParams.oaid = this.oaid;
    // Ad request callback listener.
    const adLoaderListener: advertising.AdLoadListener = {
      // Called when an ad request fails.
      onAdLoadFailure: (errorCode: number, errorMsg: string) => {
        HiAdLog.e(TAG, `Failed to request ad, errorCode is: ${errorCode}, errorMsg is: ${errorMsg}`);
        Prompt.showToast({
          message: `Failed to request ad, errorCode is:  ${errorCode} , errorMsg is: ${errorMsg}`,
          duration: 1000
        });
      },
      // Called upon ad request success.
      onAdLoadSuccess: (ads: Array<advertising.Advertisement>) => {
        HiAdLog.i(TAG, 'Succeeded in requesting ad!');
        // Save the requested ad content for display.
        HiAdLog.i(TAG, `ads[0].adType is : ${ads[0].adType}`);
        if (canIUse('SystemCapability.Advertising.Ads')) {
          if (ads[0].adType === AdType.REWARD_AD) {
            // Register a status listener for rewarded ads to monitor their playback status.
            new RewardAdStatusHandler().registerPPSReceiver();
            // Call the API for displaying ads.
            advertising.showAd(ads[0], this.adDisplayOptions, this.context);
          } else if (ads[0].adType === AdType.NATIVE_AD) {
            // Call the native ad display page.
            routePage('pages/NativeAdPage', ads, this.adDisplayOptions);
          } else if (ads[0].adType === AdType.SPLASH_AD) {
            // Call the splash ad display page.
            if (ads[0]?.isFullScreen === true) {
              routePage('pages/SplashFullScreenAdPage', ads, this.adDisplayOptions);
            } else {
              routePage('pages/SplashHalfScreenAdPage', ads, this.adDisplayOptions);
            }
          } else if (ads[0].adType === AdType.PLACEMENT_AD) {
            // Call the roll ad display page.
            routePage('pages/PlacementAdPage', ads, this.adDisplayOptions, this.adOptionsPlacementAd);
          } else if (ads[0].adType === AdType.INTERSTITIAL_AD) {
            // Register a status listener for interstitial ads to monitor their playback status.
            new InterstitialAdStatusHandler().registerPPSReceiver();
            // Call the API for displaying ads.
            advertising.showAd(ads[0], this.adDisplayOptions, this.context);
          } else {
            HiAdLog.w(TAG, 'error adType');
          }
        }
      }
    };
    // Create an AdLoader ad object.
    const load: advertising.AdLoader = new advertising.AdLoader(this.context);
    // Call the API for requesting ads.
    HiAdLog.i(TAG, 'request ad!');
    load.loadAd(adReqParams, adOptions, adLoaderListener);
  }

  private requestOAIDTrackingConsentPermissions(context: common.Context): void {
    // Request Activity tracking for this app from users when they access a page.
    const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    try {
      atManager.requestPermissionsFromUser(context, ['ohos.permission.APP_TRACKING_CONSENT']).then((data) => {
        if (data.authResults[0] == 0) {
          HiAdLog.i(TAG, 'Succeeded in requesting permission');
          identifier.getOAID().then((data: string) => {
            this.oaid = data;
            HiAdLog.i(TAG, 'Succeeded in getting adsIdentifierInfo by promise');
          }).catch((error: BusinessError) => {
            HiAdLog.e(TAG, `Failed to get adsIdentifierInfo, errorCode: ${error.code}, errorMsg: ${error.message}`);
          })
        } else {
          HiAdLog.i(TAG, 'user rejected');
        }
      }).catch((err: BusinessError) => {
        HiAdLog.e(TAG, `Failed to request permission, errorCode: ${err.code}, errorMsg: ${err.message}`);
      })
    } catch (err) {
      HiAdLog.e(TAG, `catch err, errorCode: ${err.code}, errorMsg: ${err.message}`);
    }
  }
}

async function routePage(pageUri: string, ads: Array<advertising.Advertisement | null>,
  displayOptions: advertising.AdDisplayOptions, adOptions?: advertising.AdOptions) {
  let options: router.RouterOptions = {
    url: pageUri,
    params: {
      ads: ads,
      displayOptions: displayOptions,
      adOptions: adOptions
    }
  }
  try {
    HiAdLog.i(TAG, `routePage  + ${pageUri}`);
    router.pushUrl(options);
  } catch (error) {
    HiAdLog.e(TAG, `Failed to routePage callback, errorCode: ${error.code}, errorMsg: ${error.message}`);
  }
}

async function routePageWithoutAds(pageUri: string, oaid: string, adRequestParams: advertising.AdRequestParams,
  displayOptions: advertising.AdDisplayOptions, adOptions: advertising.AdOptions) {
  // Set the oaid parameter for AdRequestParams.
  adRequestParams.oaid = oaid;
  let options: router.RouterOptions = {
    url: pageUri,
    params: {
      adRequestParams: adRequestParams,
      displayOptions: displayOptions,
      adOptions: adOptions
    }
  }
  try {
    HiAdLog.i(TAG, `routePage  + ${pageUri}`);
    router.pushUrl(options);
  } catch (error) {
    HiAdLog.e(TAG, `Failed to routePage callback, errorCode: ${error.code}, errorMsg: ${error.message}`);
  }
}
