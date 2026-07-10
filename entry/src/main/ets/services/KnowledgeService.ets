import { relationalStore, ValuesBucket, preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { resourceManager } from '@kit.LocalizationKit';
import { util } from '@kit.ArkTS';
import { sendVisionRequest, ApiServiceConfig } from './LlmService';
import { PreferencesService } from './PreferencesService';

const DOMAIN: number = 0xF000;
const TAG: string = 'KnowledgeService';

const KB_DB_NAME: string = 'medcalc_kb.db';
const KB_DB_VERSION: number = 6;
const KB_DB_SECURITY: relationalStore.SecurityLevel = relationalStore.SecurityLevel.S1;

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

const KB_ROOT: string = 'kb';
const PREFS_KB_INDEXED: string = 'kb_indexed_version';

export class SearchResult {
  path: string = '';
  title: string = '';
  snippet: string = '';
  sourceInfo: string = '';
  rank: number = 0;
  relevanceScore: number = 0;
}

export class KnowledgePage {
  path: string = '';
  title: string = '';
  content: string = '';
  sourceInfo: string = '';
}

export class KnowledgeDirEntry {
  path: string = '';
  parentPath: string = '';
  name: string = '';
  isDir: boolean = false;
}

export class GroupedPageEntry {
  path: string = '';
  title: string = '';
  sourceInfo: string = '';
  summary: string = '';
  groupName: string = '';
  order: number = 0;
}

export class KnowledgeService {
  private static instance: KnowledgeService | null = null;
  private store: relationalStore.RdbStore | null = null;
  private initPromise: Promise<void> | null = null;
  private indexed: boolean = false;
  private context: Context | null = null;
  lastExpandedCount: number = 0;
  lastPartialPaths: string[] = [];

  private constructor() {}

  static getInstance(): KnowledgeService {
    if (!KnowledgeService.instance) {
      KnowledgeService.instance = new KnowledgeService();
    }
    return KnowledgeService.instance;
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
      const prefs = await this.getPreferences();
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
    const prefs = await this.getPreferences();
    const indexedVersion = prefs.getSync(PREFS_KB_INDEXED, 0) as number;
    if (indexedVersion < KB_DB_VERSION) {
      hilog.info(DOMAIN, TAG, 'Starting knowledge base indexing...');
      const startTime = Date.now();
      await this.buildIndex(context);
      prefs.putSync(PREFS_KB_INDEXED, KB_DB_VERSION);
      await prefs.flush();
      const elapsed = Date.now() - startTime;
      hilog.info(DOMAIN, TAG, 'Knowledge base indexing done in ' + elapsed + 'ms');
      this.indexed = true;
    } else {
      this.indexed = true;
      hilog.info(DOMAIN, TAG, 'Knowledge base already indexed, skipping');
    }
  }

  private async getPreferences(): Promise<preferences.Preferences> {
    const ctx = this.context!;
    return await preferences.getPreferences(ctx, 'medcalc_kb_prefs');
  }

  private async buildIndex(context: Context): Promise<void> {
    const db = this.ensureStore();
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
        const title = this.extractTitle(content);
        const tags = this.extractTags(content);
        const summary = this.extractSummary(content);
        const links = this.extractWikilinks(content);
        const indexedTitle = tags.length > 0 ? title + ' ' + tags.join(' ') : title;
        const sourceInfo = this.extractSourceInfo(content);
        const path = filePath.substring(KB_ROOT.length + 1);
        const pathKeywords = this.extractPathKeywords(path);
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

  private extractPathKeywords(path: string): string[] {
    const keywords: string[] = [];
    const parts = path.split('/');
    for (let i = 0; i < parts.length - 1; i++) {
      const part = parts[i];
      if (part.length > 0 && part !== 'NICE' && part !== '机制' && part !== '笔记') {
        keywords.push(part);
      }
    }
    return keywords;
  }

  private async buildDirEntries(rm: resourceManager.ResourceManager, dirPath: string, parentPath: string): Promise<void> {
    const db = this.ensureStore();
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

  private extractTitle(content: string): string {
    const yamlEnd = content.indexOf('---', 3);
    if (yamlEnd > 0) {
      const yaml = content.substring(3, yamlEnd);
      const lines = yaml.split('\n');
      for (const line of lines) {
        const trimmed = line.trim();
        if (trimmed.startsWith('title:')) {
          return trimmed.substring(6).trim().replace(/^['"]|['"]$/g, '');
        }
      }
    }
    const h1Match = content.match(/^#\s+(.+)$/m);
    if (h1Match !== null && h1Match.length > 1) {
      return h1Match[1];
    }
    return '';
  }

  private extractSourceInfo(content: string): string {
    const yamlEnd = content.indexOf('---', 3);
    if (yamlEnd <= 0) {
      return '';
    }
    const yaml = content.substring(3, yamlEnd);
    const lines = yaml.split('\n');
    const parts: string[] = [];
    for (const line of lines) {
      const trimmed = line.trim();
      if (trimmed.startsWith('source:')) {
        parts.push(trimmed.substring(7).trim().replace(/^['"]|['"]$/g, ''));
      } else if (trimmed.startsWith('date:')) {
        parts.push(trimmed.substring(5).trim().replace(/^['"]|['"]$/g, ''));
      }
    }
    return parts.join(' ');
  }

  private extractTags(content: string): string[] {
    const yamlEnd = content.indexOf('---', 3);
    if (yamlEnd <= 0) {
      return [];
    }
    const yaml = content.substring(3, yamlEnd);
    const lines = yaml.split('\n');
    let inTags = false;
    const tags: string[] = [];
    for (const line of lines) {
      const trimmed = line.trim();
      if (trimmed === 'tags:') {
        inTags = true;
        continue;
      }
      if (inTags) {
        if (trimmed.startsWith('- ')) {
          const tag = trimmed.substring(2).trim().replace(/^['"]|['"]$/g, '');
          if (tag.length > 0) {
            tags.push(tag);
          }
        } else if (!trimmed.startsWith('-') && trimmed.length > 0) {
          break;
        }
      }
    }
    return tags;
  }

  private ensureStore(): relationalStore.RdbStore {
    if (!this.store) {
      throw new Error('KnowledgeService not initialized');
    }
    return this.store;
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
        entry.title = this.extractTitle(content);
        entry.sourceInfo = this.extractSourceInfo(content);
        entry.summary = this.extractSummary(content);
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

  private extractSummary(content: string): string {
    const yamlEnd = content.indexOf('---', 3);
    if (yamlEnd <= 0) {
      const bodyStart = content.indexOf('\n\n');
      if (bodyStart > 0 && bodyStart + 2 < content.length) {
        const firstPara = content.substring(bodyStart + 2, Math.min(bodyStart + 302, content.length));
        const nextBreak = firstPara.indexOf('\n\n');
        return nextBreak > 0 ? firstPara.substring(0, nextBreak) : firstPara;
      }
      return content.substring(0, Math.min(300, content.length));
    }
    const yaml = content.substring(3, yamlEnd);
    const lines = yaml.split('\n');
    for (const line of lines) {
      const trimmed = line.trim();
      if (trimmed.startsWith('summary:')) {
        return trimmed.substring(8).trim().replace(/^['"]|['"]$/g, '');
      }
    }
    const bodyStart = content.indexOf('\n\n', yamlEnd + 3);
    if (bodyStart > 0 && bodyStart + 2 < content.length) {
      const firstPara = content.substring(bodyStart + 2, Math.min(bodyStart + 302, content.length));
      const nextBreak = firstPara.indexOf('\n\n');
      return nextBreak > 0 ? firstPara.substring(0, nextBreak) : firstPara;
    }
    return '';
  }

  private static readonly STOPWORDS: string[] = [
    '重症', '急性', '慢性', '严重', '重度', '中度', '轻度', '高危', '低危',
    '原发性', '继发性', '先天性', '非', '未特指'
  ];

  private static readonly COMPOUND_PREFIXES: string[] = [
    '社区获得性', '医院获得性', '获得性免疫', '获得性肺炎'
  ];

  refineQuery(query: string): string {
    const protectedParts: string[] = [];
    let remaining = query;
    for (const cp of KnowledgeService.COMPOUND_PREFIXES) {
      if (remaining.includes(cp)) {
        protectedParts.push(cp);
        remaining = remaining.replace(cp, ' ');
      }
    }
    const parts = remaining.split(/[\s,，、；;]+/);
    const refined: string[] = [];
    for (const pp of protectedParts) {
      refined.push(pp);
    }
    for (const part of parts) {
      let trimmed = part.trim();
      if (trimmed.length === 0) {
        continue;
      }
      for (const sw of KnowledgeService.STOPWORDS) {
        if (trimmed.startsWith(sw) && trimmed.length > sw.length) {
          trimmed = trimmed.substring(sw.length);
        }
      }
      if (trimmed.length > 0) {
        refined.push(trimmed);
      }
    }
    return refined.join(' ');
  }

  async search(query: string, limit: number = 10): Promise<SearchResult[]> {
    const db = this.ensureStore();
    const refined = this.refineQuery(query);
    const escapedQuery = this.escapeFtsQuery(refined);
    hilog.info(DOMAIN, TAG, 'search: query=' + query + ', refined=' + refined + ', escaped=' + escapedQuery);
    if (escapedQuery.length === 0) {
      return [];
    }
    const sql =
      'SELECT path, title, source ' +
      'FROM kb_index ' +
      'WHERE kb_index MATCH ? ' +
      'LIMIT ?';
    let rs: relationalStore.ResultSet;
    try {
      rs = await db.querySql(sql, [escapedQuery, limit]);
    } catch (e) {
      const msg = e instanceof Error ? e.message : 'unknown';
      hilog.warn(DOMAIN, TAG, 'FTS search failed: ' + msg);
      return [];
    }
    const results: SearchResult[] = [];
    if (rs.rowCount > 0) {
      rs.goToFirstRow();
      let rank = 0;
      do {
        const sr = new SearchResult();
        sr.path = rs.getString(0);
        sr.title = rs.getString(1);
        sr.sourceInfo = rs.getString(2) || '';
        sr.rank = rank;
        rank++;
        results.push(sr);
      } while (rs.goToNextRow());
    }
    rs.close();
    hilog.info(DOMAIN, TAG, 'search results: ' + results.length.toString() + ' for query=' + query);
    return results;
  }

  buildSearchKeywordsFromAbnormalLabs(latestData: Map<string, string>): string[] {
    const keywords: string[] = [];
    const checks: string[][] = [
      ['pct', '0.5', 'gt', '细菌感染 脓毒症'],
      ['pct', '2', 'gt', '脓毒症 严重感染'],
      ['crp', '10', 'gt', '炎症 感染'],
      ['crp', '100', 'gt', '严重感染 脓毒症'],
      ['ctni', '0.018', 'gt', '心肌损伤 心梗 冠脉'],
      ['myo', '95.2', 'gt', '心肌损伤 骨骼肌损伤'],
      ['bnp', '100', 'gt', '心衰 心功能不全'],
      ['dDimer', '1.0', 'gt', '肺栓塞 深静脉血栓 血栓'],
      ['dDimer', '5', 'gt', 'DIC 纤溶'],
      ['fib', '1.5', 'lt', 'DIC 低纤维蛋白原 出血'],
      ['fdp', '5', 'gt', 'DIC 纤溶亢进'],
      ['pt', '18', 'gt', '凝血障碍 肝病'],
      ['ck', '5000', 'gt', '横纹肌溶解'],
      ['ck', '1000', 'gt', '肌损伤'],
      ['alt', '216', 'gt', '肝损伤 肝损害'],
      ['ammonia', '50', 'gt', '肝性脑病'],
      ['mg', '0.7', 'lt', '低镁 心律失常'],
      ['p', '0.85', 'lt', '低磷 呼吸肌无力 撤机困难'],
      ['ft4', '77', 'gt', '甲亢危象'],
      ['tsh', '10', 'gt', '甲减 黏液水肿'],
      ['cortisol', '140', 'lt', '肾上腺危象'],
    ];
    for (let i = 0; i < checks.length; i++) {
      const c = checks[i];
      const val = latestData.get(c[0]);
      if (val === undefined || val.length === 0) {
        continue;
      }
      const numVal = parseFloat(val);
      if (isNaN(numVal)) {
        continue;
      }
      const threshold = parseFloat(c[1]);
      const op = c[2];
      let matched = false;
      if (op === 'gt' && numVal > threshold) {
        matched = true;
      } else if (op === 'lt' && numVal < threshold) {
        matched = true;
      }
      if (matched) {
        const kws = c[3].split(' ');
        for (let j = 0; j < kws.length; j++) {
          if (!keywords.includes(kws[j])) {
            keywords.push(kws[j]);
          }
        }
      }
    }
    return keywords;
  }

  async smartSearch(query: string, limit: number = 10): Promise<SearchResult[]> {
    const prefsService = PreferencesService.getInstance();
    const config = prefsService.getActiveLlmConfig();
    if (config === null) {
      return await this.search(query, limit);
    }

    let expandedTerms: string[] = [];
    try {
      expandedTerms = await this.expandQueryWithLlm(query, config);
    } catch (_e) {
      expandedTerms = [];
    }
    let ftsResults: SearchResult[];
    if (expandedTerms.length > 0) {
      const expandedQuery = query + ' ' + expandedTerms.join(' ');
      ftsResults = await this.searchWithExpandedQuery(expandedQuery, 50);
    } else {
      ftsResults = await this.search(query, 50);
    }

    if (ftsResults.length === 0) {
      this.lastExpandedCount = 0;
      this.lastPartialPaths = [];
      return [];
    }

    this.lastExpandedCount = ftsResults.length;
    const verified = await this.verifyResultsWithLlm(query, ftsResults, config, limit);
    if (verified.length > 0) {
      return verified;
    }
    return ftsResults.slice(0, limit);
  }

  private async verifyResultsWithLlm(query: string, results: SearchResult[], config: ApiServiceConfig, limit: number): Promise<SearchResult[]> {
    try {
      const docList: string[] = [];
      for (let i = 0; i < results.length; i++) {
        docList.push((i + 1).toString() + '. [' + results[i].path + '] ' + results[i].title);
      }
      const systemPrompt = '你是重症医学知识库搜索验收专家。给定用户查询词和候选文章列表，对每篇文章判断其与查询词的相关程度。' +
        '\n\n三级判断标准：' +
        'Y(全文相关)：文章的主要主题就是查询词所述的疾病/综合征。文章path中的疾病名与查询词匹配或高度相关。' +
        'P(片段相关)：文章的主要主题不是查询词疾病，但文章中有**独立段落**专门讨论查询词疾病的诊断、监测、治疗等临床内容。一句话提及或仅作为并发症列举不算P。' +
        'N(不相关)：文章仅顺带提及查询词（一句话提及、并发症列表、鉴别诊断举例、实验室表现列举等），没有独立段落专门讨论。' +
        '\n\n输出格式：每篇文章输出"编号:Y"或"编号:P"或"编号:N"，用逗号分隔。不要解释。' +
        '\n\n示例：' +
        '查询"代谢性酸中毒"，文章"[酸碱平衡/代谢性酸中毒/诊断]"→1:Y（主题就是代谢性酸中毒）' +
        '查询"代谢性酸中毒"，文章"[脓毒症/机制/机制-脓毒症-05-代谢改变]"→2:P（脓毒症主题，但有独立段落讨论代谢性酸中毒的机制和处理）' +
        '查询"代谢性酸中毒"，文章"[休克/分类/分类概述]"→3:N（仅列举"代谢性酸中毒是休克的代谢表现之一"，无独立讨论）' +
        '查询"AKI"，文章"[脓毒症/机制/肾脏损伤]"→4:P（脓毒症主题，但有独立段落讨论AKI的发生机制和管理）' +
        '查询"乳酸升高"，文章"[脓毒症/集束化治疗]"→5:P（脓毒症主题，但有独立段落讨论乳酸监测目标和乳酸清除率）' +
        '查询"肺炎"，文章"[中枢神经系统感染/NICE/NICE-BacM-4-抗生素]"→6:N（仅提及肺炎链球菌作为病原，无独立讨论肺炎）';
      const userText = '查询词：' + query + '\n候选文章：\n' + docList.join('\n');
      const response = await sendVisionRequest(config, systemPrompt, userText, '', '');
      const yIndices: number[] = [];
      const pIndices: number[] = [];
      const parts = response.split(/[,\s，、]+/);
      for (const part of parts) {
        const trimmed = part.trim();
        const colonIdx = trimmed.lastIndexOf(':');
        if (colonIdx < 0) {
          const n = parseInt(trimmed, 10);
          if (!isNaN(n) && n >= 1 && n <= results.length) {
            yIndices.push(n - 1);
          }
          continue;
        }
        const numPart = trimmed.substring(0, colonIdx);
        const label = trimmed.substring(colonIdx + 1).toUpperCase();
        const n = parseInt(numPart, 10);
        if (isNaN(n) || n < 1 || n > results.length) {
          continue;
        }
        if (label === 'Y') {
          yIndices.push(n - 1);
        } else if (label === 'P') {
          pIndices.push(n - 1);
        }
      }
      const verified: SearchResult[] = [];
      for (const idx of yIndices) {
        verified.push(results[idx]);
        if (verified.length >= limit) {
          break;
        }
      }
      const partialPaths: string[] = [];
      if (verified.length < limit) {
        for (const idx of pIndices) {
          partialPaths.push(results[idx].path);
          if (verified.length < limit) {
            verified.push(results[idx]);
          }
        }
      }
      this.lastPartialPaths = partialPaths;
      if (verified.length === 0 && pIndices.length === 0) {
        hilog.warn(DOMAIN, TAG, 'verifyResults: all rejected, falling back to FTS order');
        return [];
      }
      hilog.info(DOMAIN, TAG, 'verifyResults: ' + query + ' Y=' + yIndices.length + ' P=' + pIndices.length + '/' + results.length);
      return verified;
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'verifyResults failed: ' + (e instanceof Error ? e.message : 'unknown') + ', fallback to FTS');
      this.lastPartialPaths = [];
      return results.slice(0, limit);
    }
  }

  private async expandQueryWithLlm(query: string, config: ApiServiceConfig): Promise<string[]> {
    try {
      const systemPrompt = '你是重症医学文献检索专家。用户会给你一个临床检索词，请生成2-5个同义词、相关术语或临床等效表述，' +
        '用于扩大文献检索范围。只输出扩展词，每行一个，不要编号，不要解释。' +
        '如果检索词已经很具体无需扩展，输出空行。' +
        '示例：输入"脓毒症"→输出"败血症\\n全身性感染\\nSepsis"' +
        '示例：输入"AKI"→输出"急性肾损伤\\n急性肾衰竭\\nARF"';
      const response = await sendVisionRequest(config, systemPrompt, query, '', '');
      const lines = response.split(/[\n,，、；;]+/);
      const terms: string[] = [];
      for (const line of lines) {
        const trimmed = line.trim();
        if (trimmed.length > 0 && trimmed.length < 20 && trimmed !== query) {
          terms.push(trimmed);
        }
      }
      hilog.info(DOMAIN, TAG, 'expandQuery: ' + query + ' -> ' + terms.join(', '));
      return terms.slice(0, 5);
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'expandQuery failed: ' + (e instanceof Error ? e.message : 'unknown'));
      return [];
    }
  }

  private async searchWithExpandedQuery(expandedQuery: string, limit: number): Promise<SearchResult[]> {
    const db = this.ensureStore();
    const refined = this.refineQuery(expandedQuery);
    const escapedQuery = this.escapeFtsQueryOr(refined);
    if (escapedQuery.length === 0) {
      return [];
    }
    const sql =
      'SELECT path, title, source ' +
      'FROM kb_index ' +
      'WHERE kb_index MATCH ? ' +
      'LIMIT ?';
    let rs: relationalStore.ResultSet;
    try {
      rs = await db.querySql(sql, [escapedQuery, limit]);
    } catch (e) {
      const msg = e instanceof Error ? e.message : 'unknown';
      hilog.warn(DOMAIN, TAG, 'Expanded FTS search failed: ' + msg);
      return [];
    }
    const results: SearchResult[] = [];
    if (rs.rowCount > 0) {
      rs.goToFirstRow();
      let rank = 0;
      do {
        const sr = new SearchResult();
        sr.path = rs.getString(0);
        sr.title = rs.getString(1);
        sr.sourceInfo = rs.getString(2) || '';
        sr.rank = rank;
        rank++;
        results.push(sr);
      } while (rs.goToNextRow());
    }
    rs.close();
    return results;
  }

  private escapeFtsQueryOr(query: string): string {
    const parts = query.split(/[\s,，、；;]+/);
    const escaped: string[] = [];
    for (const part of parts) {
      const trimmed = part.trim();
      if (trimmed.length === 0) {
        continue;
      }
      escaped.push('"' + trimmed.replace(/"/g, '""') + '"');
    }
    if (escaped.length <= 1) {
      return escaped.join('');
    }
    return escaped.join(' OR ');
  }

  private escapeFtsQuery(query: string): string {
    const parts = query.split(/[\s,，、；;]+/);
    const escaped: string[] = [];
    for (const part of parts) {
      const trimmed = part.trim();
      if (trimmed.length === 0) {
        continue;
      }
      escaped.push('"' + trimmed.replace(/"/g, '""') + '"');
    }
    if (escaped.length <= 1) {
      return escaped.join('');
    }
    return escaped.join(' AND ');
  }

  async getPage(path: string): Promise<KnowledgePage | null> {
    const db = this.ensureStore();
    try {
      const rs = await db.querySql(
        'SELECT content FROM kb_content WHERE path = ? LIMIT 1', [path]);
      if (rs.rowCount > 0) {
        rs.goToFirstRow();
        const content = rs.getString(0);
        rs.close();
        const page = new KnowledgePage();
        page.path = path;
        page.title = this.extractTitle(content);
        page.content = content;
        page.sourceInfo = this.extractSourceInfo(content);
        return page;
      }
      rs.close();
    } catch (_e) {
    }
    const rm = this.context!.resourceManager;
    const rawPath = KB_ROOT + '/' + path;
    try {
      const content = await this.readRawFile(rm, rawPath);
      const page = new KnowledgePage();
      page.path = path;
      page.title = this.extractTitle(content);
      page.content = content;
      page.sourceInfo = this.extractSourceInfo(content);
      return page;
    } catch (e) {
      const msg = e instanceof Error ? e.message : 'unknown';
      hilog.warn(DOMAIN, TAG, 'Failed to read page ' + path + ': ' + msg);
      return null;
    }
  }

  async searchAndLoad(query: string, limit: number = 3): Promise<KnowledgePage[]> {
    const results = await this.smartSearch(query, limit);
    const pages: KnowledgePage[] = [];
    for (const sr of results) {
      const page = await this.getPage(sr.path);
      if (page !== null && page.content.trim().length >= 100) {
        pages.push(page);
      }
    }
    return pages;
  }

  excerptContent(content: string, keywords: string[], maxChars: number): string {
    const paragraphs: string[] = content.split(/\n\n+/);
    if (paragraphs.length === 0) {
      return content.substring(0, maxChars);
    }
    const mandatoryIndices = new Set<number>();
    if (paragraphs.length > 0) {
      mandatoryIndices.add(0);
    }
    if (paragraphs.length > 1) {
      mandatoryIndices.add(1);
    }
    const hitIndices = new Set<number>();
    for (let i = 0; i < paragraphs.length; i++) {
      for (const kw of keywords) {
        if (kw.length > 0 && paragraphs[i].includes(kw)) {
          hitIndices.add(i);
          if (i > 0) {
            hitIndices.add(i - 1);
          }
          if (i < paragraphs.length - 1) {
            hitIndices.add(i + 1);
          }
          break;
        }
      }
    }
    const selectedIndices = new Set<number>();
    for (const idx of mandatoryIndices) {
      selectedIndices.add(idx);
    }
    for (const idx of hitIndices) {
      selectedIndices.add(idx);
    }
    const sorted: number[] = Array.from(selectedIndices).sort((a: number, b: number): number => a - b);
    const result: string[] = [];
    for (const idx of sorted) {
      result.push(paragraphs[idx]);
    }
    let joined = result.join('\n\n');
    if (joined.length < 500) {
      return content.substring(0, Math.min(5000, content.length));
    }
    while (joined.length > maxChars && result.length > 2) {
      result.pop();
      joined = result.join('\n\n');
    }
    return joined.substring(0, maxChars);
  }

  async getSnippet(path: string, query: string, contextChars: number = 120): Promise<string> {
    const db = this.ensureStore();
    const escapedQuery = this.escapeFtsQuery(query);
    if (escapedQuery.length === 0) {
      return '';
    }
    try {
      const sql =
        'SELECT snippet(kb_index) as snippet ' +
        'FROM kb_index WHERE path = ? AND kb_index MATCH ? LIMIT 1';
      const rs = await db.querySql(sql, [path, escapedQuery]);
      let snippet = '';
      if (rs.rowCount > 0) {
        rs.goToFirstRow();
        snippet = rs.getString(0);
      }
      rs.close();
      if (snippet.length > 0) {
        return snippet;
      }
    } catch (_e) {
    }
    try {
      const rs = await db.querySql(
        'SELECT meta FROM kb_index WHERE path = ? LIMIT 1', [path]);
      if (rs.rowCount > 0) {
        rs.goToFirstRow();
        const meta = rs.getString(0);
        rs.close();
        return meta.substring(0, contextChars);
      }
      rs.close();
    } catch (_e) {
    }
    return '';
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

  async searchWithSnippets(query: string, limit: number = 10): Promise<SearchResult[]> {
    const results = await this.smartSearch(query, limit);
    const db = this.ensureStore();
    const refined = this.refineQuery(query);
    const escapedQuery = this.escapeFtsQuery(refined);
    if (escapedQuery.length === 0) {
      return results;
    }
    for (const sr of results) {
      try {
        const sql =
          'SELECT snippet(kb_index) as snippet ' +
          'FROM kb_index WHERE path = ? AND kb_index MATCH ? LIMIT 1';
        const rs = await db.querySql(sql, [sr.path, escapedQuery]);
        if (rs.rowCount > 0) {
          rs.goToFirstRow();
          sr.snippet = rs.getString(0);
        }
        rs.close();
      } catch (_e) {
        if (sr.snippet.length === 0) {
          sr.snippet = sr.sourceInfo;
        }
      }
    }
    return results;
  }

  async getRelatedPages(path: string, limit: number = 5): Promise<SearchResult[]> {
    const page = await this.getPage(path);
    if (page === null) {
      return [];
    }
    const queryParts: string[] = [];
    if (page.title.length > 0) {
      queryParts.push(page.title);
    }
    const wikilinks = this.extractWikilinks(page.content);
    for (const link of wikilinks) {
      const linkTitle = link.split('/').pop() || '';
      const baseName = linkTitle.replace(/\.md$/, '');
      if (baseName.length > 0) {
        queryParts.push(baseName);
      }
    }
    if (queryParts.length === 0) {
      return [];
    }
    const query = queryParts.slice(0, 3).join(' ');
    const results = await this.search(query, limit + 1);
    return results.filter((sr: SearchResult): boolean => sr.path !== path).slice(0, limit);
  }

  extractWikilinks(content: string): string[] {
    const regex = /\[\[([^\]]+)\]\]/g;
    const links: string[] = [];
    let match: RegExpExecArray | null;
    while ((match = regex.exec(content)) !== null) {
      if (match.length > 1) {
        links.push(match[1]);
      }
    }
    return links;
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
    const prefs = await this.getPreferences();
    prefs.putSync(PREFS_KB_INDEXED, 0);
    await prefs.flush();
    const db = this.ensureStore();
    await db.executeSql('DELETE FROM kb_index');
    await db.executeSql('DELETE FROM kb_dir');
    await db.executeSql('DELETE FROM kb_content');
    const startTime = Date.now();
    await this.buildIndex(context);
    prefs.putSync(PREFS_KB_INDEXED, KB_DB_VERSION);
    await prefs.flush();
    hilog.info(DOMAIN, TAG, 'Force reindex done in ' + (Date.now() - startTime) + 'ms');
  }

  async testSearch(query: string): Promise<string> {
    const db = this.ensureStore();
    const refined = this.refineQuery(query);
    const escapedQuery = this.escapeFtsQuery(refined);
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
      const smartResults = await this.smartSearch(query, 5);
      const smartPaths: string[] = [];
      for (const sr of smartResults) {
        smartPaths.push(sr.path + '|' + sr.title);
      }
      return ftsResult + ', smart_results=' + smartResults.length.toString() + ', smart_paths=' + smartPaths.join('; ');
    } catch (e) {
      const msg = e instanceof Error ? e.message : 'unknown';
      return diagInfo + ', ERROR=' + msg;
    }
  }
}
