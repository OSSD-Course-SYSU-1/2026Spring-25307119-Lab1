export enum GameMode {
  CLASSIC = 'classic',
  TIMED = 'timed',
  MOVE_LIMIT = 'move_limit'
}

export const TIMED_TOTAL_SECONDS: number = 90;
export const MOVE_LIMIT_TOTAL_MOVES: number = 50;
export const TIMED_MASTER_SCORE: number = 1000;

export interface ModeBestScores {
  classic: number
  timed: number
  moveLimit: number
}

export interface Achievement {
  id: string
  title: string
  description: string
  unlocked: boolean
  unlockedAt: string
}

export interface GameRecord {
  mode: GameMode
  score: number
  maxTile: number
  steps: number
  result: string
  playedAt: string
  remainingSeconds: number
  remainingMoves: number
}

export interface GameStatistics {
  totalGames: number
  classicGames: number
  timedGames: number
  moveLimitGames: number
  wins: number
  losses: number
  bestScore: number
  maxTile: number
  totalMoves: number
  bestStepsTo128: number
  bestStepsTo2048: number
  lastPlayedAt: string
  recentRecords: GameRecord[]
}

export const DEFAULT_BEST_SCORES: ModeBestScores = {
  classic: 0,
  timed: 0,
  moveLimit: 0
};

export function sanitizeGameMode(value: string | undefined): GameMode {
  if (value === GameMode.TIMED) {
    return GameMode.TIMED;
  }
  if (value === GameMode.MOVE_LIMIT) {
    return GameMode.MOVE_LIMIT;
  }
  return GameMode.CLASSIC;
}

export function getModeName(mode: GameMode): string {
  if (mode === GameMode.TIMED) {
    return '限时挑战';
  }
  if (mode === GameMode.MOVE_LIMIT) {
    return '步数挑战';
  }
  return '经典模式';
}

export function getModeBestScoreKey(mode: GameMode): string {
  if (mode === GameMode.TIMED) {
    return 'timed';
  }
  if (mode === GameMode.MOVE_LIMIT) {
    return 'moveLimit';
  }
  return 'classic';
}

export function getDefaultStatistics(): GameStatistics {
  return {
    totalGames: 0,
    classicGames: 0,
    timedGames: 0,
    moveLimitGames: 0,
    wins: 0,
    losses: 0,
    bestScore: 0,
    maxTile: 0,
    totalMoves: 0,
    bestStepsTo128: 0,
    bestStepsTo2048: 0,
    lastPlayedAt: '',
    recentRecords: []
  };
}

export function getAchievementDefinitions(): Achievement[] {
  return [
    { id: 'tile_32', title: '初出茅庐', description: '首次合成 32', unlocked: false, unlockedAt: '' },
    { id: 'tile_128', title: '小有成就', description: '首次合成 128', unlocked: false, unlockedAt: '' },
    { id: 'tile_512', title: '数字大师', description: '首次合成 512', unlocked: false, unlockedAt: '' },
    { id: 'tile_2048', title: '最终目标', description: '首次合成 2048', unlocked: false, unlockedAt: '' },
    { id: 'efficient_128', title: '效率玩家', description: '20 次有效移动以内合成 128', unlocked: false, unlockedAt: '' },
    { id: 'timed_master', title: '限时高手', description: `限时模式中达到 ${TIMED_MASTER_SCORE} 分`, unlocked: false, unlockedAt: '' },
    { id: 'ten_games', title: '坚持不懈', description: '完成 10 局游戏', unlocked: false, unlockedAt: '' }
  ];
}
