import { hilog } from '@kit.PerformanceAnalysisKit';
import router from '@ohos.router';

class GameItem {
  name: string;
  icon: Resource;
  route: string;

  constructor(name: string, icon: Resource, route: string) {
    this.name = name;
    this.icon = icon;
    this.route = route;
  }
}

const WIDE_SCREEN_BREAKPOINT = 600;
const WIDE_CARD_WIDTH = 220;
const WIDE_CARD_HEIGHT = 150;

@Entry
@Component
struct Index {
  @State contentWidth: number = 0;
  @State games: ToolbarItem = {
    'value': "游戏", 'icon': $r('app.media.games'), 'action': () => {
      hilog.info(0x0000, 'testTag', '游戏 ok');
    }
  }
  @State about: ToolbarItem = {
    'value': "关于", 'icon': $r('app.media.about'), 'action': () => {
      router.pushUrl({
        url: "pages/About"
      })
    }
  }
  private services: GameItem[] =
    [
      new GameItem("2048", $r('app.media.2048_2'), "pages/NumberGame"),
      new GameItem("变色方块", $r('app.media.background'), "pages/ColorBlocks"),
      new GameItem("推箱子", $r('app.media.background'), "")
    ]

  build() {
    Column() {
      Navigation() {
        if (this.isWideScreen()) {
          this.wideGameListBuilder()
        } else {
          this.phoneGameListBuilder()
        }
      }
      .title("经典小游戏")
      .width('100%')
      .height('100%')
      .mode(NavigationMode.Stack)
      .toolbarConfiguration([this.games, this.about], {
        backgroundColor: 'rgba(96, 139, 196, 1.00)'
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(52, 89, 138, 1.00)')
    .onAreaChange((_oldValue: Area, newValue: Area) => {
      this.contentWidth = this.parseLength(newValue.width)
    })
  }

  @Builder
  phoneGameListBuilder() {
    List() {
      ForEach(this.services, (item: GameItem) => {
        ListItem() {
          this.gameCardBuilder(item, '100%', 80, false)
        }
        .margin(8)
      }, (_item: GameItem, index: number) => {
        return index + ''
      })
    }
    .margin(20)
  }

  @Builder
  wideGameListBuilder() {
    Column() {
      Flex({
        direction: FlexDirection.Row,
        wrap: FlexWrap.Wrap,
        justifyContent: FlexAlign.Center,
        alignItems: ItemAlign.Center
      }) {
        ForEach(this.services, (item: GameItem) => {
          this.gameCardBuilder(item, WIDE_CARD_WIDTH, WIDE_CARD_HEIGHT, true)
        }, (_item: GameItem, index: number) => {
          return index + ''
        })
      }
      .width('88%')
      .constraintSize({ maxWidth: 820 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  gameCardBuilder(item: GameItem, width: Length, height: number, isWide: boolean) {
    Row({ space: isWide ? 14 : 0 }) {
      Image(item.icon)
        .width(isWide ? 64 : 55)
        .height(isWide ? 64 : 55)
        .margin(isWide ? 0 : 15)
        .border({ radius: 10 })
      Column({ space: 6 }) {
        Text(item.name)
          .fontSize(isWide ? 22 : 25)
          .fontColor('#fff')
          .maxLines(1)
        if (item.route == '') {
          Text('开发中...')
            .fontSize(13)
            .fontColor('#fff')
            .maxLines(1)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width(width)
    .height(height)
    .padding(isWide ? 18 : 0)
    .margin(isWide ? 12 : 0)
    .backgroundColor('#ff472b81')
    .border({ radius: 7 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.openGame(item)
    })
  }

  openGame(item: GameItem): void {
    if (item.route) {
      router.pushUrl({
        url: item.route
      })
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
