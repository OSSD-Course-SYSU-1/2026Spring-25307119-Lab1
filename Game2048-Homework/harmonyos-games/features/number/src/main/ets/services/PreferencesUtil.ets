import dataPreferences from '@ohos.data.preferences';
import { BusinessError } from '@kit.BasicServicesKit';
import common from '@ohos.app.ability.common';

const PREFERENCES_NAME: string = 'fruit.db';
const context = getContext() as common.UIAbilityContext;

export default class PreferencesUtil {
  private preferences: dataPreferences.Preferences | undefined = undefined;

  async getPreferencesFromStorage(): Promise<void> {
    await dataPreferences.getPreferences(context, PREFERENCES_NAME).then((data: dataPreferences.Preferences) => {
      this.preferences = data;
      console.info('Succeeded in getting preferences');
    }).catch((err: BusinessError) => {
      console.error(`Failed to get preferences, Cause: ${err.message} ${err.code}`);
    });
  }

  async putPreference(key: string, data: dataPreferences.ValueType): Promise<void> {
    if (this.preferences === undefined) {
      await this.getPreferencesFromStorage();
    }

    await this.preferences?.put(key, data).then(() => {
      console.info(`Succeeded in putting value for ${key}`);
    }).catch((err: BusinessError) => {
      console.error(`Failed to put preference, Cause: ${JSON.stringify(err)}`);
    });

    await this.preferences?.flush();
  }

  async getPreference(key: string): Promise<dataPreferences.ValueType> {
    let result: dataPreferences.ValueType = '';
    if (this.preferences === undefined) {
      await this.getPreferencesFromStorage();
    }
    await this.preferences?.get(key, '').then((data: dataPreferences.ValueType) => {
      result = data;
      console.info(`Succeeded in getting value for ${key}`);
    }).catch((err: BusinessError) => {
      console.error(`Failed to get preference, Cause: ${JSON.stringify(err)}`);
    });

    return result;
  }

  async deletePreferences(): Promise<void> {
    await dataPreferences.deletePreferences(context, PREFERENCES_NAME).then(() => {
      console.info('Succeeded in deleting preferences');
    }).catch((err: BusinessError) => {
      console.error(`Failed to delete preferences, Cause: ${JSON.stringify(err)}`);
    });
    this.preferences = undefined;
  }
}
