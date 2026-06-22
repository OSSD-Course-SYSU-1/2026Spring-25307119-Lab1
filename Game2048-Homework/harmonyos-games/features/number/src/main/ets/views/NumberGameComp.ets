import { HdNav } from '@mygames/basic';
import { KeyCode } from '@ohos.multimodalInput.keyCode';
import { Board, Tile } from '../services/helper';
import { HashMap } from '@kit.ArkTS';
import PreferencesUtil from '../services/PreferencesUtil';
import GameStateStore, { GameSnapshot, GAME_SNAPSHOT_VERSION } from '../services/GameStateStore';
import AchievementStore from '../services/AchievementStore';
import StatisticsStore from '../services/StatisticsStore';
import {
  Achievement,
  GameMode,
  GameRecord,
  GameStatistics,
  ModeBestScores,
  MOVE_LIMIT_TOTAL_MOVES,
  TIMED_TOTAL_SECONDS,
  getAchievementDefinitions,
  getDefaultStatistics,
  getModeName
} from '../services/GameModels';

interface InfoBuilderParams {
  info: string | Resource
  text: string
  width: string
}

interface ActionButtonParams {
  text: string | Resource
  width: string
  action: () => void
  style?: string
  enabled?: boolean
}

interface ModeCardParams {
  mode: GameMode
  title: string
  subtitle: string
}

interface BoardCellView {
  id: number
  key: string
  value: number
  row: number
  column: number
  isNew: boolean
  mergedThisTurn: boolean
}

const WIDE_SCREEN_BREAKPOINT = 600;
const PHONE_CONTENT_WIDTH_RATIO = 0.9;
const WIDE_BOARD_WIDTH_RATIO = 0.52;
const WIDE_BOARD_HEIGHT_RATIO = 0.86;
const WIDE_BOARD_MAX_SIZE = 520;
const DEFAULT_BOARD_SIZE = 320;
const KEY_TARGET_FOCUS_ID = 'game-key-target';
const KEYCODE_DPAD_UP = 19;
const KEYCODE_DPAD_DOWN = 20;
const KEYCODE_DPAD_LEFT = 21;
const KEYCODE_DPAD_RIGHT = 22;
const KEYCODE_A = 29;
const KEYCODE_D = 32;
const KEYCODE_S = 47;
const KEYCODE_W = 51;
const BUTTON_STYLE_PRIMARY = 'primary';
const BUTTON_STYLE_SECONDARY = 'secondary';
const BUTTON_STYLE_TERTIARY = 'tertiary';
const RESULT_WIN = 'win';
const RESULT_LOSE = 'lose';
const RESULT_TIMEOUT = 'timeout';
const RESULT_MOVE_LIMIT = 'move_limit_end';
const SETTLEMENT_NONE = 'NONE';
const SETTLEMENT_WIN = 'WIN';
const SETTLEMENT_NO_MOVES = 'NO_MOVES';
const SETTLEMENT_TIME_UP = 'TIME_UP';
const SETTLEMENT_MOVE_LIMIT_REACHED = 'MOVE_LIMIT_REACHED';

@Component
export struct NumberGameComp {
  @State won: boolean = false;
  @State lost: boolean = false;
  @State board: Board = new Board();
  @State score: number = 0;
  @State bestScore: number = 0;
  @State stepCount: number = 0;
  @State boardCellsArray: BoardCellView[][] = [];
  @State boardRenderVersion: number = 0;
  @State contentWidth: number = 0;
  @State contentHeight: number = 0;
  @State canUndo: boolean = false;
  @State modeSelected: boolean = false;
  @State currentMode: GameMode = GameMode.CLASSIC;
  @State remainingSeconds: number = TIMED_TOTAL_SECONDS;
  @State remainingMoves: number = MOVE_LIMIT_TOTAL_MOVES;
  @State gameEnded: boolean = false;
  @State modeBestScores: ModeBestScores = { classic: 0, timed: 0, moveLimit: 0 };
  @State achievements: Achievement[] = getAchievementDefinitions();
  @State statistics: GameStatistics = getDefaultStatistics();
  @State showAchievementsPanel: boolean = false;
  @State showStatisticsPanel: boolean = false;
  @State currentAchievement: Achievement | undefined = undefined;
  @State achievementVisible: boolean = false;
  @State achievementQueue: Achievement[] = [];
  @State settlementVisible: boolean = false;
  @State settlementReason: string = SETTLEMENT_NONE;
  @State settlementScore: number = 0;
  @State settlementSteps: number = 0;
  @State settlementMaxTile: number = 0;
  @State settlementBestScore: number = 0;
  @State imageHashMap: HashMap<string, Resource> = new HashMap();

  private undoSnapshot: GameSnapshot | undefined = undefined;
  private victoryPromptShown: boolean = false;
  private lostPromptShown: boolean = false;
  private settlementPromptShown: boolean = false;
  private roundRecorded: boolean = false;
  private timerId: number = -1;
  private pendingSettlementReason: string = SETTLEMENT_NONE;
  private preferencesUtil = new PreferencesUtil();
  private achievementStore = new AchievementStore(this.preferencesUtil);
  private statisticsStore = new StatisticsStore(this.preferencesUtil);

  build() {
    Stack() {
      Column() {
        if (!this.modeSelected) {
          this.modeSelectionPageBuilder()
        } else if (this.showAchievementsPanel) {
          this.achievementPanelBuilder()
        } else if (this.showStatisticsPanel) {
          this.statisticsPanelBuilder()
        } else if (this.isWideScreen()) {
          this.wideLayoutBuilder()
        } else {
          this.phoneLayoutBuilder()
        }
      }
      if (this.achievementVisible && this.currentAchievement !== undefined) {
        this.achievementToastBuilder(this.currentAchievement)
      }
      if (this.settlementVisible) {
        this.settlementOverlayBuilder()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.n_page_bg'))
    .focusable(true)
    .focusOnTouch(true)
    .defaultFocus(true)
    .id(KEY_TARGET_FOCUS_ID)
    .onAppear(() => this.requestBoardFocus())
    .onKeyEvent((event: KeyEvent) => {
      return this.handleKeyEvent(event);
    })
    .onAreaChange((_oldValue: Area, newValue: Area) => {
      this.updateContentSize(newValue.width, newValue.height);
    })
    .onVisibleAreaChange([0.0, 1.0], (isVisible: boolean, _currentRatio: number) => {
      if (isVisible) {
        this.restorePendingSnapshotIfNeeded();
        this.startTimedTimerIfNeeded();
      } else {
        this.stopTimedTimer();
      }
    })
  }

  @Builder
  modeSelectionPageBuilder() {
    Scroll() {
      Column({ space: 18 }) {
        HdNav({ title: '2048', showRightIcon: false })
        Column({ space: 6 }) {
          Text('选择模式')
            .fontSize(this.isWideScreen() ? 34 : 28)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.n_font_color'))
          Text('先选玩法，再开始本局。')
            .fontSize(14)
            .fontColor($r('app.color.n_secondary_text'))
        }
        .width(this.isWideScreen() ? '82%' : '90%')
        .alignItems(this.isWideScreen() ? HorizontalAlign.Center : HorizontalAlign.Start)

        Flex({
          direction: FlexDirection.Row,
          wrap: FlexWrap.Wrap,
          justifyContent: FlexAlign.Center,
          alignItems: ItemAlign.Stretch
        }) {
          this.modeCardBuilder({ mode: GameMode.CLASSIC, title: '经典模式', subtitle: '无时间和步数限制，标准 2048 规则。' })
          this.modeCardBuilder({ mode: GameMode.TIMED, title: '限时挑战', subtitle: '90 秒倒计时，尽量获得更高分。' })
          this.modeCardBuilder({ mode: GameMode.MOVE_LIMIT, title: '步数挑战', subtitle: '50 次有效移动内冲击最高分。' })
        }
        .width(this.isWideScreen() ? '88%' : '90%')
        .constraintSize({ maxWidth: 900 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .padding({ bottom: 28 })
    }
    .width('100%')
    .height('100%')
    .scrollable(ScrollDirection.Vertical)
  }

  @Builder
  modeCardBuilder(params: ModeCardParams) {
    Column({ space: 10 }) {
      Text(params.title)
        .fontSize(21)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.n_font_color'))
      Text(params.subtitle)
        .fontSize(14)
        .fontColor($r('app.color.n_secondary_text'))
      Text(`最高分 ${this.getModeBestScore(params.mode)}`)
        .fontSize(13)
        .fontColor($r('app.color.n_primary'))
        .fontWeight(FontWeight.Bold)
    }
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Center)
    .width(this.isWideScreen() ? '30%' : '100%')
    .height(150)
    .padding(18)
    .margin(8)
    .backgroundColor($r('app.color.n_cm_bg_color'))
    .border({ width: 1, color: $r('app.color.n_card_border'), radius: 16 })
    .onClick(() => this.startNewGame(params.mode))
  }

  @Builder
  phoneLayoutBuilder() {
    Scroll() {
      Column({ space: 12 }) {
        HdNav({ title: '2048', showRightIcon: false })
        this.modeHeaderBuilder(false)
        this.infoRowBuilder('90%')
        this.mainActionsBuilder(false)
        this.snapshotActionsBuilder(false)
        this.secondaryActionsBuilder(false)
        this.boardBuilder()
        this.keyboardHintBuilder(false)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .padding({ bottom: 20 })
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
        Column({ space: 16 }) {
          Column({ space: 4 }) {
            Text('2048')
              .fontSize(34)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.n_font_color'))
            Text('合并数字，向 2048 前进')
              .fontSize(13)
              .fontColor($r('app.color.n_secondary_text'))
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          this.modeHeaderBuilder(true)
          this.infoRowBuilder('100%')
          this.mainActionsBuilder(true)
          this.snapshotActionsBuilder(true)
          this.secondaryActionsBuilder(true)
          this.keyboardHintBuilder(true)
        }
        .width('100%')
        .padding(20)
        .backgroundColor($r('app.color.n_cm_bg_color'))
        .border({ width: 1, color: $r('app.color.n_card_border'), radius: 16 })
      }
      .width('34%')
      .constraintSize({ maxWidth: 420 })
      .height('auto')
      .scrollable(ScrollDirection.Vertical)
    }
    .width('92%')
    .height('100%')
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  modeHeaderBuilder(isWide: boolean) {
    Column({ space: 6 }) {
      Row() {
        Text(getModeName(this.currentMode))
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.n_font_color'))
        Blank()
        Text(this.getModeStatusText())
          .fontSize(13)
          .fontColor($r('app.color.n_primary'))
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      Text(this.getModeDescription())
        .fontSize(12)
        .fontColor($r('app.color.n_secondary_text'))
    }
    .width(isWide ? '100%' : '90%')
    .padding(14)
    .backgroundColor($r('app.color.n_cm_bg_color'))
    .border({ width: 1, color: $r('app.color.n_card_border'), radius: 14 })
  }

  @Builder
  mainActionsBuilder(isWide: boolean) {
    Column({ space: 10 }) {
      Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.SpaceBetween }) {
        this.actionButton({ text: '新游戏', width: '48%', style: BUTTON_STYLE_PRIMARY, action: (): void => this.reset() })
        this.actionButton({
          text: '撤销一步',
          width: '48%',
          style: BUTTON_STYLE_SECONDARY,
          enabled: this.canUndo,
          action: (): void => this.undoLastMove()
        })
      }
      .width('100%')
    }
    .width(isWide ? '100%' : '90%')
  }

  @Builder
  snapshotActionsBuilder(isWide: boolean) {
    Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.SpaceBetween }) {
      this.actionButton({
        text: '保存快照',
        width: '48%',
        style: BUTTON_STYLE_TERTIARY,
        action: (): void => this.saveSimulationSnapshot()
      })
      this.actionButton({
        text: '恢复快照',
        width: '48%',
        style: BUTTON_STYLE_TERTIARY,
        action: (): void => this.restoreSimulationSnapshot()
      })
    }
    .width(isWide ? '100%' : '90%')
  }

  @Builder
  secondaryActionsBuilder(isWide: boolean) {
    Column({ space: 8 }) {
      Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.SpaceBetween }) {
        this.actionButton({ text: '切换模式', width: '32%', style: BUTTON_STYLE_TERTIARY, action: (): void => this.confirmSwitchMode() })
        this.actionButton({ text: '成就', width: '32%', style: BUTTON_STYLE_TERTIARY, action: (): void => this.openAchievementsPanel() })
        this.actionButton({ text: '统计', width: '32%', style: BUTTON_STYLE_TERTIARY, action: (): void => this.openStatisticsPanel() })
      }
      .width('100%')
      this.actionButton({ text: '游戏说明', width: '100%', style: BUTTON_STYLE_TERTIARY, action: (): void => this.showGameRules() })
    }
    .width(isWide ? '100%' : '90%')
  }

  @Builder
  actionButton(params: ActionButtonParams) {
    Button(params.text)
      .type(ButtonType.Normal)
      .width(params.width)
      .height(44)
      .backgroundColor(this.getActionButtonBg(params.style, params.enabled !== false))
      .fontColor(this.getActionButtonTextColor(params.style, params.enabled !== false))
      .border({ width: params.style === BUTTON_STYLE_TERTIARY ? 1 : 0, color: $r('app.color.n_card_border'), radius: 12 })
      .fontSize(13)
      .enabled(params.enabled !== false)
      .onClick(params.action)
  }

  @Builder
  infoRowBuilder(containerWidth: string) {
    Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.SpaceEvenly }) {
      this.infoBuilder({ info: '积分', text: this.score.toString(), width: '30%' })
      this.infoBuilder({ info: '最高', text: this.bestScore.toString(), width: '30%' })
      this.infoBuilder({ info: this.currentMode === GameMode.MOVE_LIMIT ? '剩余步数' : '步数', text: this.getStepInfoText(), width: '30%' })
    }
    .width(containerWidth)
  }

  @Builder
  infoBuilder(params: InfoBuilderParams) {
    Column() {
      Text(params.info)
        .fontSize(11)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.n_secondary_text'))
      Text(params.text)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.n_font_color'))
    }
    .justifyContent(FlexAlign.Center)
    .width(params.width)
    .height(56)
    .backgroundColor($r('app.color.n_cm_bg_color'))
    .border({ width: 1, color: $r('app.color.n_card_border'), radius: 14 })
  }

  @Builder
  boardBuilder() {
    Column() {
      this.gridBuilder()
    }
    .width(this.getBoardSize())
    .height(this.getBoardSize())
    .padding(10)
    .backgroundColor($r('app.color.n_board_bg'))
    .borderRadius(16)
    .focusable(true)
    .focusOnTouch(true)
    .defaultFocus(true)
    .onClick(() => this.requestBoardFocus())
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.requestBoardFocus();
      }
    })
    .onAppear(() => this.requestBoardFocus())
    .onKeyEvent((event: KeyEvent) => {
      return this.handleKeyEvent(event);
    })
  }

  @Builder
  keyboardHintBuilder(isWide: boolean) {
    Text(isWide ? '键盘：方向键或 W A S D 移动' : '提示：支持方向键 / W A S D')
      .fontSize(12)
      .fontColor($r('app.color.n_secondary_text'))
      .width(isWide ? '100%' : '90%')
      .textAlign(TextAlign.Center)
  }

  @Builder
  achievementToastBuilder(achievement: Achievement) {
    Column({ space: 4 }) {
      Text('解锁成就')
        .fontSize(12)
        .fontColor($r('app.color.n_primary'))
        .fontWeight(FontWeight.Bold)
      Text(achievement.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.n_font_color'))
      Text(achievement.description)
        .fontSize(12)
        .fontColor($r('app.color.n_secondary_text'))
    }
    .width(this.isWideScreen() ? 280 : '82%')
    .padding(14)
    .backgroundColor($r('app.color.n_cm_bg_color'))
    .border({ width: 1, color: $r('app.color.n_card_border'), radius: 16 })
    .position({ x: this.isWideScreen() ? this.contentWidth - 330 : this.contentWidth * 0.09, y: 24 })
    .opacity(this.achievementVisible ? 1 : 0)
    .scale({ x: this.achievementVisible ? 1 : 0.9, y: this.achievementVisible ? 1 : 0.9 })
    .zIndex(10)
  }

  @Builder
  settlementOverlayBuilder() {
    Column() {
      Column({ space: 12 }) {
        Text(this.getSettlementTitle())
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.n_font_color'))
        this.settlementInfoRow('最终分数', this.settlementScore.toString())
        this.settlementInfoRow('最大数字', this.settlementMaxTile.toString())
        this.settlementInfoRow('有效步数', this.settlementSteps.toString())
        this.settlementInfoRow('本模式最高分', this.settlementBestScore.toString())
        if (this.settlementReason === SETTLEMENT_TIME_UP || this.settlementReason === SETTLEMENT_MOVE_LIMIT_REACHED) {
          Row({ space: 10 }) {
            this.settlementButton('再来一局', () => this.reset(), '48%')
            this.settlementButton('返回模式选择', () => this.returnToModeSelection(), '48%')
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
        } else if (this.settlementReason === SETTLEMENT_NO_MOVES) {
          if (this.canUndo) {
            Row({ space: 10 }) {
              this.settlementButton('撤销一步', () => this.undoLastMove(), '48%')
              this.settlementButton('重新开始', () => this.reset(), '48%')
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            this.settlementButton('返回模式选择', () => this.returnToModeSelection(), '100%')
          } else {
            Row({ space: 10 }) {
              this.settlementButton('重新开始', () => this.reset(), '48%')
              this.settlementButton('返回模式选择', () => this.returnToModeSelection(), '48%')
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
          }
        } else {
          Row({ space: 10 }) {
            this.settlementButton('继续游戏', () => this.closeSettlementOverlay(), '48%')
            this.settlementButton('开始新游戏', () => this.reset(), '48%')
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
        }
      }
      .width(this.isWideScreen() ? 420 : '84%')
      .padding(20)
      .backgroundColor('#FFFFFF')
      .border({ width: 1, color: $r('app.color.n_card_border'), radius: 16 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#99000000')
    .zIndex(20)
  }

  @Builder
  settlementInfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor($r('app.color.n_secondary_text'))
      Blank()
      Text(value)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.n_font_color'))
    }
    .width('100%')
  }

  @Builder
  settlementButton(text: string, action: () => void, width: Length) {
    Button(text)
      .type(ButtonType.Normal)
      .width(width)
      .height(44)
      .backgroundColor($r('app.color.n_primary'))
      .fontColor('#FFFFFF')
      .borderRadius(12)
      .fontSize(13)
      .onClick(action)
  }

  @Builder
  achievementPanelBuilder() {
    Scroll() {
      Column({ space: 14 }) {
        HdNav({ title: '成就', showRightIcon: false })
        this.panelHeaderBuilder('成就', `${this.getUnlockedAchievementCount()} / ${this.achievements.length} 已解锁`)
        Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Center }) {
          ForEach(this.achievements, (item: Achievement) => {
            this.achievementItemBuilder(item)
          }, (item: Achievement) => item.id)
        }
        .width(this.isWideScreen() ? '86%' : '90%')
        this.actionButton({ text: '返回游戏', width: this.isWideScreen() ? '30%' : '90%', style: BUTTON_STYLE_PRIMARY, action: (): void => this.closePanels() })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .padding({ bottom: 24 })
    }
    .width('100%')
    .height('100%')
    .scrollable(ScrollDirection.Vertical)
  }

  @Builder
  achievementItemBuilder(item: Achievement) {
    Column({ space: 8 }) {
      Text(item.unlocked ? '已解锁' : '未解锁')
        .fontSize(12)
        .fontColor(item.unlocked ? $r('app.color.n_primary') : $r('app.color.n_secondary_text'))
      Text(item.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(item.unlocked ? $r('app.color.n_font_color') : $r('app.color.n_secondary_text'))
      Text(item.description)
        .fontSize(13)
        .fontColor($r('app.color.n_secondary_text'))
      Text(item.unlockedAt.length > 0 ? item.unlockedAt : '暂无解锁时间')
        .fontSize(11)
        .fontColor($r('app.color.n_secondary_text'))
    }
    .alignItems(HorizontalAlign.Start)
    .width(this.isWideScreen() ? '46%' : '100%')
    .padding(14)
    .margin(6)
    .backgroundColor(item.unlocked ? $r('app.color.n_cm_bg_color') : '#F0ECF6')
    .border({ width: 1, color: $r('app.color.n_card_border'), radius: 14 })
  }

  @Builder
  statisticsPanelBuilder() {
    Scroll() {
      Column({ space: 14 }) {
        HdNav({ title: '数据统计', showRightIcon: false })
        this.panelHeaderBuilder('数据统计', this.statistics.totalGames === 0 ? '暂无完成局数' : `最近：${this.statistics.lastPlayedAt}`)
        Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Center }) {
          this.statCardBuilder('总局数', this.statistics.totalGames.toString())
          this.statCardBuilder('胜率', this.getWinRateText())
          this.statCardBuilder('最高分', this.statistics.bestScore.toString())
          this.statCardBuilder('最大数字', this.statistics.maxTile.toString())
          this.statCardBuilder('累计步数', this.statistics.totalMoves.toString())
          this.statCardBuilder('最少 2048', this.statistics.bestStepsTo2048 === 0 ? '暂无' : this.statistics.bestStepsTo2048.toString())
        }
        .width(this.isWideScreen() ? '86%' : '90%')
        this.recentRecordsBuilder()
        this.actionButton({ text: '返回游戏', width: this.isWideScreen() ? '30%' : '90%', style: BUTTON_STYLE_PRIMARY, action: (): void => this.closePanels() })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .padding({ bottom: 24 })
    }
    .width('100%')
    .height('100%')
    .scrollable(ScrollDirection.Vertical)
  }

  @Builder
  panelHeaderBuilder(title: string, subtitle: string) {
    Column({ space: 6 }) {
      Text(title)
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.n_font_color'))
      Text(subtitle)
        .fontSize(13)
        .fontColor($r('app.color.n_secondary_text'))
    }
    .width('90%')
    .alignItems(this.isWideScreen() ? HorizontalAlign.Center : HorizontalAlign.Start)
  }

  @Builder
  statCardBuilder(label: string, value: string) {
    Column({ space: 4 }) {
      Text(label)
        .fontSize(12)
        .fontColor($r('app.color.n_secondary_text'))
      Text(value)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.n_font_color'))
    }
    .justifyContent(FlexAlign.Center)
    .width(this.isWideScreen() ? '30%' : '46%')
    .height(78)
    .margin(5)
    .backgroundColor($r('app.color.n_cm_bg_color'))
    .border({ width: 1, color: $r('app.color.n_card_border'), radius: 14 })
  }

  @Builder
  recentRecordsBuilder() {
    Column({ space: 8 }) {
      Text('最近 5 局')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.n_font_color'))
      if (this.statistics.recentRecords.length === 0) {
        Text('暂无记录，完成一局后会显示在这里。')
          .fontSize(13)
          .fontColor($r('app.color.n_secondary_text'))
      } else {
        ForEach(this.statistics.recentRecords, (item: GameRecord, index: number) => {
          Row() {
            Text(`${getModeName(item.mode)} · ${this.getResultText(item.result)}`)
              .fontSize(13)
              .fontColor($r('app.color.n_font_color'))
            Blank()
            Text(`${item.score} 分 / ${item.maxTile}`)
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.n_primary'))
          }
          .width('100%')
          .padding(10)
          .backgroundColor('#F7F3FC')
          .borderRadius(10)
        }, (_item: GameRecord, index: number) => index.toString())
      }
    }
    .width(this.isWideScreen() ? '72%' : '90%')
    .padding(14)
    .backgroundColor($r('app.color.n_cm_bg_color'))
    .border({ width: 1, color: $r('app.color.n_card_border'), radius: 14 })
  }

  async aboutToAppear(): Promise<void> {
    this.initImageHashMap();
    this.refreshBoardCells();
    await this.preferencesUtil.getPreferencesFromStorage();
    this.modeBestScores = await this.statisticsStore.loadModeBestScores();
    this.bestScore = this.statisticsStore.getBestScore(this.modeBestScores, this.currentMode);
    this.achievements = this.mergeAchievementStates(await this.achievementStore.loadAchievements(), this.achievements);
    this.statistics = await this.statisticsStore.loadStatistics();
    if (!this.restorePendingSnapshotIfNeeded()) {
      this.publishSnapshot();
    }
    this.startTimedTimerIfNeeded();
  }

  aboutToDisappear(): void {
    this.stopTimedTimer();
    this.publishSnapshot();
  }

  startNewGame(mode: GameMode): void {
    this.currentMode = mode;
    this.modeSelected = true;
    this.reset();
  }

  reset(): void {
    this.stopTimedTimer();
    this.board = new Board();
    this.refreshBoardCells();
    this.score = this.board.score;
    this.stepCount = 0;
    this.remainingSeconds = TIMED_TOTAL_SECONDS;
    this.remainingMoves = MOVE_LIMIT_TOTAL_MOVES;
    this.gameEnded = false;
    this.lost = false;
    this.won = false;
    this.victoryPromptShown = false;
    this.lostPromptShown = false;
    this.settlementPromptShown = false;
    this.roundRecorded = false;
    this.pendingSettlementReason = SETTLEMENT_NONE;
    this.achievementQueue = [];
    this.currentAchievement = undefined;
    this.achievementVisible = false;
    this.clearSettlementState();
    this.bestScore = this.statisticsStore.getBestScore(this.modeBestScores, this.currentMode);
    this.clearUndoSnapshot();
    this.publishSnapshot();
    this.startTimedTimerIfNeeded();
    this.requestBoardFocus();
  }

  @Builder
  gridBuilder() {
    Grid(undefined, { regularSize: [1, 1] }) {
      ForEach(this.boardCellsArray, (row: BoardCellView[]) => {
        ForEach(row, (item: BoardCellView) => {
          this.tileBuilder(item)
        }, (item: BoardCellView) => item.key)
      }, (_item: BoardCellView[], index: number) => `${this.boardRenderVersion}-${index}`)
    }
    .columnsGap(8)
    .rowsGap(8)
    .maxCount(4)
    .columnsTemplate('1fr 1fr 1fr 1fr')
    .rowsTemplate('1fr 1fr 1fr 1fr')
    .width('100%')
    .height('100%')
    .layoutDirection(GridDirection.Row)
    .gesture(GestureGroup(GestureMode.Exclusive,
      PanGesture({ direction: PanDirection.Left }).onActionEnd(() => this.handleMove(0)),
      PanGesture({ direction: PanDirection.Right }).onActionEnd(() => this.handleMove(2)),
      PanGesture({ direction: PanDirection.Up }).onActionEnd(() => this.handleMove(1)),
      PanGesture({ direction: PanDirection.Down }).onActionEnd(() => this.handleMove(3))
    ))
  }

  async handleMove(direction: number): Promise<void> {
    if (!this.modeSelected || this.hasBlockingPanel() || this.gameEnded) {
      return;
    }
    const beforeSnapshot = this.createSnapshot();
    const beforeValues: number[][] = this.getBoardValues(this.board.cells);
    this.board.move(direction);
    const moved = this.isBoardChanged(beforeValues, this.board.cells);
    if (moved) {
      this.refreshBoardCells();
      this.setUndoSnapshot(beforeSnapshot);
      this.stepCount += 1;
      if (this.currentMode === GameMode.MOVE_LIMIT && this.remainingMoves > 0) {
        this.remainingMoves -= 1;
      }
    }
    await this.updateGameStatus(moved);
    if (moved) {
      this.publishSnapshot();
    }
  }

  async updateGameStatus(moved: boolean): Promise<void> {
    this.score = this.board.score;
    this.modeBestScores = await this.statisticsStore.updateBestScore(this.modeBestScores, this.currentMode, this.score);
    this.bestScore = this.statisticsStore.getBestScore(this.modeBestScores, this.currentMode);
    await this.checkAchievements();

    if (this.board.hasWon() && !this.won) {
      this.won = true;
      await this.requestSettlement(SETTLEMENT_WIN);
      return;
    }
    if (moved && this.currentMode === GameMode.MOVE_LIMIT && this.remainingMoves <= 0 && !this.gameEnded) {
      await this.requestSettlement(this.won ? SETTLEMENT_WIN : SETTLEMENT_MOVE_LIMIT_REACHED);
      return;
    }
    if (moved && this.board.hasLost() && !this.gameEnded) {
      await this.requestSettlement(SETTLEMENT_NO_MOVES);
    }
  }

  undoLastMove(): void {
    if (this.undoSnapshot === undefined) {
      this.showMessage('撤销一步', '暂无可撤销操作');
      return;
    }

    const snapshot = this.cloneSnapshot(this.undoSnapshot);
    if (this.restoreSnapshot(snapshot, false)) {
      this.clearUndoSnapshot();
      this.lostPromptShown = false;
      this.settlementPromptShown = false;
      this.pendingSettlementReason = SETTLEMENT_NONE;
      this.clearSettlementState();
      this.showMessage('撤销一步', '已恢复到上一步。');
    } else {
      this.clearUndoSnapshot();
      this.showMessage('撤销一步', '撤销快照无效，未恢复。');
    }
  }

  async recordRoundIfNeeded(result: string): Promise<void> {
    if (this.roundRecorded) {
      return;
    }
    this.roundRecorded = true;
    const record: GameRecord = {
      mode: this.currentMode,
      score: this.score,
      maxTile: this.getMaxTile(),
      steps: this.stepCount,
      result: result,
      playedAt: new Date().toLocaleString(),
      remainingSeconds: this.remainingSeconds,
      remainingMoves: this.remainingMoves
    };
    this.statistics = await this.statisticsStore.recordGame(this.statistics, record);
    await this.checkAchievements();
  }

  getSettlementResult(reason: string): string {
    if (reason === SETTLEMENT_WIN) {
      return RESULT_WIN;
    }
    if (reason === SETTLEMENT_TIME_UP) {
      return RESULT_TIMEOUT;
    }
    if (reason === SETTLEMENT_MOVE_LIMIT_REACHED) {
      return RESULT_MOVE_LIMIT;
    }
    return RESULT_LOSE;
  }

  async checkAchievements(): Promise<void> {
    const unlocked = await this.achievementStore.unlockByGameState(this.achievements, this.getMaxTile(), this.stepCount,
      this.score, this.currentMode, this.statistics.totalGames);
    if (unlocked.length > 0) {
      this.achievements = this.achievements.slice();
      this.enqueueAchievements(unlocked);
    }
  }

  mergeAchievementStates(loaded: Achievement[], current: Achievement[]): Achievement[] {
    return loaded.map((item: Achievement) => {
      const currentItem = current.find((candidate: Achievement) => candidate.id === item.id);
      if (currentItem !== undefined && currentItem.unlocked && !item.unlocked) {
        return {
          id: item.id,
          title: item.title,
          description: item.description,
          unlocked: true,
          unlockedAt: currentItem.unlockedAt
        };
      }
      return item;
    });
  }

  enqueueAchievements(unlocked: Achievement[]): void {
    this.achievementQueue = this.achievementQueue.concat(unlocked);
    this.showNextAchievement();
  }

  showNextAchievement(): void {
    if (this.achievementVisible || this.achievementQueue.length === 0) {
      return;
    }
    this.currentAchievement = this.achievementQueue[0];
    this.achievementQueue = this.achievementQueue.slice(1);
    this.achievementVisible = true;
    setTimeout(() => {
      this.achievementVisible = false;
      this.currentAchievement = undefined;
      this.showNextAchievement();
    }, 2400);
  }

  showPendingSettlementIfReady(): void {
    if (this.pendingSettlementReason === SETTLEMENT_NONE || this.settlementVisible) {
      return;
    }
    const reason = this.pendingSettlementReason;
    this.pendingSettlementReason = SETTLEMENT_NONE;
    this.showSettlement(reason);
  }

  showSettlement(reason: string): void {
    this.settlementReason = reason;
    this.settlementVisible = true;
    this.settlementPromptShown = true;
  }

  startTimedTimerIfNeeded(): void {
    if (!this.modeSelected || this.currentMode !== GameMode.TIMED || this.gameEnded || this.timerId !== -1) {
      return;
    }
    this.timerId = setInterval(() => {
      if (this.remainingSeconds > 0) {
        this.remainingSeconds -= 1;
        this.publishSnapshot();
      }
      if (this.remainingSeconds <= 0) {
        this.finishTimedGame();
      }
    }, 1000);
  }

  stopTimedTimer(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  async finishTimedGame(): Promise<void> {
    this.remainingSeconds = 0;
    await this.requestSettlement(this.won ? SETTLEMENT_WIN : SETTLEMENT_TIME_UP);
  }

  async requestSettlement(reason: string): Promise<void> {
    if (this.settlementVisible || this.pendingSettlementReason !== SETTLEMENT_NONE) {
      return;
    }
    this.stopTimedTimer();
    this.gameEnded = true;
    this.won = reason === SETTLEMENT_WIN;
    this.lost = reason !== SETTLEMENT_WIN;
    this.modeBestScores = await this.statisticsStore.updateBestScore(this.modeBestScores, this.currentMode, this.score);
    this.bestScore = this.statisticsStore.getBestScore(this.modeBestScores, this.currentMode);
    this.settlementScore = this.score;
    this.settlementSteps = this.stepCount;
    this.settlementMaxTile = this.getMaxTile();
    this.settlementBestScore = this.bestScore;
    this.pendingSettlementReason = reason;
    this.showPendingSettlementIfReady();
    this.publishSnapshot();
    await this.recordRoundIfNeeded(this.getSettlementResult(reason));
    this.publishSnapshot();
  }

  handleKeyEvent(event: KeyEvent): boolean {
    if (event.type !== KeyType.Down || this.hasBlockingPanel() || this.gameEnded) {
      return false;
    }
    if (this.isKeyCode(event.keyCode, KeyCode.KEYCODE_DPAD_LEFT, KEYCODE_DPAD_LEFT) ||
      this.isKeyCode(event.keyCode, KeyCode.KEYCODE_A, KEYCODE_A)) {
      this.handleMove(0);
      return true;
    } else if (this.isKeyCode(event.keyCode, KeyCode.KEYCODE_DPAD_UP, KEYCODE_DPAD_UP) ||
      this.isKeyCode(event.keyCode, KeyCode.KEYCODE_W, KEYCODE_W)) {
      this.handleMove(1);
      return true;
    } else if (this.isKeyCode(event.keyCode, KeyCode.KEYCODE_DPAD_RIGHT, KEYCODE_DPAD_RIGHT) ||
      this.isKeyCode(event.keyCode, KeyCode.KEYCODE_D, KEYCODE_D)) {
      this.handleMove(2);
      return true;
    } else if (this.isKeyCode(event.keyCode, KeyCode.KEYCODE_DPAD_DOWN, KEYCODE_DPAD_DOWN) ||
      this.isKeyCode(event.keyCode, KeyCode.KEYCODE_S, KEYCODE_S)) {
      this.handleMove(3);
      return true;
    }
    return false;
  }

  isKeyCode(actual: number, expected: number, fallback: number): boolean {
    return actual === expected || actual === fallback;
  }

  confirmSwitchMode(): void {
    AlertDialog.show({
      title: '切换模式',
      message: '切换模式会结束当前局并回到模式选择。',
      primaryButton: { value: '继续当前局', action: () => this.requestBoardFocus() },
      secondaryButton: {
        value: '切换模式',
        action: () => {
          this.stopTimedTimer();
          this.modeSelected = false;
          this.gameEnded = true;
          this.publishSnapshot();
        }
      }
    });
  }

  openAchievementsPanel(): void {
    this.showStatisticsPanel = false;
    this.showAchievementsPanel = true;
  }

  openStatisticsPanel(): void {
    this.showAchievementsPanel = false;
    this.showStatisticsPanel = true;
  }

  closePanels(): void {
    this.showAchievementsPanel = false;
    this.showStatisticsPanel = false;
    this.startTimedTimerIfNeeded();
    this.requestBoardFocus();
  }

  returnToModeSelection(): void {
    this.stopTimedTimer();
    this.modeSelected = false;
    this.gameEnded = true;
    this.clearSettlementState();
    this.publishSnapshot();
  }

  closeSettlementOverlay(): void {
    this.clearSettlementState();
    this.gameEnded = false;
    this.requestBoardFocus();
  }

  clearSettlementState(): void {
    this.settlementVisible = false;
    this.settlementReason = SETTLEMENT_NONE;
    this.settlementScore = 0;
    this.settlementSteps = 0;
    this.settlementMaxTile = 0;
    this.settlementBestScore = 0;
    this.settlementPromptShown = false;
    this.pendingSettlementReason = SETTLEMENT_NONE;
  }

  showGameRules(): void {
    AlertDialog.show({
      title: '游戏说明',
      message: '上下左右滑动棋盘移动所有数字方块，相同数字相撞会合并并计分。经典模式没有限制；限时挑战为 90 秒倒计时；步数挑战只有 50 次有效移动。宽屏和 2in1 设备支持方向键与 W A S D。',
      primaryButton: { value: '知道了', action: () => this.requestBoardFocus() }
    });
  }

  saveSimulationSnapshot(): void {
    this.publishSnapshot();
    if (GameStateStore.saveSimulationSnapshot()) {
      this.showMessage('模拟快照', '模拟快照已保存。');
    } else {
      this.showMessage('模拟快照', '当前没有可保存的模拟快照。');
    }
  }

  restoreSimulationSnapshot(): void {
    if (!GameStateStore.prepareSimulationRestore()) {
      this.showMessage('模拟快照', '暂无可恢复的模拟快照。');
      return;
    }

    if (this.restorePendingSnapshotIfNeeded()) {
      this.clearUndoSnapshot();
      this.showMessage('模拟快照', '模拟快照已恢复。');
    } else {
      this.showMessage('模拟快照', '模拟快照无效，未恢复。');
    }
  }

  showMessage(title: string, message: string): void {
    AlertDialog.show({
      title: title,
      message: message,
      primaryButton: { value: '知道了', action: () => {} }
    });
  }

  restorePendingSnapshotIfNeeded(): boolean {
    const pendingSnapshot = GameStateStore.consumePendingSnapshot();
    if (pendingSnapshot === undefined) {
      return false;
    }
    return this.restoreSnapshot(pendingSnapshot);
  }

  restoreSnapshot(snapshot: GameSnapshot, clearUndo: boolean = true): boolean {
    this.stopTimedTimer();
    if (!this.board.restoreFromValues(snapshot.cells, snapshot.score, snapshot.won)) {
      return false;
    }

    this.refreshBoardCells();
    this.score = snapshot.score;
    this.stepCount = snapshot.stepCount;
    this.currentMode = snapshot.mode;
    this.modeSelected = true;
    this.remainingSeconds = snapshot.remainingSeconds;
    this.remainingMoves = snapshot.remainingMoves;
    this.gameEnded = snapshot.gameEnded;
    this.bestScore = this.statisticsStore.getBestScore(this.modeBestScores, this.currentMode);
    this.won = snapshot.won;
    this.lost = snapshot.lost;
    this.victoryPromptShown = snapshot.won;
    this.lostPromptShown = snapshot.lost;
    this.settlementPromptShown = false;
    this.roundRecorded = snapshot.gameEnded || snapshot.won || snapshot.lost;
    if (clearUndo) {
      this.clearUndoSnapshot();
    }
    this.publishSnapshot();
    if (this.currentMode === GameMode.TIMED && this.remainingSeconds <= 0) {
      if (this.roundRecorded || this.gameEnded) {
        this.remainingSeconds = 0;
        this.gameEnded = true;
        this.lost = !this.won;
        this.stopTimedTimer();
        this.settlementScore = this.score;
        this.settlementSteps = this.stepCount;
        this.settlementMaxTile = this.getMaxTile();
        this.settlementBestScore = this.bestScore;
        this.pendingSettlementReason = SETTLEMENT_TIME_UP;
        this.showPendingSettlementIfReady();
        this.publishSnapshot();
      } else {
        this.finishTimedGame();
      }
    } else {
      this.startTimedTimerIfNeeded();
      this.requestBoardFocus();
    }
    return true;
  }

  createSnapshot(): GameSnapshot {
    return {
      version: GAME_SNAPSHOT_VERSION,
      cells: this.board.exportCellValues(),
      score: this.score,
      stepCount: this.stepCount,
      bestScore: this.bestScore,
      won: this.won,
      lost: this.lost,
      mode: this.currentMode,
      remainingSeconds: this.remainingSeconds,
      remainingMoves: this.remainingMoves,
      gameEnded: this.gameEnded,
      timerStartedAt: this.currentMode === GameMode.TIMED && this.timerId !== -1 ? Date.now() : 0
    };
  }

  cloneSnapshot(snapshot: GameSnapshot): GameSnapshot {
    return {
      version: snapshot.version,
      cells: snapshot.cells.slice(),
      score: snapshot.score,
      stepCount: snapshot.stepCount,
      bestScore: snapshot.bestScore,
      won: snapshot.won,
      lost: snapshot.lost,
      mode: snapshot.mode,
      remainingSeconds: snapshot.remainingSeconds,
      remainingMoves: snapshot.remainingMoves,
      gameEnded: snapshot.gameEnded,
      timerStartedAt: snapshot.timerStartedAt
    };
  }

  setUndoSnapshot(snapshot: GameSnapshot): void {
    this.undoSnapshot = this.cloneSnapshot(snapshot);
    this.canUndo = true;
  }

  clearUndoSnapshot(): void {
    this.undoSnapshot = undefined;
    this.canUndo = false;
  }

  publishSnapshot(): void {
    GameStateStore.setLatestSnapshot(this.createSnapshot());
  }

  getBoardValues(cells: Tile[][]): number[][] {
    let values: number[][] = [];
    for (let rowIndex = 0; rowIndex < cells.length; rowIndex++) {
      let rowValues: number[] = [];
      for (let columnIndex = 0; columnIndex < cells[rowIndex].length; columnIndex++) {
        rowValues.push(cells[rowIndex][columnIndex].value);
      }
      values.push(rowValues);
    }
    return values;
  }

  isBoardChanged(beforeValues: number[][], afterCells: Tile[][]): boolean {
    for (let rowIndex = 0; rowIndex < afterCells.length; rowIndex++) {
      for (let columnIndex = 0; columnIndex < afterCells[rowIndex].length; columnIndex++) {
        if (beforeValues[rowIndex][columnIndex] !== afterCells[rowIndex][columnIndex].value) {
          return true;
        }
      }
    }
    return false;
  }

  getMaxTile(): number {
    let maxTile = 0;
    for (let rowIndex = 0; rowIndex < this.board.cells.length; rowIndex++) {
      for (let columnIndex = 0; columnIndex < this.board.cells[rowIndex].length; columnIndex++) {
        maxTile = Math.max(maxTile, this.board.cells[rowIndex][columnIndex].value);
      }
    }
    return maxTile;
  }

  refreshBoardCells(): void {
    this.boardRenderVersion += 1;
    let rows: BoardCellView[][] = [];
    for (let rowIndex = 0; rowIndex < this.board.cells.length; rowIndex++) {
      let row: BoardCellView[] = [];
      for (let columnIndex = 0; columnIndex < this.board.cells[rowIndex].length; columnIndex++) {
        const tile = this.board.cells[rowIndex][columnIndex];
        row.push({
          id: tile.id,
          key: `${this.boardRenderVersion}-${rowIndex}-${columnIndex}-${tile.id}-${tile.value}`,
          value: tile.value,
          row: rowIndex,
          column: columnIndex,
          isNew: tile.isNew(),
          mergedThisTurn: tile.mergedThisTurn
        });
      }
      rows.push(row);
    }
    this.boardCellsArray = rows;
  }

  requestBoardFocus(): void {
    if (!this.modeSelected || this.hasBlockingPanel() || this.gameEnded) {
      return;
    }
    focusControl.requestFocus(KEY_TARGET_FOCUS_ID);
    setTimeout(() => {
      if (this.modeSelected && !this.hasBlockingPanel() && !this.gameEnded) {
        focusControl.requestFocus(KEY_TARGET_FOCUS_ID);
      }
    }, 0);
  }

  getModeBestScore(mode: GameMode): number {
    return this.statisticsStore.getBestScore(this.modeBestScores, mode);
  }

  getModeDescription(): string {
    if (this.currentMode === GameMode.TIMED) {
      return '90 秒倒计时，时间归零后立即结算。';
    }
    if (this.currentMode === GameMode.MOVE_LIMIT) {
      return '只有棋盘变化才消耗步数，剩余步数归零后结算。';
    }
    return '标准 2048 规则，可一直玩到胜利或无路可走。';
  }

  getModeStatusText(): string {
    if (this.currentMode === GameMode.TIMED) {
      return `${this.remainingSeconds}s`;
    }
    if (this.currentMode === GameMode.MOVE_LIMIT) {
      return `${this.remainingMoves} 步`;
    }
    return '无上限';
  }

  getStepInfoText(): string {
    return this.currentMode === GameMode.MOVE_LIMIT ? this.remainingMoves.toString() : this.stepCount.toString();
  }

  getWinRateText(): string {
    if (this.statistics.totalGames <= 0) {
      return '0%';
    }
    return `${Math.round(this.statistics.wins * 100 / this.statistics.totalGames)}%`;
  }

  getUnlockedAchievementCount(): number {
    return this.achievements.filter((item: Achievement) => item.unlocked).length;
  }

  getResultText(result: string): string {
    if (result === RESULT_WIN) {
      return '胜利';
    }
    if (result === RESULT_TIMEOUT) {
      return '时间结束';
    }
    if (result === RESULT_MOVE_LIMIT) {
      return '步数用尽';
    }
    return '失败';
  }

  getSettlementTitle(): string {
    if (this.settlementReason === SETTLEMENT_TIME_UP) {
      return '时间到';
    }
    if (this.settlementReason === SETTLEMENT_NO_MOVES) {
      return '本局结束';
    }
    if (this.settlementReason === SETTLEMENT_MOVE_LIMIT_REACHED) {
      return '步数挑战结束';
    }
    return '恭喜合成 2048';
  }

  hasBlockingPanel(): boolean {
    return this.showAchievementsPanel || this.showStatisticsPanel || this.settlementVisible || !this.modeSelected;
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

  getActionButtonBg(style: string | undefined, enabled: boolean): string {
    if (!enabled) {
      return '#E8E1F0';
    }
    if (style === BUTTON_STYLE_PRIMARY) {
      return '#49318C';
    }
    if (style === BUTTON_STYLE_SECONDARY) {
      return '#6C4CCF';
    }
    return '#FFFFFF';
  }

  getActionButtonTextColor(style: string | undefined, enabled: boolean): string {
    if (!enabled) {
      return '#9A91A8';
    }
    if (style === BUTTON_STYLE_TERTIARY) {
      return '#49318C';
    }
    return '#FFFFFF';
  }

  @Builder
  tileBuilder(params: BoardCellView) {
    GridItem() {
      if (params.value > 0) {
        Image(this.getImageResource(params.value))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Contain)
          .scale({ x: params.mergedThisTurn ? 1.12 : 1, y: params.mergedThisTurn ? 1.12 : 1 })
          .opacity(params.isNew ? 0.92 : 1)
          .animation({ duration: 180, curve: Curve.EaseOut })
      }
    }
    .backgroundColor($r('app.color.n_empty_cell'))
    .borderRadius(10)
  }

  getImageResource(value: number): Resource {
    const resource = this.imageHashMap.get(value.toString());
    if (resource === undefined) {
      return $r('app.media.2');
    }
    return resource;
  }

  initImageHashMap(): void {
    this.imageHashMap.set('2', $r('app.media.2'));
    this.imageHashMap.set('4', $r('app.media.4'));
    this.imageHashMap.set('8', $r('app.media.8'));
    this.imageHashMap.set('16', $r('app.media.16'));
    this.imageHashMap.set('32', $r('app.media.32'));
    this.imageHashMap.set('64', $r('app.media.64'));
    this.imageHashMap.set('128', $r('app.media.128'));
    this.imageHashMap.set('256', $r('app.media.256'));
    this.imageHashMap.set('512', $r('app.media.512'));
    this.imageHashMap.set('1024', $r('app.media.1024'));
    this.imageHashMap.set('2048', $r('app.media.2048'));
  }
}
