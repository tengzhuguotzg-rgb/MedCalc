import { ApiServiceConfig } from './LlmService';

export class PreferencesService {
  private static instance: PreferencesService;
  private data: Map<string, string> = new Map();

  private constructor() {}

  static getInstance(): PreferencesService {
    if (!PreferencesService.instance) {
      PreferencesService.instance = new PreferencesService();
    }
    return PreferencesService.instance;
  }

  saveFavorites(favorites: string[]): void {
    this.data.set('favorites', JSON.stringify(favorites));
  }

  getFavorites(): string[] {
    const value = this.data.get('favorites');
    return value ? JSON.parse(value) : [];
  }

  saveTheme(theme: string): void {
    this.data.set('theme', theme);
  }

  getTheme(): string {
    return this.data.get('theme') || 'light';
  }

  saveLastCalculator(calcId: string): void {
    this.data.set('lastCalculator', calcId);
  }

  getLastCalculator(): string {
    return this.data.get('lastCalculator') || 'crcl';
  }

  saveApiServices(services: ApiServiceConfig[]): void {
    this.data.set('apiServicesCount', String(services.length));
    for (let i = 0; i < services.length; i++) {
      this.data.set(`apiSvc_${i}_id`, services[i].id);
      this.data.set(`apiSvc_${i}_name`, services[i].name);
      this.data.set(`apiSvc_${i}_url`, services[i].baseUrl);
      this.data.set(`apiSvc_${i}_key`, services[i].apiKey);
      this.data.set(`apiSvc_${i}_model`, services[i].model);
    }
  }

  getApiServices(): ApiServiceConfig[] {
    const countStr = this.data.get('apiServicesCount');
    if (!countStr) {
      return [];
    }
    const count = parseInt(countStr, 10);
    const result: ApiServiceConfig[] = [];
    for (let i = 0; i < count; i++) {
      const id = this.data.get(`apiSvc_${i}_id`) || '';
      const name = this.data.get(`apiSvc_${i}_name`) || '';
      const baseUrl = this.data.get(`apiSvc_${i}_url`) || '';
      const apiKey = this.data.get(`apiSvc_${i}_key`) || '';
      const model = this.data.get(`apiSvc_${i}_model`) || '';
      result.push({ id: id, name: name, baseUrl: baseUrl, apiKey: apiKey, model: model });
    }
    return result;
  }

  saveActiveServiceId(id: string): void {
    this.data.set('activeServiceId', id);
  }

  getActiveServiceId(): string {
    return this.data.get('activeServiceId') || '';
  }
}
