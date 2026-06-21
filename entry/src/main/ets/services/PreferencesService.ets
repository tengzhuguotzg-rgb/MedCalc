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
}
