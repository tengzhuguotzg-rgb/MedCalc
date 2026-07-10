import { relationalStore, ValuesBucket } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { preferences } from '@kit.ArkData';
import { ApiServiceConfig } from './LlmService';
import { PreferencesService } from './PreferencesService';

const DOMAIN: number = 0xF000;
const TAG: string = 'EmbeddingService';

const EMBED_DB_NAME: string = 'medcalc_embeddings.db';
const EMBED_DB_VERSION: number = 1;
const EMBED_DB_SECURITY: relationalStore.SecurityLevel = relationalStore.SecurityLevel.S1;

const CREATE_EMBEDDINGS: string =
  'CREATE TABLE IF NOT EXISTS embeddings (' +
  'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
  'path TEXT NOT NULL, ' +
  'chunkIndex INTEGER NOT NULL, ' +
  'chunkText TEXT NOT NULL, ' +
  'vector BLOB, ' +
  'modelTag TEXT, ' +
  'createdAt INTEGER)';

const CREATE_IDX_EMBED_PATH: string =
  'CREATE INDEX IF NOT EXISTS idx_embed_path ON embeddings(path)';

export class EmbeddingSearchResult {
  path: string = '';
  chunkText: string = '';
  score: number = 0;
}

export class EmbeddingService {
  private static instance: EmbeddingService | null = null;
  private store: relationalStore.RdbStore | null = null;
  private initPromise: Promise<void> | null = null;
  private context: Context | null = null;

  private constructor() {}

  static getInstance(): EmbeddingService {
    if (!EmbeddingService.instance) {
      EmbeddingService.instance = new EmbeddingService();
    }
    return EmbeddingService.instance;
  }

  async init(context: Context): Promise<void> {
    if (this.initPromise) {
      return this.initPromise;
    }
    this.context = context;
    this.initPromise = this.doInit(context);
    return this.initPromise;
  }

  private async doInit(context: Context): Promise<void> {
    const config: relationalStore.StoreConfig = {
      name: EMBED_DB_NAME,
      securityLevel: EMBED_DB_SECURITY,
    };
    this.store = await relationalStore.getRdbStore(context, config);
    const currentVersion = this.store.version;
    if (currentVersion < EMBED_DB_VERSION) {
      if (currentVersion === 0) {
        await this.store.executeSql(CREATE_EMBEDDINGS);
        await this.store.executeSql(CREATE_IDX_EMBED_PATH);
      }
      this.store.version = EMBED_DB_VERSION;
    }
    hilog.info(DOMAIN, TAG, 'EmbeddingService initialized');
  }

  private ensureStore(): relationalStore.RdbStore {
    if (!this.store) {
      throw new Error('EmbeddingService not initialized');
    }
    return this.store;
  }

  async isIndexed(): Promise<boolean> {
    const db = this.ensureStore();
    try {
      const rs = await db.querySql('SELECT count(*) as cnt FROM embeddings', []);
      if (rs.rowCount > 0) {
        rs.goToFirstRow();
        const cnt = rs.getLong(0);
        rs.close();
        return cnt > 0;
      }
      rs.close();
    } catch (_e) {
    }
    return false;
  }

  async getIndexedCount(): Promise<number> {
    const db = this.ensureStore();
    try {
      const rs = await db.querySql('SELECT count(*) as cnt FROM embeddings', []);
      if (rs.rowCount > 0) {
        rs.goToFirstRow();
        const cnt = rs.getLong(0);
        rs.close();
        return cnt;
      }
      rs.close();
    } catch (_e) {
    }
    return -1;
  }

  async storeEmbedding(path: string, chunkIndex: number, chunkText: string, vector: number[], modelTag: string): Promise<void> {
    const db = this.ensureStore();
    const vectorBlob = new Float64Array(vector);
    const bucket: ValuesBucket = {
      'path': path,
      'chunkIndex': chunkIndex,
      'chunkText': chunkText,
      'vector': vectorBlob.buffer,
      'modelTag': modelTag,
      'createdAt': Date.now()
    };
    await db.insert('embeddings', bucket);
  }

  async searchByVector(_queryVector: number[], _limit: number = 5): Promise<EmbeddingSearchResult[]> {
    hilog.info(DOMAIN, TAG, 'Vector search not yet implemented - use smartSearch in KnowledgeService');
    return [];
  }

  async clearAll(): Promise<void> {
    const db = this.ensureStore();
    await db.executeSql('DELETE FROM embeddings');
    hilog.info(DOMAIN, TAG, 'All embeddings cleared');
  }

  async generateEmbedding(_text: string, _config: ApiServiceConfig): Promise<number[]> {
    hilog.info(DOMAIN, TAG, 'Embedding generation not yet implemented');
    return [];
  }

  async buildEmbeddingIndex(_context: Context): Promise<void> {
    hilog.info(DOMAIN, TAG, 'Embedding index build not yet implemented - reserved for future use');
  }
}
