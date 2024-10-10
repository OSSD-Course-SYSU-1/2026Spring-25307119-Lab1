# Ads Kit Sample Code (HarmonyOS ArkTS)
## Contents

* [Overview](#Overview)
* [Installation](#Installation)
* [Preview](#Preview)
* [Project Directory](#Project-Directory)
* [Sample Code](#Sample-Code)
* [Constraints](#Constraints)


## Overview
The sample code of Ads Kit for HarmonyOS ArkTS describes how to use APIs of Ads Kit in your app to display ads.

## Installation
Install the demo on a phone running HarmonyOS.

## Preview
| **Home screen for various ad formats**              | **Rewarded ad**                       | **Native video ad**                                |
|-----------------------------------------------------|------------------------------------|--------------------------------------------|
| ![avatar](./screenshots/device_en/home_page_en.jpg) | ![avatar](./screenshots/device_en/reward_en.jpg) | ![avatar](./screenshots/device_en/native_video_en.jpg) |

| **Native large image ad**                      | **Native small image ad**                        | **Native three-image ad**                        |
|------------------------------------------------|------------------------------------|------------------------------------|
| ![avatar](./screenshots/device_en/native_big_en.jpg) | ![avatar](./screenshots/device_en/native_small_en.jpg) | ![avatar](./screenshots/device_en/native_three_en.jpg) |

| **Splash video ad**                                    | **Splash image ad**                                    | **Image roll ad**                                |
|--------------------------------------------------|--------------------------------------------------------|--------------------------------------------------|
| ![avatar](./screenshots/device_en/splash_video_en.jpg) | ![avatar](./screenshots/device_en/splash_pictures_en.png) | ![avatar](./screenshots/device_en/placement_en.png) |

| **Interstitial video ad**                                          | **Interstitial image ad**     | **Banner ad**                                 |
|--------------------------------------------------------|-------------------|-----------------------------------------------|
| ![avatar](./screenshots/device_en/interstitial_video_en.jpg) | ![avatar](./screenshots/device_en/interstitial_picture_en.jpg) | ![avatar](./screenshots/device_en/banner_en.jpg) |

## Project Directory
```
├─entry/src/main/ets               // Code area. 
│ ├─constant                       // Constants.                        
│ │ └─AdType.ets                   // Class of enumerated ad types.
│ ├─entryability
│ │ └─EntryAbility.ets             // Entry point class.
│ ├─event   
│ │ └─AdStatus.ets                 // Class of enumerated ad callback statuses.
│ │ └─InterstitialAdStatusHandler.ets // Class for subscribing to interstitial ad events.
│ │ └─RewardAdStatusHandler.ets    // Class for subscribing to rewarded ad events.
│ ├─log   
│ │ └─HiAdLog.ets                  // Log component.
│ ├─pages                          // Directory for storing app UI files.               
│ │ ├─AdsServicePage.ets           // App home screen.
│ │ ├─BannerAdPage.ets             // Banner ad page.
│ │ ├─NativeAdPage.ets             // Native ad page.
│ │ ├─PlacementAdPage.ets          // Roll ad page.
│ │ ├─SplashFullScreenAdPage.ets   // Full-screen splash ad page.               
│ │ └─SplashHalfScreenAdPage.ets   // Half-screen splash ad page.
│ ├─widgets                        // Common components.
│ │ ├─action-bar.ets               // Action bar component.   
│ │ └─custom-button.ets            // Button component.
└─entry/src/main/resources         // Directory for storing resource files.
```
## Sample Code
### Petal Ads Publisher Service
The sample code is used to implement a UI to display various formats of ads.
The sample code includes the following files for you to request and display ads:

1). AdsServicePage.ets
Demo UI of Petal Ads Publisher Service, where you can tap the corresponding button to request and display banner ads, rewarded ads, native ads, splash ads, roll ads, and interstitial ads.
<br>Code location: **entry\src\main\ets\pages\AdsServicePage.ets**<br>

2). NativeAdPage.ets
Used to display native ads.
<br>Code location: **entry\src\main\ets\pages\NativeAdPage.ets**<br>

3). PlacementAdPage.ets
Used to display roll ads.
<br>Code location: **entry\src\main\ets\pages\PlacementAdPage.ets**<br>

4). SplashFullScreenAdPage.ets
Used to display full-screen splash ads.
<br>Code location: **entry\src\main\ets\pages\SplashFullScreenAdPage.ets**<br>

5). SplashHalfScreenAdPage.ets
Used to display half-screen splash ads.
<br>Code location: **entry\src\main\ets\pages\SplashFullScreenAdPage.ets**<br>

6). BannerAdPage.ets
Used to display banner ads.
<br>Code location: **entry\src\main\ets\pages\BannerAdPage.ets**<br>

## Constraints

1. The sample app is only supported on Huawei phones and tablets with standard systems.
2. The HarmonyOS version must be HarmonyOS NEXT Developer Beta1 or later.
3. The DevEco Studio version must be DevEco Studio NEXT Developer Beta1 or later.
4. The HarmonyOS SDK version must be HarmonyOS NEXT Developer Beta1 or later.
