// KnowledgeIndex.ets
// 知识库的"索引生命周期"模块：DB 打开 + 版本迁移 + DDL + Markdown 摄取 + 强制重建索引。
// store 的所有权（生产者）在此模块内部：init() 一次性返回就绪的 RdbStore，
// 不暴露 store 给消费方直接管理，避免迁移时 deleteRdbStore 带来的引用失效问题。
// 不作为单例存在，由 KnowledgeService 门面按需实例化并持有。

import { relationalStore, ValuesBucket, preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { resourceManager } from '@kit.LocalizationKit';
import { util } from '@kit.ArkTS';
import { extractTitle, extractSourceInfo, extractTags, extractSummary, extractPathKeywords, extractWikilinks } from '../utils/KbTextUtils';

const DOMAIN: number = 0x0001;
const TAG: string = 'MedCalc';

const KB_DB_NAME: string = 'medcalc_kb.db';
const KB_DB_VERSION: number = 7;
const KB_DB_SECURITY: relationalStore.SecurityLevel = relationalStore.SecurityLevel.S1;
const KB_ROOT: string = 'kb';
const PREFS_KB_INDEXED: string = 'kb_indexed_version';

const CREATE_KB_INDEX: string =
  'CREATE VIRTUAL TABLE IF NOT EXISTS kb_index USING fts4(' +
  'title, ' +
  'meta, ' +
  'path, ' +
  'source, ' +
  'tokenize=icu zh_CN)';

const CREATE_KB_DIR: string =
  'CREATE TABLE IF NOT EXISTS kb_dir (' +
  'path TEXT PRIMARY KEY, ' +
  'parentPath TEXT, ' +
  'name TEXT NOT NULL, ' +
  'isDir INTEGER NOT NULL)';

const IDX_KB_DIR_PARENT: string =
  'CREATE INDEX IF NOT EXISTS idx_kb_dir_parent ON kb_dir(parentPath)';

const CREATE_KB_CONTENT: string =
  'CREATE TABLE IF NOT EXISTS kb_content (' +
  'path TEXT PRIMARY KEY, ' +
  'content TEXT NOT NULL)';

export class KnowledgeIndex {
  private store: relationalStore.RdbStore | null = null;
  private initPromise: Promise<relationalStore.RdbStore> | null = null;

  /**
   * 打开/迁移/建表/按需重建索引。幂等：内部 initPromise 防并发。
   * 返回就绪的 RdbStore，调用方应持有并交给 KnowledgeSearch.attach。
   */
  init(context: Context): Promise<relationalStore.RdbStore> {
    if (!this.initPromise) {
      this.initPromise = this.doInit(context);
    }
    return this.initPromise;
  }

  private async doInit(context: Context): Promise<relationalStore.RdbStore> {
    const config: relationalStore.StoreConfig = {
      name: KB_DB_NAME,
      securityLevel: KB_DB_SECURITY,
      tokenizer: relationalStore.Tokenizer.ICU_TOKENIZER
    };
    this.store = await relationalStore.getRdbStore(context, config);
    const currentVersion = this.store.version;
    if (currentVersion > 0 && currentVersion < KB_DB_VERSION) {
      this.store = null;
      await relationalStore.deleteRdbStore(context, KB_DB_NAME);
      this.store = await relationalStore.getRdbStore(context, config);
      const prefs = await this.getPreferences(context);
      prefs.putSync(PREFS_KB_INDEXED, 0);
      await prefs.flush();
    }
    if (this.store.version === 0) {
      await this.store.executeSql(CREATE_KB_INDEX);
      await this.store.executeSql(CREATE_KB_DIR);
      await this.store.executeSql(IDX_KB_DIR_PARENT);
      await this.store.executeSql(CREATE_KB_CONTENT);
      this.store.version = KB_DB_VERSION;
    }
    const prefs = await this.getPreferences(context);
    const indexedVersion = prefs.getSync(PREFS_KB_INDEXED, 0) as number;
    if (indexedVersion < KB_DB_VERSION) {
      hilog.info(DOMAIN, TAG, 'Starting knowledge base indexing...');
      const startTime = Date.now();
      await this.buildIndex(context);
      prefs.putSync(PREFS_KB_INDEXED, KB_DB_VERSION);
      await prefs.flush();
      const elapsed = Date.now() - startTime;
      hilog.info(DOMAIN, TAG, 'Knowledge base indexing done in ' + elapsed + 'ms');
    } else {
      hilog.info(DOMAIN, TAG, 'Knowledge base already indexed, skipping');
    }
    return this.store;
  }

  private async getPreferences(context: Context): Promise<preferences.Preferences> {
    return await preferences.getPreferences(context, 'medcalc_kb_prefs');
  }

  /**
   * 强制重建索引。供 KnowledgeService.forceReindex 透传调用。
   * 必须在 init 之后使用，否则 store 为空会抛错。
   */
  async forceReindex(context: Context): Promise<void> {
    if (!this.store) {
      throw new Error('KnowledgeIndex not initialized');
    }
    const prefs = await this.getPreferences(context);
    prefs.putSync(PREFS_KB_INDEXED, 0);
    await prefs.flush();
    await this.store.executeSql('DELETE FROM kb_index');
    await this.store.executeSql('DELETE FROM kb_dir');
    await this.store.executeSql('DELETE FROM kb_content');
    const startTime = Date.now();
    await this.buildIndex(context);
    prefs.putSync(PREFS_KB_INDEXED, KB_DB_VERSION);
    await prefs.flush();
    hilog.info(DOMAIN, TAG, 'Force reindex done in ' + (Date.now() - startTime) + 'ms');
  }

  private async buildIndex(context: Context): Promise<void> {
    const db = this.store!;
    const rm = context.resourceManager;
    await db.executeSql('DELETE FROM kb_index');
    await db.executeSql('DELETE FROM kb_dir');
    await db.executeSql('DELETE FROM kb_content');
    const mdFiles = await this.listAllMdFiles(rm, KB_ROOT);
    hilog.info(DOMAIN, TAG, 'Found ' + mdFiles.length + ' md files');
    await this.buildDirEntries(rm, KB_ROOT, '');
    let indexedCount = 0;
    let failedCount = 0;
    for (const filePath of mdFiles) {
      try {
        const content = await this.readRawFile(rm, filePath);
        const title = extractTitle(content);
        const tags = extractTags(content);
        const summary = extractSummary(content);
        const links = extractWikilinks(content);
        const indexedTitle = tags.length > 0 ? title + ' ' + tags.join(' ') : title;
        const sourceInfo = extractSourceInfo(content);
        const path = filePath.substring(KB_ROOT.length + 1);
        const pathKeywords = extractPathKeywords(path);
        const linkTexts: string[] = [];
        for (const link of links) {
          const baseName = link.split('/').pop() || link;
          linkTexts.push(baseName.replace(/\.md$/, ''));
        }
        const metaParts: string[] = [];
        if (summary.length > 0) {
          metaParts.push(summary);
        }
        if (pathKeywords.length > 0) {
          metaParts.push(pathKeywords.join(' '));
        }
        if (linkTexts.length > 0) {
          metaParts.push(linkTexts.slice(0, 10).join(' '));
        }
        const meta = metaParts.join(' ');
        const ftsBucket: ValuesBucket = {
          'title': indexedTitle,
          'meta': meta,
          'path': path,
          'source': sourceInfo
        };
        const rowId = await db.insert('kb_index', ftsBucket);
        if (rowId < 0) {
          hilog.warn(DOMAIN, TAG, 'FTS insert failed: ' + path + ' rowId=' + rowId.toString());
          failedCount++;
        } else {
          indexedCount++;
        }
        const contentBucket: ValuesBucket = {
          'path': path,
          'content': content
        };
        await db.insert('kb_content', contentBucket);
      } catch (e) {
        const msg = e instanceof Error ? e.message : 'unknown';
        hilog.warn(DOMAIN, TAG, 'Failed to index ' + filePath + ': ' + msg);
        failedCount++;
      }
    }
    hilog.info(DOMAIN, TAG, 'Indexing complete: ' + indexedCount.toString() + ' ok, ' + failedCount.toString() + ' failed');
    const rs = await db.querySql('SELECT count(*) FROM kb_index', []);
    if (rs.rowCount > 0) {
      rs.goToFirstRow();
      hilog.info(DOMAIN, TAG, 'kb_index row count: ' + rs.getLong(0).toString());
    }
    rs.close();
  }

  private async buildDirEntries(rm: resourceManager.ResourceManager, dirPath: string, parentPath: string): Promise<void> {
    const db = this.store!;
    const entries = await this.listDir(rm, dirPath);
    for (const entry of entries) {
      const fullPath = dirPath + '/' + entry;
      const isDir = !entry.endsWith('.md');
      const name = isDir ? entry : entry.replace(/\.md$/, '');
      const pathKey = fullPath.substring(KB_ROOT.length + 1);
      const parentKey = parentPath;
      const bucket: ValuesBucket = {
        'path': pathKey,
        'parentPath': parentKey,
        'name': name,
        'isDir': isDir ? 1 : 0
      };
      await db.insert('kb_dir', bucket);
      if (isDir) {
        try {
          await this.buildDirEntries(rm, fullPath, pathKey);
        } catch (_e) {
          hilog.warn(DOMAIN, TAG, 'Cannot recurse into ' + fullPath);
        }
      }
    }
  }

  private async listAllMdFiles(rm: resourceManager.ResourceManager, dirPath: string): Promise<string[]> {
    const result: string[] = [];
    await this.collectMdFiles(rm, dirPath, result);
    return result;
  }

  private async collectMdFiles(rm: resourceManager.ResourceManager, dirPath: string, result: string[]): Promise<void> {
    let entries: string[] = [];
    try {
      entries = await rm.getRawFileList(dirPath);
    } catch (_e) {
      return;
    }
    for (const entry of entries) {
      if (entry === '.obsidian' || entry.startsWith('.')) {
        continue;
      }
      const fullPath = dirPath + '/' + entry;
      if (entry.endsWith('.md')) {
        result.push(fullPath);
      } else {
        try {
          await this.collectMdFiles(rm, fullPath, result);
        } catch (_e) {
          hilog.warn(DOMAIN, TAG, 'Cannot recurse into ' + fullPath);
        }
      }
    }
  }

  private listDir(rm: resourceManager.ResourceManager, dirPath: string): Promise<string[]> {
    return rm.getRawFileList(dirPath);
  }

  private async readRawFile(rm: resourceManager.ResourceManager, filePath: string): Promise<string> {
    const uint8Array = await rm.getRawFileContent(filePath);
    const textDecoder = util.TextDecoder.create('utf-8');
    return textDecoder.decodeToString(uint8Array);
  }
}
