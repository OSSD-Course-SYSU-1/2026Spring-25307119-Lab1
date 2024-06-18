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
 * 流量变现服务演示页面
 */
@Entry
@Component
export struct LoadAd {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  private scroller: Scroller = new Scroller();
  private oaid: string = '';
  // 广告展示参数
  private adDisplayOptions: advertising.AdDisplayOptions = {
    // 是否静音，默认不静音
    mute: false,
  }
  // 广告配置
  private adOptions: advertising.AdOptions = {
    // 是否允许流量下载  0不允许 1允许，不设置以广告主设置为准
    allowMobileTraffic: 0,
    // 是否希望根据 COPPA 的规定将您的内容视为面向儿童的内容，: -1默认值，不确定 0不希望 1希望
    tagForChildProtection: -1,
    // 是否希望按适合未达到法定承诺年龄的欧洲经济区 (EEA) 用户的方式处理该广告请求 -1默认值，不确定 0不希望 1希望
    tagForUnderAgeOfPromise: -1,
    // 设置广告内容分级上限: W: 3+,所有受众 PI: 7+,家长指导 J:12+,青少年 A: 16+/18+，成人受众
    adContentClassification: 'A',
  }
  // 贴片广告配置
  private adOptionsPlacementAd: advertising.AdOptions = {
    totalDuration: 30,
    placementAdCountDownDesc: encodeURI('VIP免广告'),
    // 是否允许流量下载  0不允许 1允许，不设置以广告主设置为准
	  allowMobileTraffic: 0,
    // 是否希望根据 COPPA 的规定将您的内容视为面向儿童的内容，: -1默认值，不确定 0不希望 1希望
    tagForChildProtection: -1,
    // 是否希望按适合未达到法定承诺年龄的欧洲经济区 (EEA) 用户的方式处理该广告请求 -1默认值，不确定 0不希望 1希望
    tagForUnderAgeOfPromise: -1,
    // 设置广告内容分级上限: W: 3+,所有受众 PI: 7+,家长指导 J:12+,青少年 A: 16+/18+，成人受众
    adContentClassification: 'A',
  }
  // 激励广告请求参数
  private rewardAdReqParams: advertising.AdRequestParams = {
    adId: 'testx9dtjwj8hp',
    adType: AdType.REWARD_AD,
    adCount: 1,
  }
  // 原生视频广告请求参数
  private nativeVideoAdReqParams: advertising.AdRequestParams = {
    adId: 'testy63txaom86',
    adType: AdType.NATIVE_AD,
    adCount: 1,
    // 原生广告自定义扩展参数。等所有广告素材下载完后再回调
    enableDirectReturnVideoAd: true,
  }
  // 原生大图广告请求参数
  private nativeBigImageAdReqParams: advertising.AdRequestParams = {
    adId: 'testu7m3hc4gvm',
    adType: AdType.NATIVE_AD,
    adCount: 1,
    // 原生广告自定义扩展参数。等所有广告素材下载完后再回调
    enableDirectReturnVideoAd: true,
  }
  // 原生三图广告请求参数
  private nativeThreeImageAdReqParams: advertising.AdRequestParams = {
    adId: 'testr6w14o0hqz',
    adType: AdType.NATIVE_AD,
    adCount: 1,
    // 原生广告自定义扩展参数。等所有广告素材下载完后再回调
    enableDirectReturnVideoAd: true,
  }
  // 原生小图广告请求参数
  private nativeSmallImageAdReqParams: advertising.AdRequestParams = {
    adId: 'testb65czjivt9',
    adType: AdType.NATIVE_AD,
    adCount: 1,
    // 原生广告自定义扩展参数。等所有广告素材下载完后再回调
    enableDirectReturnVideoAd: true,
  }
  // 原生媒体自渲染广告请求参数
  private nativeSelfRenderAdReqParams: advertising.AdRequestParams = {
    adId: 'testy63txaom86',
    adType: AdType.NATIVE_AD,
    adCount: 1,
    // 原生广告自定义扩展参数。等所有广告素材下载完后再回调
    enableDirectReturnVideoAd: true,
    // 原生广告自定义扩展参数。返回原生广告创意元数据给三方媒体开发者。
    needSelfRendering: true,
  }
  // 开屏视频广告请求参数
  private splashVideoAdReqParams: advertising.AdRequestParams = {
    adId: 'testd7c5cewoj6',
    adType: AdType.SPLASH_AD,
    adCount: 1,
  }
  // 开屏图片广告请求参数
  private splashImageAdReqParams: advertising.AdRequestParams = {
    adId: 'testq6zq98hecj',
    adType: AdType.SPLASH_AD,
    adCount: 1,
  }
  // 贴片广告请求参数
  private placementAdReqParams: advertising.AdRequestParams = {
    adId: 'testy3cglm3pj0',
    adType: AdType.PLACEMENT_AD,
    adCount: 1,
  }
  // 插屏视频广告请求参数
  private interstitialVideoAdReqParams: advertising.AdRequestParams = {
    adId: 'testb4znbuh3n2',
    adType: AdType.INTERSTITIAL_AD,
    adCount: 1,
  }
  // 插屏图片广告请求参数
  private interstitialImageAdReqParams: advertising.AdRequestParams = {
    adId: 'teste9ih9j0rc3',
    adType: AdType.INTERSTITIAL_AD,
    adCount: 1,
  }
  // Banner广告请求参数
  private bannerAdReqParams: advertising.AdRequestParams = {
    adId: 'testw6vs28auh3',
    adType: AdType.BANNER_AD,
    adCount: 1,
    adWidth: 360,
    adHeight: 57,
  }

  aboutToAppear() {
    try {
      // 使用Promise回调方式获取OAID
      this.requestOAIDTrackingConsentPermissions(this.context);
    } catch (error) {
      HiAdLog.e(TAG, `catch err->${JSON.stringify(error)}`);
    }
    HiAdLog.i(TAG, 'aboutToAppear');
  }

  build() {
    Column() {
      ActionBar({ title: $r("app.string.ads_demo_title") }).height('10%')
      Scroll(this.scroller) {
        Column() {
          // 跳转到激励广告展示页面
          CustomButton({
            mText: $r("app.string.request_reward_ad_btn"), mOnClick: () => {
              this.requestAd(this.rewardAdReqParams, this.adOptions);
            }
          });

          // 跳转到原生视频广告展示页面
          CustomButton({
            mText: $r("app.string.request_native_video_ad_btn"), mOnClick: () => {
              this.requestAd(this.nativeVideoAdReqParams, this.adOptions);
            }
          });

          // 跳转到原生大图广告展示页面
          CustomButton({
            mText: $r("app.string.request_native_big_image_ad_btn"), mOnClick: () => {
              this.requestAd(this.nativeBigImageAdReqParams, this.adOptions);
            }
          });

          // 跳转到原生小图广告展示页面
          CustomButton({
            mText: $r("app.string.request_native_small_image_ad_btn"), mOnClick: () => {
              this.requestAd(this.nativeSmallImageAdReqParams, this.adOptions);
            }
          });

          // 跳转到原生三图广告展示页面
          CustomButton({
            mText: $r("app.string.request_native_three_image_ad_btn"), mOnClick: () => {
              this.requestAd(this.nativeThreeImageAdReqParams, this.adOptions);
            }
          });

          // 跳转到原生媒体自渲染广告展示页面
          CustomButton({
            mText: $r("app.string.request_native_self_render_ad_btn"), mOnClick: () => {
              this.requestAd(this.nativeSelfRenderAdReqParams, this.adOptions);
            }
          });

          // 跳转到开屏视频广告展示页面
          CustomButton({
            mText: $r("app.string.request_splash_video_ad_btn"), mOnClick: () => {
              this.requestAd(this.splashVideoAdReqParams, this.adOptions);
            }
          });

          // 跳转到开屏图片广告展示页面
          CustomButton({
            mText: $r("app.string.request_splash_image_ad_btn"), mOnClick: () => {
              this.requestAd(this.splashImageAdReqParams, this.adOptions);
            }
          });

          // 跳转到贴片广告展示页面
          CustomButton({
            mText: $r("app.string.request_placement_ad_btn"), mOnClick: () => {
              this.requestAd(this.placementAdReqParams, this.adOptionsPlacementAd as advertising.AdOptions);
            }
          });

          // 跳转到插屏视频广告展示页面
          CustomButton({
            mText: $r("app.string.request_interstitial_video_ad_btn"), mOnClick: () => {
              this.requestAd(this.interstitialVideoAdReqParams, this.adOptions);
            }
          });

          // 跳转到插屏图片广告展示页面
          CustomButton({
            mText: $r("app.string.request_interstitial_image_ad_btn"), mOnClick: () => {
              this.requestAd(this.interstitialImageAdReqParams, this.adOptions);
            }
          });

          // 跳转到Banner广告展示页面
          CustomButton({
            mText: $r("app.string.request_banner_ad_btn"), mOnClick: () => {
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
    // 给AdRequestParams设置oaid参数
    adReqParams.oaid = this.oaid;
    // 广告请求回调监听
    const adLoaderListener: advertising.AdLoadListener = {
      // 广告请求失败回调
      onAdLoadFailure: (errorCode: number, errorMsg: string) => {
        HiAdLog.i(TAG, `request ad errorCode is: ${errorCode}, errorMsg is: ${errorMsg}`);
        Prompt.showToast({
          message: 'request ad failed, code is: ' + errorCode + 'message is: ' + errorMsg,
          duration: 1000
        });
      },
      // 广告请求成功回调
      onAdLoadSuccess: (ads: Array<advertising.Advertisement>) => {
        HiAdLog.i(TAG, "succeeded in requesting ad!");
        // 保存请求到的广告内容用于展示
        HiAdLog.i(TAG, `ads[0].adType is : ${JSON.stringify(ads[0])}`);
        if (canIUse("SystemCapability.Advertising.Ads")) {
          if (ads[0].adType === AdType.REWARD_AD) {
            // 注册激励广告状态监听器，用于监听激励广告播放状态
            new RewardAdStatusHandler().registerPPSReceiver();
            // 调用广告展示接口
            advertising.showAd(ads[0], this.adDisplayOptions, this.context);
          } else if (ads[0].adType === AdType.NATIVE_AD) {
            if (!ads[0].canSelfRendering) {
              // 调用原生广告展示页面
              routePage('pages/NativeAdPage', ads, this.adDisplayOptions);
            } else {
              // 调用原生广告自渲染页面
              routePage('pages/SelfRenderAdPage', ads, this.adDisplayOptions);
            }
          } else if (ads[0].adType === AdType.SPLASH_AD) {
            // 调用开屏广告展示页面
            if (ads[0]?.isFullScreen === true) {
              routePage('pages/SplashFullScreenAdPage', ads, this.adDisplayOptions);
            } else {
              routePage('pages/SplashHalfScreenAdPage', ads, this.adDisplayOptions);
            }
          } else if (ads[0].adType === AdType.PLACEMENT_AD) {
            // 调用贴片广告展示页面
            routePage('pages/PlacementAdPage', ads, this.adDisplayOptions, this.adOptionsPlacementAd);
          } else if (ads[0].adType === AdType.INTERSTITIAL_AD) {
            // 注册插屏广告状态监听器，用于监听插屏广告播放状态
            new InterstitialAdStatusHandler().registerPPSReceiver();
            // 调用广告展示接口
            advertising.showAd(ads[0], this.adDisplayOptions, this.context);
          } else {
            HiAdLog.w(TAG, 'error adType');
          }
        }
      }
    };
    // 创建AdLoader广告对象
    const load: advertising.AdLoader = new advertising.AdLoader(this.context);
    // 调用广告请求接口
    HiAdLog.i(TAG, 'request ad!');
    load.loadAd(adReqParams, adOptions, adLoaderListener);
  }

  private requestOAIDTrackingConsentPermissions(context: common.Context): void {
    // 进入页面时触发动态授权弹框，向用户请求授权广告跟踪权限
    const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    try {
      atManager.requestPermissionsFromUser(context, ["ohos.permission.APP_TRACKING_CONSENT"]).then((data) => {
        if (data.authResults[0] == 0) {
          HiAdLog.i(TAG, 'succeeded in requesting permission');
          identifier.getOAID().then((data: string) => {
            this.oaid = data;
            HiAdLog.i(TAG, `succeeded in gettiing adsIdentifierInfo by promise`);
          }).catch((error: BusinessError) => {
            HiAdLog.e(TAG, `getAdsIdentifierInfo failed, message: ${error.message}`);
          })
        } else {
          HiAdLog.i(TAG, 'user rejected');
        }
      }).catch((err: BusinessError) => {
        HiAdLog.e(TAG, `request permission failed, error: ${err.code} ${err.message}`);
      })
    } catch (err) {
      HiAdLog.e(TAG, `catch err->${err.code}, ${err.message}`);
    }
  }
}

async function routePage(pageUri: string, ads: Array<advertising.Advertisement | null>, displayOptions: advertising.AdDisplayOptions, adOptions?: advertising.AdOptions) {
  let options: router.RouterOptions = {
    url: pageUri,
    params: {
      ads: ads,
      displayOptions: displayOptions,
      adOptions: adOptions,
    }
  }
  try {
    HiAdLog.i(TAG, `routePage  + ${pageUri}`);
    router.pushUrl(options);
  } catch (error) {
    HiAdLog.e(TAG, `routePage fail callback, code: ${error.code}, msg: ${error.message}`);
  }
}

async function routePageWithoutAds(pageUri: string, oaid: string, adRequestParams: advertising.AdRequestParams, displayOptions: advertising.AdDisplayOptions, adOptions: advertising.AdOptions) {
  // 给AdRequestParams设置oaid参数
  adRequestParams.oaid = oaid;
  let options: router.RouterOptions = {
    url: pageUri,
    params: {
      adRequestParams: adRequestParams,
      displayOptions: displayOptions,
      adOptions: adOptions,
    }
  }
  try {
    HiAdLog.i(TAG, `routePage  + ${pageUri}`);
    router.pushUrl(options);
  } catch (error) {
    HiAdLog.e(TAG, `routePage fail callback, code: ${error.code}, msg: ${error.message}`);
  }
}