import { GameMode, MOVE_LIMIT_TOTAL_MOVES, TIMED_TOTAL_SECONDS, sanitizeGameMode } from './GameModels';

export interface GameSnapshot {
  version: number
  cells: number[]
  score: number
  stepCount: number
  bestScore: number
  won: boolean
  lost: boolean
  mode: GameMode
  remainingSeconds: number
  remainingMoves: number
  gameEnded: boolean
  timerStartedAt: number
}

export const GAME_SNAPSHOT_VERSION: number = 2;
export const GAME_SNAPSHOT_PARAM_KEY: string = 'game2048Snapshot';

class GameStateStoreImpl {
  private latestSnapshot: GameSnapshot | undefined = undefined;
  private pendingSnapshot: GameSnapshot | undefined = undefined;
  private simulationSnapshotJson: string = '';

  setLatestSnapshot(snapshot: GameSnapshot): void {
    const checkedSnapshot = this.validateSnapshot(snapshot);
    if (checkedSnapshot !== undefined) {
      this.latestSnapshot = this.cloneSnapshot(checkedSnapshot);
    }
  }

  getLatestSnapshot(): GameSnapshot | undefined {
    if (this.latestSnapshot === undefined) {
      return undefined;
    }
    return this.cloneSnapshot(this.latestSnapshot);
  }

  getLatestSnapshotJson(): string {
    if (this.latestSnapshot === undefined) {
      return '';
    }
    return JSON.stringify(this.latestSnapshot);
  }

  setPendingSnapshot(snapshot: GameSnapshot): boolean {
    const checkedSnapshot = this.validateSnapshot(snapshot);
    if (checkedSnapshot === undefined) {
      return false;
    }
    this.pendingSnapshot = this.cloneSnapshot(checkedSnapshot);
    return true;
  }

  setPendingSnapshotJson(snapshotJson: string): boolean {
    const snapshot = this.parseSnapshotJson(snapshotJson);
    if (snapshot === undefined) {
      return false;
    }
    this.pendingSnapshot = snapshot;
    return true;
  }

  consumePendingSnapshot(): GameSnapshot | undefined {
    if (this.pendingSnapshot === undefined) {
      return undefined;
    }
    const snapshot = this.cloneSnapshot(this.pendingSnapshot);
    this.pendingSnapshot = undefined;
    return snapshot;
  }

  saveSimulationSnapshot(): boolean {
    const snapshotJson = this.getLatestSnapshotJson();
    if (snapshotJson.length === 0) {
      return false;
    }
    this.simulationSnapshotJson = snapshotJson;
    return true;
  }

  prepareSimulationRestore(): boolean {
    if (this.simulationSnapshotJson.length === 0) {
      return false;
    }
    return this.setPendingSnapshotJson(this.simulationSnapshotJson);
  }

  parseSnapshotJson(snapshotJson: string): GameSnapshot | undefined {
    try {
      const parsedSnapshot: Object = JSON.parse(snapshotJson) as Object;
      if (typeof parsedSnapshot !== 'object' || parsedSnapshot === null || Array.isArray(parsedSnapshot)) {
        return undefined;
      }
      return this.validateSnapshotRecord(parsedSnapshot as Record<string, Object>);
    } catch (error) {
      console.error(`Failed to parse game snapshot: ${JSON.stringify(error)}`);
      return undefined;
    }
  }

  private validateSnapshot(snapshot: GameSnapshot): GameSnapshot | undefined {
    return this.validateSnapshotValues(snapshot.version, snapshot.cells, snapshot.score, snapshot.stepCount,
      snapshot.bestScore, snapshot.won, snapshot.lost, snapshot.mode, snapshot.remainingSeconds,
      snapshot.remainingMoves, snapshot.gameEnded, snapshot.timerStartedAt);
  }

  private validateSnapshotRecord(record: Record<string, Object>): GameSnapshot | undefined {
    return this.validateSnapshotValues(Number(record['version']), record['cells'], Number(record['score']),
      Number(record['stepCount']), Number(record['bestScore']), record['won'] === true, record['lost'] === true,
      sanitizeGameMode(typeof record['mode'] === 'string' ? record['mode'] as string : undefined),
      Number(record['remainingSeconds']), Number(record['remainingMoves']), record['gameEnded'] === true,
      Number(record['timerStartedAt']));
  }

  private validateSnapshotValues(version: number, cellsSource: Object, score: number, stepCount: number,
    bestScore: number, won: boolean, lost: boolean, mode: GameMode, remainingSeconds: number,
    remainingMoves: number, gameEnded: boolean, timerStartedAt: number): GameSnapshot | undefined {
    if (!Array.isArray(cellsSource) || cellsSource.length !== 16) {
      return undefined;
    }

    let cells: number[] = [];
    for (let index = 0; index < cellsSource.length; index++) {
      const cellValue = Number(cellsSource[index]);
      if (!Number.isFinite(cellValue) || cellValue < 0) {
        return undefined;
      }
      cells.push(cellValue);
    }

    const checkedVersion = Number.isFinite(version) && version > 0 ? version : 1;
    const safeScore = Number.isFinite(score) && score >= 0 ? score : 0;
    const safeStepCount = Number.isFinite(stepCount) && stepCount >= 0 ? stepCount : 0;
    const safeBestScore = Number.isFinite(bestScore) && bestScore >= 0 ? bestScore : 0;
    const safeRemainingSeconds = Number.isFinite(remainingSeconds) && remainingSeconds >= 0 ?
      remainingSeconds : TIMED_TOTAL_SECONDS;
    const safeRemainingMoves = Number.isFinite(remainingMoves) && remainingMoves >= 0 ?
      remainingMoves : MOVE_LIMIT_TOTAL_MOVES;
    const safeTimerStartedAt = Number.isFinite(timerStartedAt) && timerStartedAt >= 0 ? timerStartedAt : 0;

    return {
      version: checkedVersion <= GAME_SNAPSHOT_VERSION ? GAME_SNAPSHOT_VERSION : checkedVersion,
      cells: cells,
      score: safeScore,
      stepCount: safeStepCount,
      bestScore: safeBestScore,
      won: won,
      lost: lost,
      mode: mode,
      remainingSeconds: safeRemainingSeconds,
      remainingMoves: safeRemainingMoves,
      gameEnded: gameEnded || lost,
      timerStartedAt: safeTimerStartedAt
    };
  }

  private cloneSnapshot(snapshot: GameSnapshot): GameSnapshot {
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
}

const GameStateStore = new GameStateStoreImpl();

export default GameStateStore;
