import PreferencesUtil from './PreferencesUtil';
import { Achievement, GameMode, getAchievementDefinitions, TIMED_MASTER_SCORE } from './GameModels';

const ACHIEVEMENT_KEY: string = 'number_achievements_v1';

export default class AchievementStore {
  private preferencesUtil: PreferencesUtil;

  constructor(preferencesUtil: PreferencesUtil) {
    this.preferencesUtil = preferencesUtil;
  }

  async loadAchievements(): Promise<Achievement[]> {
    const rawValue = await this.preferencesUtil.getPreference(ACHIEVEMENT_KEY);
    if (typeof rawValue !== 'string' || rawValue.length === 0) {
      return getAchievementDefinitions();
    }

    try {
      const parsed = JSON.parse(rawValue) as Object;
      if (!Array.isArray(parsed)) {
        return getAchievementDefinitions();
      }
      return this.mergeDefinitions(parsed as Record<string, Object>[]);
    } catch (error) {
      console.error(`Failed to parse achievements: ${JSON.stringify(error)}`);
      return getAchievementDefinitions();
    }
  }

  async saveAchievements(achievements: Achievement[]): Promise<void> {
    await this.preferencesUtil.putPreference(ACHIEVEMENT_KEY, JSON.stringify(achievements));
  }

  async unlockByGameState(achievements: Achievement[], maxTile: number, steps: number, score: number,
    mode: GameMode, totalGames: number): Promise<Achievement[]> {
    let unlocked: Achievement[] = [];
    this.ensureDefinitions(achievements);
    this.unlockIfNeeded(achievements, unlocked, 'tile_32', maxTile >= 32);
    this.unlockIfNeeded(achievements, unlocked, 'tile_128', maxTile >= 128);
    this.unlockIfNeeded(achievements, unlocked, 'tile_512', maxTile >= 512);
    this.unlockIfNeeded(achievements, unlocked, 'tile_2048', maxTile >= 2048);
    this.unlockIfNeeded(achievements, unlocked, 'efficient_128', maxTile >= 128 && steps <= 20);
    this.unlockIfNeeded(achievements, unlocked, 'timed_master', mode === GameMode.TIMED && score >= TIMED_MASTER_SCORE);
    this.unlockIfNeeded(achievements, unlocked, 'ten_games', totalGames >= 10);
    if (unlocked.length > 0) {
      this.saveAchievements(achievements).catch((error: Error) => {
        console.error(`Failed to save achievements: ${JSON.stringify(error)}`);
      });
    }
    return unlocked;
  }

  private ensureDefinitions(achievements: Achievement[]): void {
    const definitions = getAchievementDefinitions();
    for (let index = 0; index < definitions.length; index++) {
      const exists = achievements.some((item: Achievement) => item.id === definitions[index].id);
      if (!exists) {
        achievements.push(definitions[index]);
      }
    }
  }

  private unlockIfNeeded(achievements: Achievement[], unlocked: Achievement[], id: string, shouldUnlock: boolean): void {
    if (!shouldUnlock) {
      return;
    }
    const index = achievements.findIndex((item: Achievement) => item.id === id);
    if (index < 0 || achievements[index].unlocked) {
      return;
    }
    const updated: Achievement = {
      id: achievements[index].id,
      title: achievements[index].title,
      description: achievements[index].description,
      unlocked: true,
      unlockedAt: new Date().toLocaleString()
    };
    achievements[index] = updated;
    unlocked.push(updated);
  }

  private mergeDefinitions(records: Record<string, Object>[]): Achievement[] {
    const definitions = getAchievementDefinitions();
    for (let index = 0; index < definitions.length; index++) {
      const saved = records.find((item: Record<string, Object>) => item['id'] === definitions[index].id);
      if (saved === undefined) {
        continue;
      }
      definitions[index].unlocked = saved['unlocked'] === true;
      definitions[index].unlockedAt = typeof saved['unlockedAt'] === 'string' ? saved['unlockedAt'] as string : '';
    }
    return definitions;
  }
}
