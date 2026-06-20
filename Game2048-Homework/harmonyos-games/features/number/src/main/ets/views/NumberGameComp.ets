import { HdNav } from '@mygames/basic'
import { Board, Tile } from '../services/helper'
import { HashMap } from '@kit.ArkTS';
import PreferencesUtil from '../services/PreferencesUtil';
import GameStateStore, { GameSnapshot, GAME_SNAPSHOT_VERSION } from '../services/GameStateStore';

interface InfoBuilderParams {
  info: string | Resource
  text: string
  width: string
}

interface ActionButtonParams {
  text: string | Resource
  width: string
  action: () => void
}

const PREFERENCES_KEY = 'number_best_score';
const WIDE_SCREEN_BREAKPOINT = 600;
const PHONE_CONTENT_WIDTH_RATIO = 0.9;
const WIDE_BOARD_WIDTH_RATIO = 0.52;
const WIDE_BOARD_HEIGHT_RATIO = 0.86;
const WIDE_BOARD_MAX_SIZE = 520;
const DEFAULT_BOARD_SIZE = 320;

@Component
export struct NumberGameComp {
  @State won: boolean = false;
  @State lost: boolean = false;
  @State board: Board = new Board();
  @State score: number = 0;
  @State bestScore: number = 0;
  @State stepCount: number = 0;
  @State boardCellsArray: Tile[][] = [];
  @State contentWidth: number = 0;
  @State contentHeight: number = 0;
  @State imageHashMap: HashMap<string, Resource> = new HashMap();
  private preferencesUtil = new PreferencesUtil();

  build() {
    Column() {
      if (this.isWideScreen()) {
        this.wideLayoutBuilder()
      } else {
        this.phoneLayoutBuilder()
      }
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      direction: GradientDirection.Right,
      repeating: false,
      colors: [['#ff453ba7', 0.0], ['#ff56319b', 0.47], ['#ff5431b5', 1.0]]
    })
    .onAreaChange((_oldValue: Area, newValue: Area) => {
      this.updateContentSize(newValue.width, newValue.height)
    })
    .onVisibleAreaChange([0.0, 1.0], (isVisible: boolean, _currentRatio: number) => {
      if (isVisible) {
        this.restorePendingSnapshotIfNeeded()
      }
    })
  }

  @Builder
  phoneLayoutBuilder() {
    Scroll() {
      Column({ space: 10 }) {
        HdNav({ title: '2048', showRightIcon: false })
        this.actionsBuilder(false)
        this.infoRowBuilder('90%')
        this.boardBuilder()
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .padding({ bottom: 16 })
    }
    .width('100%')
    .height('100%')
    .scrollable(ScrollDirection.Vertical)
  }

  @Builder
  wideLayoutBuilder() {
    Row({ space: 28 }) {
      Column() {
        this.boardBuilder()
      }
      .width('58%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Scroll() {
        Column({ space: 14 }) {
          Text('2048')
            .fontSize(34)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.common_gray_01'))
          this.actionsBuilder(true)
          this.infoRowBuilder('100%')
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
      .width('34%')
      .constraintSize({ maxWidth: 420 })
      .height('100%')
      .scrollable(ScrollDirection.Vertical)
    }
    .width('92%')
    .height('100%')
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  actionsBuilder(isWide: boolean) {
    Column({ space: 10 }) {
      Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.SpaceBetween }) {
        this.actionButton({ text: $r('app.string.n_new_game'), width: '48%', action: (): void => this.reset() })
        this.actionButton({ text: '游戏说明', width: '48%', action: (): void => this.showGameRules() })
      }
      .width('100%')

      Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.SpaceBetween }) {
        this.actionButton({ text: '保存模拟快照', width: '48%', action: (): void => this.saveSimulationSnapshot() })
        this.actionButton({ text: '恢复模拟快照', width: '48%', action: (): void => this.restoreSimulationSnapshot() })
      }
      .width('100%')
    }
    .width(isWide ? '100%' : '90%')
  }

  @Builder
  actionButton(params: ActionButtonParams) {
    Button(params.text)
      .type(ButtonType.Normal)
      .width(params.width)
      .height(46)
      .backgroundColor($r('app.color.n_cm_bg_color'))
      .fontColor($r('app.color.n_font_color'))
      .borderRadius(7)
      .fontSize(14)
      .onClick(params.action)
  }

  @Builder
  infoRowBuilder(containerWidth: string) {
    Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.SpaceEvenly }) {
      this.infoBuilder({ info: $r('app.string.n_points'), text: this.score.toString(), width: '30%' })
      this.infoBuilder({ info: $r('app.string.n_best'), text: this.bestScore.toString(), width: '30%' })
      this.infoBuilder({ info: '步数', text: this.stepCount.toString(), width: '30%' })
    }
    .width(containerWidth)
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
    }
    .width(params.width)
    .height(50)
    .backgroundColor($r('app.color.n_cm_bg_color'))
    .borderRadius(7)
  }

  @Builder
  boardBuilder() {
    Column() {
      if (this.lost) {
        Image($r('app.media.game_over'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Contain)
      } else if (this.won) {
        Image($r('app.media.2048'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Contain)
      } else {
        this.gridBuilder()
      }
    }
    .width(this.getBoardSize())
    .height(this.getBoardSize())
  }

  async aboutToAppear() {
    this.initImageHashMap()
    this.boardCellsArray = this.board.cells;
    await this.preferencesUtil.getPreferencesFromStorage();

    const resultData = await this.preferencesUtil.getPreference(PREFERENCES_KEY);
    this.bestScore = this.parsePreferenceNumber(resultData)
    if (!this.restorePendingSnapshotIfNeeded()) {
      this.publishSnapshot()
    }
  }

  reset() {
    this.board = new Board();
    this.boardCellsArray = this.board.cells;
    this.score = this.board.score
    this.stepCount = 0
    this.lost = false;
    this.won = false;
    this.publishSnapshot()
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
    .width('100%')
    .height('100%')
    .layoutDirection(GridDirection.Row)
    .gesture(GestureGroup(GestureMode.Exclusive,
      PanGesture({ direction: PanDirection.Left }).onActionEnd(() => {
        this.handleMove(0)
      }),
      PanGesture({ direction: PanDirection.Right }).onActionEnd(() => {
        this.handleMove(2)
      }),
      PanGesture({ direction: PanDirection.Up }).onActionEnd(() => {
        this.handleMove(1)
      }),
      PanGesture({ direction: PanDirection.Down }).onActionEnd(() => {
        this.handleMove(3)
      })
    ))
  }

  handleMove(direction: number): void {
    const beforeValues: number[][] = this.getBoardValues(this.board.cells)
    this.boardCellsArray = this.board.move(direction).cells
    const moved = this.isBoardChanged(beforeValues, this.boardCellsArray)
    if (moved) {
      this.stepCount += 1
    }
    this.updateGameStatus(this.board)
    if (moved) {
      this.publishSnapshot()
    }
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

  saveSimulationSnapshot(): void {
    this.publishSnapshot()
    if (GameStateStore.saveSimulationSnapshot()) {
      this.showMessage('模拟快照', '模拟快照已保存')
    } else {
      this.showMessage('模拟快照', '当前没有可保存的模拟快照。')
    }
  }

  restoreSimulationSnapshot(): void {
    if (!GameStateStore.prepareSimulationRestore()) {
      this.showMessage('模拟快照', '暂无可恢复的模拟快照')
      return;
    }

    if (this.restorePendingSnapshotIfNeeded()) {
      this.showMessage('模拟快照', '模拟快照已恢复')
    } else {
      this.showMessage('模拟快照', '模拟快照无效，未恢复。')
    }
  }

  showMessage(title: string, message: string): void {
    AlertDialog.show({
      title: title,
      message: message,
      primaryButton: {
        value: '知道了',
        action: () => {
        }
      }
    })
  }

  restorePendingSnapshotIfNeeded(): boolean {
    const pendingSnapshot = GameStateStore.consumePendingSnapshot()
    if (pendingSnapshot === undefined) {
      return false;
    }
    return this.restoreSnapshot(pendingSnapshot)
  }

  restoreSnapshot(snapshot: GameSnapshot): boolean {
    if (!this.board.restoreFromValues(snapshot.cells, snapshot.score, snapshot.won)) {
      return false;
    }

    this.boardCellsArray = this.board.cells;
    this.score = snapshot.score;
    this.stepCount = snapshot.stepCount;
    this.bestScore = snapshot.bestScore;
    this.won = snapshot.won;
    this.lost = snapshot.lost;
    this.saveBestScore()
    this.publishSnapshot()
    return true;
  }

  publishSnapshot(): void {
    const snapshot: GameSnapshot = {
      version: GAME_SNAPSHOT_VERSION,
      cells: this.board.exportCellValues(),
      score: this.score,
      stepCount: this.stepCount,
      bestScore: this.bestScore,
      won: this.won,
      lost: this.lost
    };
    GameStateStore.setLatestSnapshot(snapshot)
  }

  isWideScreen(): boolean {
    return this.contentWidth >= WIDE_SCREEN_BREAKPOINT;
  }

  getBoardSize(): number {
    if (this.isWideScreen()) {
      const widthSize = this.contentWidth > 0 ? this.contentWidth * WIDE_BOARD_WIDTH_RATIO : DEFAULT_BOARD_SIZE;
      const heightSize = this.contentHeight > 0 ? this.contentHeight * WIDE_BOARD_HEIGHT_RATIO : DEFAULT_BOARD_SIZE;
      return Math.max(1, Math.min(widthSize, heightSize, WIDE_BOARD_MAX_SIZE));
    }

    if (this.contentWidth > 0) {
      return Math.max(1, this.contentWidth * PHONE_CONTENT_WIDTH_RATIO);
    }
    return DEFAULT_BOARD_SIZE;
  }

  updateContentSize(width: Length, height: Length): void {
    this.contentWidth = this.parseLength(width);
    this.contentHeight = this.parseLength(height);
  }

  parseLength(value: Length): number {
    const parsedValue = Number(value);
    if (Number.isFinite(parsedValue)) {
      return parsedValue;
    }

    const fallbackValue = parseFloat(value.toString());
    return Number.isFinite(fallbackValue) ? fallbackValue : 0;
  }

  @Builder
  tileBuilder(params: Tile) {
    GridItem() {
      if (params.value > 0) {
        Image(this.getImageResource(params.value))
          .width('100%')
          .height('100%')
      }
    }
    .backgroundColor("#ff564a86")
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
