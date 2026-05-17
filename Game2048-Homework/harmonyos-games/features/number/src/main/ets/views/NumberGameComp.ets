import { HdNav } from '@mygames/basic'
import { Board, Tile } from '../services/helper'
import { HashMap } from '@kit.ArkTS'; // 导入HashMap模块
import PreferencesUtil from '../services/PreferencesUtil';

interface InfoBuilderParams {
  info: string | Resource
  text: string
}
const PREFERENCES_KEY = 'number_best_score';
@Component
export struct NumberGameComp {
  @State won: boolean = false;
  @State lost: boolean = false;
  @State board: Board = new Board();
  @State score: number = 0;
  @State bestScore: number = 0;
  @State stepCount: number = 0;
  @State gridMap: number[][] = [[1, 2, 3, 4], [5, 6, 7, 8], [9, 10, 11, 12], [13, 14, 15, 16]]
  @State boardCellsArray: Tile[][] = [];
  @State screenStartX: number = 0
  @State screenStartY: number = 0
  @State lastScreenX: number = 0
  @State lastScreenY: number = 0
  @State imageHashMap: HashMap<string, Resource> = new HashMap();
  private preferencesUtil = new PreferencesUtil();
  build() {
    Column({ space: 16 }) {
      HdNav({ title: '2048', showRightIcon: false })
      Column({ space: 10 }) {
        Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.SpaceEvenly }) {
          Button($r('app.string.n_new_game'))
            .type(ButtonType.Normal)
            .width('42%')
            .height(50)
            .backgroundColor($r('app.color.n_cm_bg_color'))
            .fontColor($r('app.color.n_font_color'))
            .borderRadius(7)
            .onClick(() => {
              this.reset()
            })
          Button('游戏说明')
            .type(ButtonType.Normal)
            .width('42%')
            .height(50)
            .backgroundColor($r('app.color.n_cm_bg_color'))
            .fontColor($r('app.color.n_font_color'))
            .borderRadius(7)
            .onClick(() => {
              this.showGameRules()
            })
        }
        .width('100%')

        Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.SpaceEvenly }) {
          this.infoBuilder({ info: $r('app.string.n_points'), text: this.score + '' })
          this.infoBuilder({ info: $r('app.string.n_best'), text: this.bestScore + '' })
          this.infoBuilder({ info: '步数', text: this.stepCount + '' })
        }
        .width('100%')
      }
      .height(120)
      .width('90%')
      .padding(10)

      if (this.lost) {
        Image($r('app.media.game_over')).width('90%')
      } else if (this.won) {
        Image($r('app.media.2048')).width('90%')
      } else {
        this.gridBuilder()
      }
    }
    .linearGradient({
      direction: GradientDirection.Right,
      repeating: false,
      colors: [['#ff453ba7', 0.0], ['#ff56319b', 0.47], ['#ff5431b5', 1.0]]
    })
    .height('100%')

  }

  @Builder
  infoBuilder(params: InfoBuilderParams) {
    Column() {
      Row() {
        Text(params.info)
          .fontSize(10)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 4 })
          .fontColor($r('app.color.common_gray_01'))
      }
      .alignItems(VerticalAlign.Bottom)

      Text(params.text)
        .fontSize(20)
        .fontColor($r('app.color.common_gray_01'))
    }.width('30%').height(50).backgroundColor($r('app.color.n_cm_bg_color'))
    .borderRadius(7)
  }

  async aboutToAppear() {
    console.log("aboutToAppear")
    this.initImageHashMap()
    this.boardCellsArray = this.board.cells;
    console.log(JSON.stringify(this.boardCellsArray))
    // 初始化首选项
    await this.preferencesUtil.getPreferencesFromStorage();

    // 获取最佳得分
    this.preferencesUtil.getPreference(PREFERENCES_KEY).then(resultData => {
      console.log('PREFERENCES_KEY', resultData)
      this.bestScore = this.parsePreferenceNumber(resultData)
    });
  }

  reset() {
    this.board = new Board();
    this.boardCellsArray = this.board.cells;
    this.score = this.board.score
    this.stepCount = 0
    this.lost = false;
    this.won = false;
  }

  @Builder
  gridBuilder() {
    Grid(undefined, {
      regularSize: [1, 1]
    }) {
      ForEach(this.boardCellsArray, (row: Tile[]) => {
        ForEach(row, (item: Tile) => {
          this.tileBuilder(item)
        }, (item: Tile, index) => {
          return item.id + Math.random() + '';
        })
      }, (_item: Tile[], index) => {
        return index + Math.random() + '';
      })
    }
    .columnsGap(10)
    .rowsGap(10)
    .maxCount(4)
    .columnsTemplate('1fr 1fr 1fr 1fr')
    .rowsTemplate('1fr 1fr 1fr 1fr')
    .width('90%')
    .height('43%')
    .layoutDirection(GridDirection.Row)
    .gesture(GestureGroup(GestureMode.Exclusive,
      PanGesture({ direction: PanDirection.Left }).onActionEnd(() => {
        console.info("Left")
        this.handleMove(0)
      }),
      PanGesture({ direction: PanDirection.Right }).onActionEnd(() => {
        console.info("Right")
        this.handleMove(2)
      }),
      PanGesture({ direction: PanDirection.Up }).onActionEnd(() => {
        console.info("Up")
        this.handleMove(1)
      }),
      PanGesture({ direction: PanDirection.Down }).onActionEnd(() => {
        console.info("Down")
        this.handleMove(3)
      })
    ))
  }

  handleMove(direction: number): void {
    const beforeValues: number[][] = this.getBoardValues(this.board.cells)
    this.boardCellsArray = this.board.move(direction).cells
    if (this.isBoardChanged(beforeValues, this.boardCellsArray)) {
      this.stepCount += 1
    }
    this.updateGameStatus(this.board)
  }

  updateGameStatus(board: Board): void {
    this.score = board.score
    if (this.score > this.bestScore) {
      this.bestScore = this.score
      this.saveBestScore()
    }
    if (board.hasLost()) {
      this.lost = true
    }
    if (board.hasWon()) {
      this.won = true
    }
  }

  getBoardValues(cells: Tile[][]): number[][] {
    let values: number[][] = []
    for (let rowIndex = 0; rowIndex < cells.length; rowIndex++) {
      let rowValues: number[] = []
      for (let columnIndex = 0; columnIndex < cells[rowIndex].length; columnIndex++) {
        rowValues.push(cells[rowIndex][columnIndex].value)
      }
      values.push(rowValues)
    }
    return values
  }

  isBoardChanged(beforeValues: number[][], afterCells: Tile[][]): boolean {
    for (let rowIndex = 0; rowIndex < afterCells.length; rowIndex++) {
      for (let columnIndex = 0; columnIndex < afterCells[rowIndex].length; columnIndex++) {
        if (beforeValues[rowIndex][columnIndex] !== afterCells[rowIndex][columnIndex].value) {
          return true
        }
      }
    }
    return false
  }

  parsePreferenceNumber(value: Object): number {
    const parsedValue = Number(value)
    if (Number.isNaN(parsedValue)) {
      return 0
    }
    return parsedValue
  }

  async saveBestScore() {
    await this.preferencesUtil.putPreference(PREFERENCES_KEY, this.bestScore)
  }

  showGameRules() {
    AlertDialog.show({
      title: '游戏说明',
      message: '上下左右滑动棋盘移动所有数字方块。相同数字的方块相撞时会合并成它们的和，并计入当前分数。每次有效滑动会增加一步。合成 2048 即获胜；棋盘填满且无法继续合并时游戏结束。',
      primaryButton: {
        value: '知道了',
        action: () => {
        }
      }
    })
  }

  @Builder
  tileBuilder(params: Tile) {
    GridItem() {
      if (params.value > 0) {
        Image(this.getImageResource(params.value))
      }
    }.backgroundColor("#ff564a86")

  }

  getImageResource(value: number) {
    return this.imageHashMap.get(value.toString())
  }

  initImageHashMap() {
    this.imageHashMap.set("2", $r('app.media.2'))
    this.imageHashMap.set("4", $r('app.media.4'))
    this.imageHashMap.set("8", $r('app.media.8'))
    this.imageHashMap.set("16", $r('app.media.16'))
    this.imageHashMap.set("32", $r('app.media.32'))
    this.imageHashMap.set("64", $r('app.media.64'))
    this.imageHashMap.set("128", $r('app.media.128'))
    this.imageHashMap.set("256", $r('app.media.256'))
    this.imageHashMap.set("512", $r('app.media.512'))
    this.imageHashMap.set("1024", $r('app.media.1024'))
  }
}
