import { hilog } from '@kit.PerformanceAnalysisKit';
import router from '@ohos.router';

class GameItem {
  name: string;
  icon: Resource;
  route: string;
  description: string;
  tags: string[];

  constructor(name: string, icon: Resource, route: string, description: string, tags: string[]) {
    this.name = name;
    this.icon = icon;
    this.route = route;
    this.description = description;
    this.tags = tags;
  }
}

const WIDE_SCREEN_BREAKPOINT = 600;
const WIDE_CARD_WIDTH = 270;
const WIDE_CARD_HEIGHT = 216;

@Entry
@Component
struct Index {
  @State contentWidth: number = 0;
  @State games: ToolbarItem = {
    value: '游戏',
    icon: $r('app.media.games'),
    action: () => {
      hilog.info(0x0000, 'testTag', 'games ok');
    }
  }
  @State about: ToolbarItem = {
    value: '关于',
    icon: $r('app.media.about'),
    action: () => {
      router.pushUrl({ url: 'pages/About' });
    }
  }
  private services: GameItem[] = [
    new GameItem('2048', $r('app.media.2048_2'), 'pages/NumberGame', '数字合并益智游戏', ['多模式', '成就', '跨设备接续']),
    new GameItem('变色方块', $r('app.media.background'), 'pages/ColorBlocks', '考验反应速度', ['休闲', '反应']),
    new GameItem('推箱子', $r('app.media.background'), '', '经典空间解谜', ['解谜', '策略'])
  ];

  build() {
    Column() {
      Navigation() {
        if (this.isWideScreen()) {
          this.wideGameListBuilder()
        } else {
          this.phoneGameListBuilder()
        }
      }
      .title('经典小游戏')
      .width('100%')
      .height('100%')
      .mode(NavigationMode.Stack)
      .toolbarConfiguration([this.games, this.about], { backgroundColor: $r('app.color.theme_card') })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.common_gray_bg'))
    .onAreaChange((_oldValue: Area, newValue: Area) => {
      this.contentWidth = this.parseLength(newValue.width);
    })
  }

  @Builder
  phoneGameListBuilder() {
    Scroll() {
      Column({ space: 14 }) {
        this.homeHeaderBuilder(false)
        ForEach(this.services, (item: GameItem) => {
          this.gameCardBuilder(item, '100%', 126, false)
        }, (_item: GameItem, index: number) => index.toString())
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 24, bottom: 32 })
    }
    .width('100%')
    .height('100%')
    .scrollable(ScrollDirection.Vertical)
  }

  @Builder
  wideGameListBuilder() {
    Scroll() {
      Column({ space: 26 }) {
        this.homeHeaderBuilder(true)
        Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
          ForEach(this.services, (item: GameItem) => {
            this.gameCardBuilder(item, WIDE_CARD_WIDTH, WIDE_CARD_HEIGHT, true)
          }, (_item: GameItem, index: number) => index.toString())
        }
        .width('88%')
        .constraintSize({ maxWidth: 940 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .padding({ top: 28, bottom: 36 })
    }
    .width('100%')
    .height('100%')
    .scrollable(ScrollDirection.Vertical)
  }

  @Builder
  homeHeaderBuilder(isWide: boolean) {
    Column({ space: 6 }) {
      Text('经典小游戏')
        .fontSize(isWide ? 34 : 28)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.black'))
      Text('随时来一局')
        .fontSize(15)
        .fontColor($r('app.color.theme_secondary_text'))
    }
    .width(isWide ? '88%' : '100%')
    .alignItems(isWide ? HorizontalAlign.Center : HorizontalAlign.Start)
  }

  @Builder
  gameCardBuilder(item: GameItem, width: Length, height: number, isWide: boolean) {
    Column({ space: 12 }) {
      Row({ space: 14 }) {
        Image(item.icon)
          .width(isWide ? 62 : 56)
          .height(isWide ? 62 : 56)
          .objectFit(ImageFit.Contain)
          .border({ radius: 14 })
        Column({ space: 5 }) {
          Text(item.name)
            .fontSize(isWide ? 22 : 21)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.black'))
            .maxLines(1)
          Text(item.description)
            .fontSize(13)
            .fontColor($r('app.color.theme_secondary_text'))
            .maxLines(2)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
        ForEach(item.tags, (tag: string) => {
          Text(tag)
            .fontSize(11)
            .fontColor($r('app.color.common_main_color'))
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor('#F0EBFF')
            .borderRadius(10)
            .margin({ right: 8, bottom: 8 })
        }, (tag: string) => tag)
      }
      .width('100%')

      Row() {
        Blank()
        Text(item.route === '' ? '开发中' : '开始游戏')
          .fontSize(12)
          .fontColor(item.route === '' ? $r('app.color.theme_secondary_text') : $r('app.color.theme_primary_dark'))
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
    }
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(HorizontalAlign.Start)
    .width(width)
    .height(height)
    .padding(isWide ? 20 : 18)
    .margin(isWide ? 12 : 0)
    .backgroundColor($r('app.color.theme_card'))
    .border({ width: 1, color: $r('app.color.common_gray_border'), radius: 16 })
    .onClick(() => this.openGame(item))
  }

  openGame(item: GameItem): void {
    if (item.route) {
      router.pushUrl({ url: item.route });
    }
  }

  isWideScreen(): boolean {
    return this.contentWidth >= WIDE_SCREEN_BREAKPOINT;
  }

  parseLength(value: Length): number {
    const parsedValue = Number(value);
    if (Number.isFinite(parsedValue)) {
      return parsedValue;
    }

    const fallbackValue = parseFloat(value.toString());
    return Number.isFinite(fallbackValue) ? fallbackValue : 0;
  }
}
