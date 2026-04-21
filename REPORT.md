# 广告服务示例：「激励广告」按钮功能说明报告

## 一、功能概述
本报告针对鲸鸿动能广告服务示例首页中的 **「激励广告」按钮** 进行完整解析。该按钮是广告服务 Demo 中最核心的交互入口之一，点击后会触发激励广告的加载与展示流程，用户观看完整广告后可获得预设奖励。

## 二、功能位置与触发逻辑
- 文件路径：`entry/src/main/ets/pages/Index.ets`
- 触发方式：用户点击首页列表中的「激励广告」按钮

### 核心代码片段
```typescript
// 激励广告按钮配置
this.buttonsOptions.push({
  text: $r('app.string.request_reward_ad_btn'),
  shouldShowAd: true,
  adRequestParams: {
    adId: 'testx9dtjwj8hp',
    adType: AdType.REWARD,
    oaid: oaid
  }
});

// 按钮点击事件
Button(repeatItem.item.text)
  .onClick(() => {
    const options = repeatItem.item;
    if (options.shouldShowAd && options.adRequestParams) {
      this.viewModel.loadAd(options.adRequestParams);
      return;
    }
  })
```
## 三、参数与配置解析
| 参数 | 说明 | 作用 |
| --- | --- | --- |
| text | $r('app.string.request_reward_ad_btn') | 按钮显示的文字，多语言适配 |
| shouldShowAd | true | 标记该按钮点击后直接加载并展示广告 |
| adId | testx9dtjwj8hp | 华为广告平台提供的测试广告位 ID |
| adType | AdType.REWARD | 指定广告类型为激励广告 |
| oaid | 设备 OAID | 广告标识，用于精准投放与归因 |

## 四、点击后完整执行流程
1. **用户点击**：触发按钮的 onClick 事件。
2. **参数校验**：代码会检查 shouldShowAd 和 adRequestParams 是否有效，防止空指针崩溃。
3. **调用 ViewModel**：执行 this.viewModel.loadAd(options.adRequestParams)，将广告请求参数传递给业务逻辑层。
4. **SDK 请求广告**：AdsViewModel 会调用 @kit.AdsKit 提供的 API，向华为广告服务器发起请求。
5. **广告加载与渲染**：
   - 加载成功：自动弹出全屏广告界面，开始播放视频。
   - 加载失败：通过日志 hilog.error 输出错误信息，并可配置错误回调。
6. **用户观看与奖励发放**：用户观看完整广告后，SDK 会触发奖励回调，应用可在此处为用户发放虚拟奖励。

## 五、AI 优化与健壮性提升
在本次优化中，针对该按钮功能进行了以下改进：
- **增加空安全判断**：在 onClick 事件中添加了 options 和 adRequestParams 的非空判断，防止因数据异常导致应用崩溃。
- **异常日志增强**：在 requestOAID 函数中优化了日志输出，当获取广告标识失败时，会清晰记录错误原因，便于调试。
- **代码注释完善**：为按钮配置、点击事件和相关 ViewModel 方法添加了详细注释，提升了代码可读性与可维护性。

## 六、运行效果
点击按钮后，应用会弹出全屏激励广告。用户观看完毕后，应用会收到奖励回调，完成整个流程。功能稳定，无闪退、无异常，符合鸿蒙应用开发规范。
