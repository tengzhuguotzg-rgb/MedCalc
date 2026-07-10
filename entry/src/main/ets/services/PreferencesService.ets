import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { LlmModelConfig, LlmFormat, ApiServiceConfig } from './LlmService';

const PREFS_NAME: string = 'medcalc_prefs';
const KEY_FAVORITES: string = 'favorites';
const KEY_LAST_CALC: string = 'lastCalculator';
const KEY_LLM_MODELS: string = 'llmModels';
const KEY_SELECTED_LLM_ID: string = 'selectedLlmId';

class LlmModelRecord {
  id: string = '';
  name: string = '';
  provider: string = '';
  format: number = 0;
  baseUrl: string = '';
  apiKey: string = '';
  modelName: string = '';

  constructor(
    id: string, name: string, provider: string, format: number,
    baseUrl: string, apiKey: string, modelName: string
  ) {
    this.id = id;
    this.name = name;
    this.provider = provider;
    this.format = format;
    this.baseUrl = baseUrl;
    this.apiKey = apiKey;
    this.modelName = modelName;
  }
}

export class PreferencesService {
  private static instance: PreferencesService;
  private prefs: preferences.Preferences | null = null;
  private initDone: boolean = false;

  private constructor() {}

  static getInstance(): PreferencesService {
    if (!PreferencesService.instance) {
      PreferencesService.instance = new PreferencesService();
    }
    return PreferencesService.instance;
  }

  init(context: common.UIAbilityContext): void {
    if (this.initDone) {
      return;
    }
    try {
      this.prefs = preferences.getPreferencesSync(context, { name: PREFS_NAME });
      this.initDone = true;
    } catch (_e) {
      this.initDone = false;
    }
  }

  private ensureInit(): void {
    if (!this.initDone || this.prefs === null) {
      const ctx = AppStorage.get<common.UIAbilityContext>('context');
      if (ctx) {
        try {
          this.prefs = preferences.getPreferencesSync(ctx, { name: PREFS_NAME });
          this.initDone = true;
        } catch (_e) {}
      }
    }
  }

  private getSync(key: string, defValue: string): string {
    this.ensureInit();
    if (this.prefs === null) {
      return defValue;
    }
    try {
      return this.prefs.getSync(key, defValue) as string;
    } catch (_e) {
      return defValue;
    }
  }

  private putSync(key: string, value: string): void {
    this.ensureInit();
    if (this.prefs === null) {
      return;
    }
    try {
      this.prefs.putSync(key, value);
      this.prefs.flushSync();
    } catch (_e) {}
  }

  saveFavorites(favorites: string[]): void {
    this.putSync(KEY_FAVORITES, JSON.stringify(favorites));
  }

  getFavorites(): string[] {
    const value = this.getSync(KEY_FAVORITES, '');
    if (value.length === 0) {
      return [];
    }
    try {
      return JSON.parse(value) as string[];
    } catch (_e) {
      return [];
    }
  }

  saveLastCalculator(calcId: string): void {
    this.putSync(KEY_LAST_CALC, calcId);
  }

  getLastCalculator(): string {
    return this.getSync(KEY_LAST_CALC, 'crcl');
  }

  saveLlmModels(models: LlmModelConfig[], selectedId: string): void {
    const arr: LlmModelRecord[] = [];
    for (let i = 0; i < models.length; i++) {
      arr.push(new LlmModelRecord(
        models[i].id, models[i].name, models[i].provider, models[i].format,
        models[i].baseUrl, models[i].apiKey, models[i].modelName
      ));
    }
    this.putSync(KEY_LLM_MODELS, JSON.stringify(arr));
    this.putSync(KEY_SELECTED_LLM_ID, selectedId);
  }

  getLlmModels(): LlmModelConfig[] {
    const value = this.getSync(KEY_LLM_MODELS, '');
    if (value.length === 0) {
      return [];
    }
    try {
      const arr: Object[] = JSON.parse(value) as Object[];
      const result: LlmModelConfig[] = [];
      for (let i = 0; i < arr.length; i++) {
        const obj = arr[i] as Record<string, Object>;
        const id = (obj['id'] as string) || '';
        const name = (obj['name'] as string) || '';
        const provider = (obj['provider'] as string) || '';
        const format = (obj['format'] as number) || 0;
        const baseUrl = (obj['baseUrl'] as string) || '';
        const apiKey = (obj['apiKey'] as string) || '';
        const modelName = (obj['modelName'] as string) || '';
        result.push(new LlmModelConfig(id, name, provider, format as LlmFormat, baseUrl, apiKey, modelName));
      }
      return result;
    } catch (_e) {
      return [];
    }
  }

  getSelectedLlmId(): string {
    const id = this.getSync(KEY_SELECTED_LLM_ID, '');
    if (id.length > 0) {
      return id;
    }
    const models = this.getLlmModels();
    if (models.length > 0) {
      return models[0].id;
    }
    return '';
  }

  saveSelectedLlmId(id: string): void {
    this.putSync(KEY_SELECTED_LLM_ID, id);
  }

  getActiveLlmConfig(): ApiServiceConfig | null {
    const models = this.getLlmModels();
    const selectedId = this.getSelectedLlmId();
    for (let i = 0; i < models.length; i++) {
      if (models[i].id === selectedId) {
        return models[i].toApiServiceConfig();
      }
    }
    if (models.length > 0) {
      return models[0].toApiServiceConfig();
    }
    return null;
  }

  saveDiagnosisKbData(patientId: string, ruleId: string, data: string): void {
    this.putSync('kb_' + patientId + '_' + ruleId, data);
  }

  getDiagnosisKbData(patientId: string, ruleId: string): string {
    return this.getSync('kb_' + patientId + '_' + ruleId, '');
  }
}
