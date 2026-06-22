import PreferencesUtil from './PreferencesUtil';
import {
  GameMode,
  GameRecord,
  GameStatistics,
  ModeBestScores,
  DEFAULT_BEST_SCORES,
  getDefaultStatistics,
  getModeBestScoreKey,
  sanitizeGameMode
} from './GameModels';

const STATS_KEY: string = 'number_statistics_v1';
const BEST_SCORES_KEY: string = 'number_mode_best_scores_v1';
const OLD_BEST_SCORE_KEY: string = 'number_best_score';

export default class StatisticsStore {
  private preferencesUtil: PreferencesUtil;

  constructor(preferencesUtil: PreferencesUtil) {
    this.preferencesUtil = preferencesUtil;
  }

  async loadModeBestScores(): Promise<ModeBestScores> {
    const rawValue = await this.preferencesUtil.getPreference(BEST_SCORES_KEY);
    const bestScores: ModeBestScores = {
      classic: DEFAULT_BEST_SCORES.classic,
      timed: DEFAULT_BEST_SCORES.timed,
      moveLimit: DEFAULT_BEST_SCORES.moveLimit
    };
    if (typeof rawValue === 'string' && rawValue.length > 0) {
      try {
        const parsed = JSON.parse(rawValue) as Record<string, Object>;
        bestScores.classic = this.safeNumber(parsed['classic']);
        bestScores.timed = this.safeNumber(parsed['timed']);
        bestScores.moveLimit = this.safeNumber(parsed['moveLimit']);
        return bestScores;
      } catch (error) {
        console.error(`Failed to parse mode best scores: ${JSON.stringify(error)}`);
      }
    }

    const oldBestScore = Number(await this.preferencesUtil.getPreference(OLD_BEST_SCORE_KEY));
    if (Number.isFinite(oldBestScore) && oldBestScore > 0) {
      bestScores.classic = oldBestScore;
    }
    return bestScores;
  }

  async saveModeBestScores(bestScores: ModeBestScores): Promise<void> {
    await this.preferencesUtil.putPreference(BEST_SCORES_KEY, JSON.stringify(bestScores));
  }

  async updateBestScore(bestScores: ModeBestScores, mode: GameMode, score: number): Promise<ModeBestScores> {
    const nextBestScores: ModeBestScores = {
      classic: bestScores.classic,
      timed: bestScores.timed,
      moveLimit: bestScores.moveLimit
    };
    let changed = false;
    if (mode === GameMode.TIMED && score > nextBestScores.timed) {
      nextBestScores.timed = score;
      changed = true;
    } else if (mode === GameMode.MOVE_LIMIT && score > nextBestScores.moveLimit) {
      nextBestScores.moveLimit = score;
      changed = true;
    } else if (mode === GameMode.CLASSIC && score > nextBestScores.classic) {
      nextBestScores.classic = score;
      changed = true;
    }
    if (changed) {
      this.saveModeBestScores(nextBestScores).catch((error: Error) => {
        console.error(`Failed to save mode best scores: ${JSON.stringify(error)}`);
      });
    }
    return nextBestScores;
  }

  getBestScore(bestScores: ModeBestScores, mode: GameMode): number {
    const key = getModeBestScoreKey(mode);
    if (key === 'timed') {
      return bestScores.timed;
    }
    if (key === 'moveLimit') {
      return bestScores.moveLimit;
    }
    return bestScores.classic;
  }

  async loadStatistics(): Promise<GameStatistics> {
    const rawValue = await this.preferencesUtil.getPreference(STATS_KEY);
    if (typeof rawValue !== 'string' || rawValue.length === 0) {
      return getDefaultStatistics();
    }
    try {
      const parsed = JSON.parse(rawValue) as Record<string, Object>;
      return this.parseStatistics(parsed);
    } catch (error) {
      console.error(`Failed to parse statistics: ${JSON.stringify(error)}`);
      return getDefaultStatistics();
    }
  }

  async saveStatistics(statistics: GameStatistics): Promise<void> {
    await this.preferencesUtil.putPreference(STATS_KEY, JSON.stringify(statistics));
  }

  async recordGame(statistics: GameStatistics, record: GameRecord): Promise<GameStatistics> {
    const nextStatistics: GameStatistics = {
      totalGames: statistics.totalGames + 1,
      classicGames: statistics.classicGames,
      timedGames: statistics.timedGames,
      moveLimitGames: statistics.moveLimitGames,
      wins: statistics.wins,
      losses: statistics.losses,
      bestScore: Math.max(statistics.bestScore, record.score),
      maxTile: Math.max(statistics.maxTile, record.maxTile),
      totalMoves: statistics.totalMoves + record.steps,
      bestStepsTo128: statistics.bestStepsTo128,
      bestStepsTo2048: statistics.bestStepsTo2048,
      lastPlayedAt: record.playedAt,
      recentRecords: [record].concat(statistics.recentRecords).slice(0, 5)
    };
    if (record.mode === GameMode.TIMED) {
      nextStatistics.timedGames += 1;
    } else if (record.mode === GameMode.MOVE_LIMIT) {
      nextStatistics.moveLimitGames += 1;
    } else {
      nextStatistics.classicGames += 1;
    }

    if (record.result === 'win') {
      nextStatistics.wins += 1;
    } else {
      nextStatistics.losses += 1;
    }
    if (record.maxTile >= 128 && (nextStatistics.bestStepsTo128 === 0 || record.steps < nextStatistics.bestStepsTo128)) {
      nextStatistics.bestStepsTo128 = record.steps;
    }
    if (record.maxTile >= 2048 && (nextStatistics.bestStepsTo2048 === 0 || record.steps < nextStatistics.bestStepsTo2048)) {
      nextStatistics.bestStepsTo2048 = record.steps;
    }
    this.saveStatistics(nextStatistics).catch((error: Error) => {
      console.error(`Failed to save statistics: ${JSON.stringify(error)}`);
    });
    return nextStatistics;
  }

  private parseStatistics(record: Record<string, Object>): GameStatistics {
    const statistics = getDefaultStatistics();
    statistics.totalGames = this.safeNumber(record['totalGames']);
    statistics.classicGames = this.safeNumber(record['classicGames']);
    statistics.timedGames = this.safeNumber(record['timedGames']);
    statistics.moveLimitGames = this.safeNumber(record['moveLimitGames']);
    statistics.wins = this.safeNumber(record['wins']);
    statistics.losses = this.safeNumber(record['losses']);
    statistics.bestScore = this.safeNumber(record['bestScore']);
    statistics.maxTile = this.safeNumber(record['maxTile']);
    statistics.totalMoves = this.safeNumber(record['totalMoves']);
    statistics.bestStepsTo128 = this.safeNumber(record['bestStepsTo128']);
    statistics.bestStepsTo2048 = this.safeNumber(record['bestStepsTo2048']);
    statistics.lastPlayedAt = typeof record['lastPlayedAt'] === 'string' ? record['lastPlayedAt'] as string : '';
    if (Array.isArray(record['recentRecords'])) {
      statistics.recentRecords = (record['recentRecords'] as Record<string, Object>[])
        .map((item: Record<string, Object>) => this.parseRecord(item))
        .slice(0, 5);
    }
    return statistics;
  }

  private parseRecord(record: Record<string, Object>): GameRecord {
    return {
      mode: sanitizeGameMode(typeof record['mode'] === 'string' ? record['mode'] as string : undefined),
      score: this.safeNumber(record['score']),
      maxTile: this.safeNumber(record['maxTile']),
      steps: this.safeNumber(record['steps']),
      result: typeof record['result'] === 'string' ? record['result'] as string : 'lose',
      playedAt: typeof record['playedAt'] === 'string' ? record['playedAt'] as string : '',
      remainingSeconds: this.safeNumber(record['remainingSeconds']),
      remainingMoves: this.safeNumber(record['remainingMoves'])
    };
  }

  private safeNumber(value: Object | undefined): number {
    const parsed = Number(value);
    return Number.isFinite(parsed) && parsed >= 0 ? parsed : 0;
  }
}
