// KnowledgeService.ets
// 知识库门面（单例）。持有 store/indexed/context 状态，对外暴露 UI 适配接口。
// DB/索引生命周期委托给 KnowledgeIndex（生产者）；检索+LLM 委托给 KnowledgeSearch（消费者）。
// 纯字符串工具（extractTitle/SourceInfo/Tags/Summary/PathKeywords/Wikilinks、excerptContent）
// 由 utils/KbTextUtils.ets 承载，UI 组件直接 import，不再透传。
//
// 拆分自原 1568 行 KnowledgeService.ets；行为保持完全一致：
// - lastExpandedCount/lastPartialPaths/lastVerifyFallback 三个零读者的 side-band 字段已消除，
//   折叠到 SmartSearchOutcome 返回值，由 KnowledgeSearch 内部承载。

import { relationalStore } from '@kit.ArkData';
import { resourceManager } from '@kit.LocalizationKit';
import { util } from '@kit.ArkTS';
import { ApiServiceConfig } from './LlmService';
import { KnowledgeIndex } from './KnowledgeIndex';
import { KnowledgeSearch } from './KnowledgeSearch';
import { extractTitle, extractSourceInfo, extractSummary } from '../utils/KbTextUtils';
import { SearchResult, KnowledgePage, KnowledgeDirEntry, GroupedPageEntry, ExpandedQueryResult, SmartSearchResult } from './KnowledgeTypes';

// 兼容旧 import：UI 模块仍按 `'../services/KnowledgeService'` 引用这些类型。
export { SearchResult, KnowledgePage, KnowledgeDirEntry, GroupedPageEntry, ExpandedQueryResult, SmartSearchResult };

const KB_ROOT: string = 'kb';

export class KnowledgeService {
  private static instance: KnowledgeService | null = null;
  private store: relationalStore.RdbStore | null = null;
  private initPromise: Promise<void> | null = null;
  private indexed: boolean = false;
  private context: Context | null = null;
  private kbIndex: KnowledgeIndex = new KnowledgeIndex();
  private kbSearch: KnowledgeSearch = new KnowledgeSearch();

  private constructor() {}

  static getInstance(): KnowledgeService {
    if (!KnowledgeService.instance) {
      KnowledgeService.instance = new KnowledgeService();
    }
    return KnowledgeService.instance;
  }

  /**
   * 打开知识库 + 注入 store 给检索模块。幂等：内部 initPromise 防并发。
   */
  async init(context: Context): Promise<void> {
    if (this.initPromise) {
      return this.initPromise;
    }
    this.context = context;
    this.initPromise = (async (): Promise<void> => {
      const store = await this.kbIndex.init(context);
      this.store = store;
      this.kbSearch.attach(store, context.resourceManager);
      this.indexed = true;
    })();
    return this.initPromise;
  }

  isReady(): boolean {
    return this.indexed;
  }

  async getIndexedCount(): Promise<number> {
    const db = this.ensureStore();
    try {
      const rs = await db.querySql('SELECT count(*) as cnt FROM kb_index', []);
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

  async getDirCount(): Promise<number> {
    const db = this.ensureStore();
    try {
      const rs = await db.querySql('SELECT count(*) as cnt FROM kb_dir', []);
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

  async forceReindex(context: Context): Promise<void> {
    return await this.kbIndex.forceReindex(context);
  }

  async getPage(path: string): Promise<KnowledgePage | null> {
    return await this.kbSearch.getPage(path);
  }

  async listAllPagesInCategory(categoryPath: string): Promise<GroupedPageEntry[]> {
    const db = this.ensureStore();
    const rm = this.context!.resourceManager;
    const likeParam = categoryPath + '/%';
    const sql =
      'SELECT path, name FROM kb_dir WHERE (path LIKE ?) AND isDir = 0 ORDER BY path ASC';
    let rs: relationalStore.ResultSet;
    try {
      rs = await db.querySql(sql, [likeParam]);
    } catch (_e) {
      return [];
    }
    const rawEntries: string[] = [];
    if (rs.rowCount > 0) {
      rs.goToFirstRow();
      do {
        rawEntries.push(rs.getString(0));
      } while (rs.goToNextRow());
    }
    rs.close();

    const results: GroupedPageEntry[] = [];
    for (const pagePath of rawEntries) {
      const entry = new GroupedPageEntry();
      entry.path = pagePath;

      const pathParts = pagePath.split('/');
      if (pathParts.length >= 3) {
        entry.groupName = pathParts[1];
      } else if (pathParts.length === 2) {
        entry.groupName = '';
      }

      const fileName = pathParts[pathParts.length - 1];
      const orderMatch = fileName.match(/(\d+)/);
      if (orderMatch !== null && orderMatch.length > 1) {
        entry.order = parseInt(orderMatch[1], 10);
      } else {
        entry.order = 999;
      }

      const rawPath = KB_ROOT + '/' + pagePath;
      try {
        const content = await this.readRawFile(rm, rawPath);
        entry.title = extractTitle(content);
        entry.sourceInfo = extractSourceInfo(content);
        entry.summary = extractSummary(content);
      } catch (_e) {
        if (entry.title.length === 0) {
          entry.title = fileName.replace(/\.md$/, '');
        }
      }

      results.push(entry);
    }

    results.sort((a: GroupedPageEntry, b: GroupedPageEntry): number => {
      if (a.groupName < b.groupName) return -1;
      if (a.groupName > b.groupName) return 1;
      if (a.order < b.order) return -1;
      if (a.order > b.order) return 1;
      return 0;
    });

    return results;
  }

  async listDirEntries(parentPath: string): Promise<KnowledgeDirEntry[]> {
    const db = this.ensureStore();
    const predicates = new relationalStore.RdbPredicates('kb_dir');
    if (parentPath.length === 0) {
      predicates.equalTo('parentPath', '');
    } else {
      predicates.equalTo('parentPath', parentPath);
    }
    predicates.orderByAsc('isDir').orderByAsc('name');
    const rs = await db.query(predicates);
    const entries: KnowledgeDirEntry[] = [];
    if (rs.rowCount > 0) {
      rs.goToFirstRow();
      do {
        const entry = new KnowledgeDirEntry();
        entry.path = rs.getString(rs.getColumnIndex('path'));
        const ppIdx = rs.getColumnIndex('parentPath');
        entry.parentPath = rs.getString(ppIdx);
        entry.name = rs.getString(rs.getColumnIndex('name'));
        entry.isDir = rs.getLong(rs.getColumnIndex('isDir')) === 1;
        entries.push(entry);
      } while (rs.goToNextRow());
    }
    rs.close();
    return entries;
  }

  async testSearch(query: string): Promise<string> {
    const db = this.ensureStore();
    const refined = this.kbSearch.refineQuery(query);
    const escapedQuery = this.kbSearch.escapeFtsQuery(refined);
    if (escapedQuery.length === 0) {
      return 'escapeFtsQuery returned empty, raw query=' + query + ', refined=' + refined;
    }
    const diagInfo = 'query=' + query + ', refined=' + refined + ', escaped=' + escapedQuery;
    try {
      const rs = await db.querySql(
        'SELECT path, title FROM kb_index WHERE kb_index MATCH ? LIMIT 5',
        [escapedQuery]);
      const cnt = rs.rowCount;
      const paths: string[] = [];
      if (cnt > 0) {
        rs.goToFirstRow();
        do {
          paths.push(rs.getString(0) + '|' + rs.getString(1));
        } while (rs.goToNextRow());
      }
      rs.close();
      const ftsResult = diagInfo + ', fts_results=' + cnt.toString() + ', paths=' + paths.join('; ');
      const smartOutcome = await this.kbSearch.smartSearch(query, 5);
      const smartPaths: string[] = [];
      for (const sr of smartOutcome.results) {
        smartPaths.push(sr.path + '|' + sr.title);
      }
      return ftsResult + ', smart_results=' + smartOutcome.results.length.toString() + ', smart_paths=' + smartPaths.join('; ');
    } catch (e) {
      const msg = e instanceof Error ? e.message : 'unknown';
      return diagInfo + ', ERROR=' + msg;
    }
  }

  // --- 委托给 KnowledgeSearch 的方法 ---

  search(query: string, limit: number = 10): Promise<SearchResult[]> {
    return this.kbSearch.search(query, limit);
  }

  smartSearch(query: string, limit: number = 10, description: string = ''): Promise<SearchResult[]> {
    return this.kbSearch.smartSearch(query, limit, description).then((o): SearchResult[] => o.results);
  }

  smartSearchV2(query: string, description: string = ''): Promise<string[]> {
    return this.kbSearch.smartSearchV2(query, description);
  }

  smartSearchV2Full(query: string, description: string = ''): Promise<SmartSearchResult> {
    return this.kbSearch.smartSearchV2Full(query, description);
  }

  expandQueryV2(query: string, config: ApiServiceConfig, description: string = ''): Promise<ExpandedQueryResult> {
    return this.kbSearch.expandQueryV2(query, config, description);
  }

  searchAndLoad(query: string, limit: number = 3): Promise<KnowledgePage[]> {
    return this.kbSearch.searchAndLoad(query, limit);
  }

  searchWithSnippets(query: string, limit: number = 10): Promise<SearchResult[]> {
    return this.kbSearch.searchWithSnippets(query, limit);
  }

  getRelatedPages(path: string, limit: number = 5): Promise<SearchResult[]> {
    return this.kbSearch.getRelatedPages(path, limit);
  }

  getSnippet(path: string, query: string, contextChars: number = 120): Promise<string> {
    return this.kbSearch.getSnippet(path, query, contextChars);
  }

  directoryLimitedFts(dirs: string[], terms: string[]): Promise<string[]> {
    return this.kbSearch.directoryLimitedFts(dirs, terms);
  }

  batchGetIndexedTitles(paths: string[]): Promise<Map<string, string>> {
    return this.kbSearch.batchGetIndexedTitles(paths);
  }

  buildSearchKeywordsFromAbnormalLabs(latestData: Map<string, string>): string[] {
    return this.kbSearch.buildSearchKeywordsFromAbnormalLabs(latestData);
  }

  refineQuery(query: string): string {
    return this.kbSearch.refineQuery(query);
  }

  escapeFtsQuery(query: string): string {
    return this.kbSearch.escapeFtsQuery(query);
  }

  escapeFtsQueryOr(query: string): string {
    return this.kbSearch.escapeFtsQueryOr(query);
  }

  // --- 内部工具 ---

  private ensureStore(): relationalStore.RdbStore {
    if (!this.store) {
      throw new Error('KnowledgeService not initialized');
    }
    return this.store;
  }

  private async readRawFile(rm: resourceManager.ResourceManager, filePath: string): Promise<string> {
    const uint8Array = await rm.getRawFileContent(filePath);
    const textDecoder = util.TextDecoder.create('utf-8');
    return textDecoder.decodeToString(uint8Array);
  }
}
