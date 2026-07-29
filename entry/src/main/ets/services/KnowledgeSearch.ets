// KnowledgeSearch.ets
// 知识库的"检索 + LLM 增强"模块：FTS 检索核心、目录限制检索、智能检索 v1/v2、结果校验、LLM 扩查询。
// 不作为单例存在；由 KnowledgeService 门面在 init 时通过 attach(store, rm) 注入依赖。
// 仅消费 store 与 ResourceManager，不再持有或迁移它们。

import { relationalStore } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { resourceManager } from '@kit.LocalizationKit';
import { util } from '@kit.ArkTS';
import { sendVisionRequest, ApiServiceConfig } from './LlmService';
import { PreferencesService } from './PreferencesService';
import { extractTitle, extractSourceInfo, extractWikilinks } from '../utils/KbTextUtils';
import { SearchResult, KnowledgePage, ExpandedQueryResult, SmartSearchResult, SmartSearchOutcome, VerifyResult } from './KnowledgeTypes';

const DOMAIN: number = 0x0001;
const TAG: string = 'MedCalc';

const KB_ROOT: string = 'kb';

export class KnowledgeSearch {
  private static readonly STOPWORDS: string[] = [
    '重症', '急性', '慢性', '严重', '重度', '中度', '轻度', '高危', '低危',
    '原发性', '继发性', '先天性', '非', '未特指'
  ];

  private static readonly COMPOUND_PREFIXES: string[] = [
    '社区获得性', '医院获得性', '获得性免疫', '获得性肺炎'
  ];

  private static readonly KB_DIRECTORIES: string =
    '保肝药物|创伤性脑损伤|低镁血症|低镁血症专家共识|癫痫|肺结核|肺炎|急性冠脉综合征|' +
    '急性呼吸窘迫综合征|急性慢加急性肝衰竭|急性缺血性卒中|急性肾损伤|急性胰腺炎|' +
    '慢性阻塞性肺病|泌尿感染|凝血病|脓毒症|热射病|上消化道出血|社区获得性肺炎|' +
    '神经重症撤机|神经重症镇痛镇静|噬血细胞性淋巴组织细胞增生症|糖尿病|微循环障碍|' +
    '哮喘|心脏骤停|休克|血乳酸|血小板输注|液体复苏|' +
    '医院获得性肺炎-呼吸机相关肺炎|应激性溃疡|中枢神经系统感染|自发性脑出血|' +
    '自发性蛛网膜下腔出血|ICU PADIS|ICU营养治疗|实用重症医学|' +
    '2022 AHA ASA Spontaneous Intracerebral Hemorrhage|' +
    '2023 ESICM ARDS Guidelines|' +
    '2023 ESPEN ICU Nutrition|' +
    '2024 ATS ARDS Management Guidelines|' +
    '2024 New Global Definition of ARDS|' +
    '2024 SCCM Corticosteroids Sepsis ARDS CAP|' +
    '2025 ACC Cardiogenic Shock|' +
    '2025 ATS Community-Acquired Pneumonia|' +
    '2025 ESICM Shock and Hemodynamic Monitoring|' +
    '2025 PADIS Focused Update ICU|' +
    '2026 AHA ASA Acute Ischemic Stroke|' +
    '2026 KDIGO AKI AKD Guideline|' +
    '2026 Surviving Sepsis Campaign';

  private store: relationalStore.RdbStore | null = null;
  private rm: resourceManager.ResourceManager | null = null;

  /**
   * 由 KnowledgeService.init 注入已就绪的 RdbStore 与 ResourceManager。
   * KnowledgeSearch 仅消费两者，不管理其生命周期。
   */
  attach(store: relationalStore.RdbStore, rm: resourceManager.ResourceManager): void {
    this.store = store;
    this.rm = rm;
  }

  private ensureStore(): relationalStore.RdbStore {
    if (!this.store) {
      throw new Error('KnowledgeSearch not attached');
    }
    return this.store;
  }

  private ensureRm(): resourceManager.ResourceManager {
    if (!this.rm) {
      throw new Error('KnowledgeSearch resourceManager not attached');
    }
    return this.rm;
  }

  refineQuery(query: string): string {
    const protectedParts: string[] = [];
    let remaining = query;
    for (const cp of KnowledgeSearch.COMPOUND_PREFIXES) {
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
      for (const sw of KnowledgeSearch.STOPWORDS) {
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

  /**
   * 智能检索 v1：扩查询 -> FTS -> LLM 校验；带 R2 反馈回退。
   * 行为与原 KnowledgeService.smartSearch 完全一致。
   * 侧带状态（lastExpandedCount/lastPartialPaths/lastVerifyFallback）折叠进 SmartSearchOutcome 返回值。
   */
  async smartSearch(query: string, limit: number = 10, description: string = ''): Promise<SmartSearchOutcome> {
    const outcome = new SmartSearchOutcome();
    const prefsService = PreferencesService.getInstance();
    const config = prefsService.getActiveLlmConfig();
    hilog.info(DOMAIN, TAG, 'smartSearch: query=' + query + ' desc=' + description + ' config=' + (config !== null ? 'ok' : 'null'));
    if (config === null) {
      hilog.warn(DOMAIN, TAG, 'smartSearch: no LLM config, fallback to basic search');
      outcome.results = await this.search(query, limit);
      return outcome;
    }

    let expandedTerms: string[] = [];
    try {
      expandedTerms = await this.expandQueryWithLlm(query, config, description);
      hilog.info(DOMAIN, TAG, 'smartSearch: expandedTerms=' + expandedTerms.join('|'));
    } catch (_e) {
      expandedTerms = [];
      hilog.warn(DOMAIN, TAG, 'smartSearch: expandQuery failed, fallback');
    }
    let ftsResults: SearchResult[];
    if (expandedTerms.length > 0) {
      const allQueries: string[] = [query];
      for (const term of expandedTerms) {
        allQueries.push(term);
      }
      hilog.info(DOMAIN, TAG, 'smartSearch: searching per-term, count=' + allQueries.length.toString());
      const seen: Record<string, boolean> = {};
      const merged: SearchResult[] = [];
      let rank = 0;
      for (const q of allQueries) {
        const perResults = await this.search(q, 120);
        hilog.info(DOMAIN, TAG, 'smartSearch: term="' + q + '" hits=' + perResults.length.toString());
        for (const sr of perResults) {
          if (seen[sr.path] === undefined) {
            seen[sr.path] = true;
            sr.rank = rank;
            rank++;
            merged.push(sr);
          }
        }
      }
      ftsResults = merged;
    } else {
      hilog.warn(DOMAIN, TAG, 'smartSearch: no expanded terms, using original query');
      ftsResults = await this.search(query, 120);
    }

    if (ftsResults.length === 0) {
      outcome.expandedCount = 0;
      outcome.partialPaths = [];
      outcome.verifyFallback = false;
      outcome.results = [];
      return outcome;
    }

    outcome.expandedCount = ftsResults.length;
    hilog.info(DOMAIN, TAG, 'smartSearch: merged FTS results=' + ftsResults.length.toString());
    for (let i = 0; i < Math.min(50, ftsResults.length); i++) {
      hilog.info(DOMAIN, TAG, '  FTS[' + i.toString() + ']: ' + ftsResults[i].path);
    }
    const verifyResult = await this.verifyResultsWithLlm(query, ftsResults, config, limit, description);
    if (verifyResult.verified.length > 0) {
      outcome.results = verifyResult.verified;
      outcome.partialPaths = verifyResult.partialPaths;
      outcome.verifyFallback = verifyResult.fallback;
      return outcome;
    }

    if (ftsResults.length > 0) {
      hilog.info(DOMAIN, TAG, 'smartSearch: R1 all rejected, trying R2 with feedback');
      const feedbackTopics = ftsResults.slice(0, 10).map((sr: SearchResult): string => sr.path.split('/')[0]).join('、');
      const r2Prompt = '你是重症医学文献检索专家。用户正在ICU知识库中搜索文献，但第一轮搜索未找到相关结果。' +
        '请根据反馈信息重新生成3-6个扩展检索词。只输出扩展词，每行一个，不要编号，不要解释。' +
        '扩展词必须是ICU指南和教材中常见的疾病名/综合征名/治疗主题名，不要用学术分类名。' +
        '例如不要输出"阴离子间隙""高氯性酸中毒"，而应输出"脓毒症""休克""CRRT"等临床词。';
      const r2Feedback = '查询词"' + query + '"的第一轮搜索结果全部不相关。搜索结果主题包括：' +
        feedbackTopics + '。请重新生成3-6个更精准的扩展检索词，覆盖不同方向。';
      try {
        const r2Terms = await this.expandQueryWithLlm(query, config, r2Prompt, r2Feedback);
        if (r2Terms.length > 0) {
          const r2AllQueries: string[] = [query];
          for (const term of r2Terms) {
            r2AllQueries.push(term);
          }
          const r2Seen: Record<string, boolean> = {};
          const r2Merged: SearchResult[] = [];
          let r2Rank = 0;
          for (const q of r2AllQueries) {
            const perResults = await this.search(q, 120);
            for (const sr of perResults) {
              if (r2Seen[sr.path] === undefined) {
                r2Seen[sr.path] = true;
                sr.rank = r2Rank;
                r2Rank++;
                r2Merged.push(sr);
              }
            }
          }
          if (r2Merged.length > 0) {
            hilog.info(DOMAIN, TAG, 'smartSearch: R2 merged=' + r2Merged.length.toString());
            const r2Verify = await this.verifyResultsWithLlm(query, r2Merged, config, limit, description);
            if (r2Verify.verified.length > 0) {
              outcome.results = r2Verify.verified;
              outcome.partialPaths = r2Verify.partialPaths;
              outcome.verifyFallback = r2Verify.fallback;
              return outcome;
            }
          }
        }
      } catch (_e) {
        hilog.warn(DOMAIN, TAG, 'smartSearch: R2 failed');
      }
    }

    outcome.verifyFallback = true;
    outcome.results = ftsResults.slice(0, limit);
    return outcome;
  }

  private async verifyResultsWithLlm(query: string, results: SearchResult[], config: ApiServiceConfig, limit: number,
    description: string = ''): Promise<VerifyResult> {
    try {
      const summaries = await this.batchGetSummaries(results);
      const docList: string[] = [];
      for (let i = 0; i < results.length; i++) {
        const summary = summaries[i];
        docList.push((i + 1).toString() + '. [' + results[i].path + ']' +
          (summary.length > 0 ? ' 摘要：' + summary : ' ' + results[i].title));
      }
      const systemPrompt = '你是重症医学知识库搜索验收专家。给定用户查询词和候选文章列表（含文章摘要），对每篇文章判断其与查询词的相关程度。' +
        '\n\n三级判断标准：' +
        'Y(全文相关)：文章的主要主题就是查询词所述的疾病/综合征，或者是该疾病的核心病因疾病/核心治疗措施。' +
        '例如：查询"Ⅰ型呼吸衰竭"，ARDS是核心病因→Y，氧疗/机械通气/无创通气/高流量氧疗是核心治疗→Y，肺炎/肺栓塞是常见病因→Y。' +
        '查询"代谢性酸中毒"，乳酸酸中毒/酮症酸中毒是核心病因→Y，碳酸氢钠/血液透析/CRRT是核心治疗→Y，糖尿病/休克/急性肾损伤是常见病因→Y。' +
        'P(片段相关)：文章主要主题不是查询词疾病，但文章中有独立段落专门讨论查询词疾病的诊断、监测、治疗等临床内容。' +
        'N(不相关)：文章仅顺带提及查询词。' +
        '\n\n关键：宁可多判Y/P，不要漏掉临床相关文献。' +
        '\n\n输出格式：每篇文章输出"编号:Y"或"编号:P"或"编号:N"，用逗号分隔。不要解释。';
      const userText = '查询词：' + query + (description.length > 0 ? '（' + description + '）' : '') + '\n候选文章：\n' + docList.join('\n');
      hilog.info(DOMAIN, TAG, 'verifyResults: query=' + query + ' candidates=' + results.length.toString() + ' userTextFirst500=' + userText.substring(0, 500));
      const response = await sendVisionRequest(config, systemPrompt, userText, '', '');
      hilog.info(DOMAIN, TAG, 'verifyResults: raw response=' + response);
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
      if (verified.length === 0 && pIndices.length === 0) {
        hilog.warn(DOMAIN, TAG, 'verifyResults: all rejected by LLM, trusting FTS top results as partial');
        const fallback = new VerifyResult();
        fallback.verified = results.slice(0, Math.min(limit, results.length));
        fallback.partialPaths = results.slice(0, Math.min(limit, results.length)).map((sr: SearchResult): string => sr.path);
        fallback.fallback = true;
        return fallback;
      }
      hilog.info(DOMAIN, TAG, 'verifyResults: ' + query + ' Y=' + yIndices.length + ' P=' + pIndices.length + '/' + results.length);
      const ok = new VerifyResult();
      ok.verified = verified;
      ok.partialPaths = partialPaths;
      ok.fallback = false;
      return ok;
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'verifyResults failed: ' + (e instanceof Error ? e.message : 'unknown') + ', fallback to FTS');
      const fb = new VerifyResult();
      fb.verified = results.slice(0, limit);
      fb.partialPaths = [];
      fb.fallback = false;
      return fb;
    }
  }

  async expandQueryV2(query: string, config: ApiServiceConfig, description: string = ''): Promise<ExpandedQueryResult> {
    const result = new ExpandedQueryResult();
    try {
      const systemPrompt =
        '你是重症医学文献检索专家。用户会给你一个ICU临床诊断，你需要为该诊断在知识库中查找相关文献。' +
        '\n\n知识库目录分两类，用|分隔列出：' +
        '\n【中文疾病目录】' + KnowledgeSearch.KB_DIRECTORIES.split('|').filter((d: string): boolean => d.match(/^[0-9]{4}\s/) === null).join('|') +
        '\n【英文指南目录（非常重要，含最新国际指南，务必优先选择）】' + KnowledgeSearch.KB_DIRECTORIES.split('|').filter((d: string): boolean => d.match(/^[0-9]{4}\s/) !== null).join('|') +
        '\n\n请按以下5行格式输出（严格5行）：' +
        '\n第1行：搜索词 — 该诊断的同义词/缩写/别名（3-8个），用空格分隔' +
        '\n第2行：相关目录名 — 从上面目录列表中选择与该诊断直接或间接相关的目录（5-15个），用|分隔，英文指南目录优先' +
        '\n第3行：病因相关词 — 该诊断的常见病因/诱因/关联疾病的临床检索词（3-8个），用空格分隔' +
        '\n第4行：治疗相关词 — 该诊断的关键治疗措施/药物/操作的临床检索词（3-8个），用空格分隔' +
        '\n第5行：监测相关词 — 该诊断的核心监测指标/评估方法/评分工具（3-8个），用空格分隔' +
        '\n\n输出规则：' +
        '\n1. 搜索词必须是ICU指南和教材中常见的临床术语，不要用学术分类名' +
        '\n2. 目录名必须完全照搬上面的目录列表原文（含空格、年份等），不要拆分、缩写或改写目录名，用|分隔多个目录' +
        '\n3. 英文指南目录与中文疾病目录可能指向同一批文件（如"急性呼吸窘迫综合征"和"2023 ESICM ARDS Guidelines"都含ARDS内容），两者都要选' +
        '\n4. 病因/治疗/监测词应覆盖该诊断在ICU场景下的主要临床维度' +
        '\n5. 严格只输出5行，不要编号，不要解释，不要输出原诊断名';
      const userText = '诊断名称：' + query + (description.length > 0 ? '\n诊断依据：' + description : '');
      const response = await sendVisionRequest(config, systemPrompt, userText, '', '');
      hilog.info(DOMAIN, TAG, 'expandQueryV2 raw response for "' + query + '": ' + response);
      const lines = response.split('\n');
      const lineCount = Math.min(lines.length, 5);
      const allTerms: string[] = [];
      const dirSet = KnowledgeSearch.KB_DIRECTORIES.split('|');
      for (let i = 0; i < lineCount; i++) {
        const terms: string[] = [];
        if (i === 1) {
          const dirLine = lines[i];
          const pipeParts = dirLine.split('|').map((s: string): string => s.trim()).filter((s: string): boolean => s.length > 0);
          let validPipeDirs = 0;
          for (const p of pipeParts) {
            if (dirSet.includes(p)) { validPipeDirs++; }
          }
          if (validPipeDirs >= 2 || (pipeParts.length <= 12 && pipeParts.length >= 3 && pipeParts.every((p: string): boolean => p.length > 2))) {
            for (const part of pipeParts) {
              if (part.length > 0 && part !== query) {
                terms.push(part);
                if (!allTerms.includes(part)) { allTerms.push(part); }
              }
            }
          } else {
            const words: string[] = dirLine.split(/[\s,，、；;]+/).map((s: string): string => s.trim().replace(/^[0-9.]+[)、]/, '')).filter((s: string): boolean => s.length > 0);
            const joined = this.reassembleDirectories(words, dirSet);
            for (const d of joined) {
              if (d !== query) {
                terms.push(d);
                if (!allTerms.includes(d)) { allTerms.push(d); }
              }
            }
          }
        } else {
          const parts = lines[i].split(/[\s,，、；;]+/);
          for (const part of parts) {
            const trimmed = part.trim().replace(/^[0-9.]+[)、]/, '');
            if (trimmed.length > 0 && trimmed.length < 30 && trimmed !== query) {
              terms.push(trimmed);
              if (!allTerms.includes(trimmed)) { allTerms.push(trimmed); }
            }
          }
        }
        if (i === 0) { result.searchTerms = terms; }
        else if (i === 1) { result.directories = terms; }
        else if (i === 2) { result.etiologyTerms = terms; }
        else if (i === 3) { result.treatmentTerms = terms; }
        else if (i === 4) { result.monitoringTerms = terms; }
      }
      result.allTerms = allTerms;
      hilog.info(DOMAIN, TAG, 'expandQueryV2: search=' + result.searchTerms.join(',') +
        ' dirs=' + result.directories.join(',') +
        ' etio=' + result.etiologyTerms.join(',') +
        ' treat=' + result.treatmentTerms.join(',') +
        ' mon=' + result.monitoringTerms.join(','));
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'expandQueryV2 failed: ' + (e instanceof Error ? e.message : 'unknown'));
    }
    return result;
  }

  async smartSearchV2(query: string, description: string = ''): Promise<string[]> {
    const prefsService = PreferencesService.getInstance();
    const config = prefsService.getActiveLlmConfig();
    if (config === null) {
      hilog.warn(DOMAIN, TAG, 'smartSearchV2: no LLM config, fallback to basic search');
      const results = await this.search(query, 30);
      return results.map((sr: SearchResult): string => sr.path);
    }
    const expanded = await this.expandQueryV2(query, config, description);
    const matchedDirs = this.matchDirectories(expanded.directories);
    if (!matchedDirs.includes('实用重症医学')) {
      matchedDirs.push('实用重症医学');
    }
    hilog.info(DOMAIN, TAG, 'smartSearchV2: matchedDirs=' + matchedDirs.join(','));
    const ftsTerms: string[] = [];
    for (const t of expanded.searchTerms) { ftsTerms.push(t); }
    for (const t of expanded.etiologyTerms) { ftsTerms.push(t); }
    for (const t of expanded.treatmentTerms) { ftsTerms.push(t); }
    for (const t of expanded.monitoringTerms) { ftsTerms.push(t); }
    const ftsPaths = await this.directoryLimitedFts(matchedDirs, ftsTerms);
    hilog.info(DOMAIN, TAG, 'smartSearchV2: FTS found ' + ftsPaths.length.toString() + ' articles');
    const seen: Record<string, boolean> = {};
    const merged: string[] = [];
    for (const p of ftsPaths) {
      if (seen[p] === undefined) { seen[p] = true; merged.push(p); }
    }
    hilog.info(DOMAIN, TAG, 'smartSearchV2: total candidates=' + merged.length.toString());
    for (let i = 0; i < Math.min(30, merged.length); i++) {
      hilog.info(DOMAIN, TAG, '  [' + i.toString() + ']: ' + merged[i]);
    }
    return merged;
  }

  async smartSearchV2Full(query: string, description: string = ''): Promise<SmartSearchResult> {
    const result = new SmartSearchResult();
    const prefsService = PreferencesService.getInstance();
    const config = prefsService.getActiveLlmConfig();
    if (config === null) {
      hilog.warn(DOMAIN, TAG, 'smartSearchV2Full: no LLM config, fallback');
      const results = await this.search(query, 30);
      result.candidatePaths = results.map((sr: SearchResult): string => sr.path);
      return result;
    }
    result.expanded = await this.expandQueryV2(query, config, description);
    result.matchedDirs = this.matchDirectories(result.expanded.directories);
    if (!result.matchedDirs.includes('实用重症医学')) {
      result.matchedDirs.push('实用重症医学');
    }
    const ftsTerms: string[] = [];
    for (const t of result.expanded.searchTerms) { ftsTerms.push(t); }
    for (const t of result.expanded.etiologyTerms) { ftsTerms.push(t); }
    for (const t of result.expanded.treatmentTerms) { ftsTerms.push(t); }
    for (const t of result.expanded.monitoringTerms) { ftsTerms.push(t); }
    const ftsPaths = await this.directoryLimitedFts(result.matchedDirs, ftsTerms);
    const seen: Record<string, boolean> = {};
    for (const p of ftsPaths) {
      if (seen[p] === undefined) { seen[p] = true; result.candidatePaths.push(p); }
    }
    hilog.info(DOMAIN, TAG, 'smartSearchV2Full: total candidates=' + result.candidatePaths.length.toString());
    return result;
  }

  private reassembleDirectories(words: string[], allDirs: string[]): string[] {
    const result: string[] = [];
    const used: boolean[] = new Array(words.length).fill(false);
    for (let start = 0; start < words.length; start++) {
      if (used[start]) { continue; }
      let bestEnd = start;
      let bestDir = '';
      for (let end = Math.min(start + 8, words.length); end > start; end--) {
        const candidate = words.slice(start, end).join(' ');
        if (allDirs.includes(candidate)) {
          bestEnd = end;
          bestDir = candidate;
          break;
        }
      }
      if (bestDir.length > 0) {
        result.push(bestDir);
        for (let k = start; k < bestEnd; k++) { used[k] = true; }
      } else {
        if (words[start].length > 1) { result.push(words[start]); }
        used[start] = true;
      }
    }
    return result;
  }

  private matchDirectories(inputDirs: string[]): string[] {
    const allDirs = KnowledgeSearch.KB_DIRECTORIES.split('|');
    const matched: string[] = [];
    for (const inputDir of inputDirs) {
      const normalized = inputDir.trim();
      if (normalized.length === 0) { continue; }
      if (allDirs.includes(normalized)) {
        if (!matched.includes(normalized)) { matched.push(normalized); }
        continue;
      }
      if (normalized.length < 2) { continue; }
      for (const kbDir of allDirs) {
        if (kbDir.includes(normalized)) {
          if (!matched.includes(kbDir)) { matched.push(kbDir); }
        }
      }
    }
    return matched;
  }

  async directoryLimitedFts(dirs: string[], terms: string[]): Promise<string[]> {
    if (dirs.length === 0 || terms.length === 0) { return []; }
    const db = this.ensureStore();
    const dirConditions: string[] = [];
    const dirParams: string[] = [];
    for (const dir of dirs) {
      dirConditions.push('path LIKE ?');
      dirParams.push(dir + '/%');
    }
    const escapedTerms: string[] = [];
    for (const term of terms) {
      const trimmed = term.trim();
      if (trimmed.length > 0) {
        escapedTerms.push('"' + trimmed.replace(/"/g, '""') + '"');
      }
    }
    if (escapedTerms.length === 0) { return []; }
    const ftsQuery = escapedTerms.join(' OR ');
    const sql =
      'SELECT path FROM kb_index WHERE kb_index MATCH ? AND (' +
      dirConditions.join(' OR ') + ') LIMIT 200';
    const params: (string | number)[] = [ftsQuery];
    for (const dp of dirParams) { params.push(dp); }
    const paths: string[] = [];
    try {
      const rs = await db.querySql(sql, params);
      if (rs.rowCount > 0) {
        rs.goToFirstRow();
        do {
          paths.push(rs.getString(0));
        } while (rs.goToNextRow());
      }
      rs.close();
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'directoryLimitedFts failed: ' + (e instanceof Error ? e.message : 'unknown'));
    }
    return paths;
  }

  private async expandQueryWithLlm(query: string, config: ApiServiceConfig, description: string = '',
    customSystemPrompt: string = '', customUserText: string = ''): Promise<string[]> {
    try {
      const systemPrompt = customSystemPrompt.length > 0 ? customSystemPrompt :
        '你是重症医学文献检索专家。用户会给你一个临床诊断及其诊断依据，用于在ICU知识库中搜索相关文献。' +
        '请基于诊断名称和诊断依据，生成3-6个扩展检索词。' +
        '\n\n扩展策略（按优先级）：' +
        '1. 同义词/缩写：如"脓毒症"→"败血症""Sepsis"，"AKI"→"急性肾损伤""急性肾衰竭""ARF"' +
        '2. 核心病因/并发症：如"Ⅰ型呼吸衰竭"→"ARDS""急性呼吸窘迫综合征"，"感染性休克"→"脓毒症休克"' +
        '3. 关键治疗/监测主题：如"呼吸衰竭"→"氧疗""机械通气""呼吸支持"，"AKI"→"肾替代治疗""CRRT"' +
        '4. 常见关联疾病：如"Ⅱ型呼吸衰竭"→"COPD""慢性阻塞性肺病"' +
        '\n只输出扩展词，每行一个，不要编号，不要解释，不要输出原查询词。' +
        '\n\n重要约束：' +
        '1. 扩展词应该是ICU指南和教材中常见的疾病名/综合征名/治疗主题名，而不是学术分类名或病理生理描述。' +
        '2. 例如"代谢性酸中毒"不要扩展为"阴离子间隙""高氯性酸中毒""乳酸性酸中毒"等学术分类，' +
        '而应扩展为"脓毒症""休克""急性肾损伤""液体复苏""碳酸氢钠""CRRT"等能直接匹配到文献主题的临床词。' +
        '3. 严格只输出3-6个词，不要输出超过6个。';
      const userText = customUserText.length > 0 ? customUserText :
        '诊断名称：' + query + (description.length > 0 ? '\n诊断标准：' + description : '');
      const response = await sendVisionRequest(config, systemPrompt, userText, '', '');
      hilog.info(DOMAIN, TAG, 'expandQuery raw response for "' + query + '": ' + response);
      const lines = response.split(/[\n,，、；;]+/);
      const terms: string[] = [];
      for (const line of lines) {
        const trimmed = line.trim();
        if (trimmed.length > 0 && trimmed.length < 30 && trimmed !== query) {
          terms.push(trimmed);
        }
      }
      hilog.info(DOMAIN, TAG, 'expandQuery: ' + query + ' -> ' + terms.join(', '));
      return terms.slice(0, 6);
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

  escapeFtsQueryOr(query: string): string {
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

  escapeFtsQuery(query: string): string {
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

  private async batchGetSummaries(results: SearchResult[]): Promise<string[]> {
    const db = this.ensureStore();
    const summaries: string[] = [];
    const placeholders: string[] = [];
    const paths: string[] = [];
    for (const sr of results) {
      placeholders.push('?');
      paths.push(sr.path);
    }
    const sql = 'SELECT path, content FROM kb_content WHERE path IN (' + placeholders.join(',') + ')';
    const summaryMap: Record<string, string> = {};
    try {
      const rs = await db.querySql(sql, paths);
      if (rs.rowCount > 0) {
        rs.goToFirstRow();
        do {
          const p = rs.getString(0);
          const c = rs.getString(1);
          const frontMatterEnd = c.indexOf('---', 4);
          let body = frontMatterEnd > 0 ? c.substring(frontMatterEnd + 3).trim() : c;
          if (body.length > 200) {
            body = body.substring(0, 200);
          }
          summaryMap[p] = body;
        } while (rs.goToNextRow());
      }
      rs.close();
    } catch (_e) {
    }
    for (const sr of results) {
      const s = summaryMap[sr.path];
      summaries.push(s !== undefined ? s : '');
    }
    return summaries;
  }

  private diversifyResults(results: SearchResult[], limit: number): SearchResult[] {
    const topicMap: Record<string, SearchResult[]> = {};
    const order: string[] = [];
    for (const sr of results) {
      const topic = sr.path.split('/')[0];
      if (topicMap[topic] === undefined) {
        topicMap[topic] = [];
        order.push(topic);
      }
      if (topicMap[topic].length < 3) {
        topicMap[topic].push(sr);
      }
    }
    const diversified: SearchResult[] = [];
    let idx = 0;
    while (diversified.length < limit && order.length > 0) {
      let added = false;
      for (const topic of order) {
        const bucket = topicMap[topic];
        if (bucket !== undefined && idx < bucket.length) {
          diversified.push(bucket[idx]);
          added = true;
          if (diversified.length >= limit) {
            break;
          }
        }
      }
      if (!added) {
        break;
      }
      idx++;
    }
    return diversified;
  }

  async searchAndLoad(query: string, limit: number = 3): Promise<KnowledgePage[]> {
    const outcome = await this.smartSearch(query, limit);
    const pages: KnowledgePage[] = [];
    for (const sr of outcome.results) {
      const page = await this.getPage(sr.path);
      if (page !== null && page.content.trim().length >= 100) {
        pages.push(page);
      }
    }
    return pages;
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

  async searchWithSnippets(query: string, limit: number = 10): Promise<SearchResult[]> {
    const outcome = await this.smartSearch(query, limit);
    const results = outcome.results;
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
    const wikilinks = extractWikilinks(page.content);
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

  /**
   * 读取页面正文（db 优先，回退到 raw 资源）。供门面 getPage 透传与 getRelatedPages 内部使用。
   * 行为与原 KnowledgeService.getPage 完全一致。
   */
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
        page.title = extractTitle(content);
        page.content = content;
        page.sourceInfo = extractSourceInfo(content);
        return page;
      }
      rs.close();
    } catch (_e) {
    }
    const rm = this.ensureRm();
    const rawPath = KB_ROOT + '/' + path;
    try {
      const content = await this.readRawFile(rm, rawPath);
      const page = new KnowledgePage();
      page.path = path;
      page.title = extractTitle(content);
      page.content = content;
      page.sourceInfo = extractSourceInfo(content);
      return page;
    } catch (e) {
      const msg = e instanceof Error ? e.message : 'unknown';
      hilog.warn(DOMAIN, TAG, 'Failed to read page ' + path + ': ' + msg);
      return null;
    }
  }

  async batchGetIndexedTitles(paths: string[]): Promise<Map<string, string>> {
    const db = this.ensureStore();
    const result = new Map<string, string>();
    if (paths.length === 0) { return result; }
    const placeholders: string[] = [];
    for (let i = 0; i < paths.length; i++) {
      placeholders.push('?');
    }
    const sql = 'SELECT path, title FROM kb_index WHERE path IN (' + placeholders.join(',') + ')';
    try {
      const rs = await db.querySql(sql, paths);
      if (rs.rowCount > 0) {
        rs.goToFirstRow();
        do {
          result.set(rs.getString(0), rs.getString(1));
        } while (rs.goToNextRow());
      }
      rs.close();
    } catch (_e) {
    }
    return result;
  }

  private async readRawFile(rm: resourceManager.ResourceManager, filePath: string): Promise<string> {
    const uint8Array = await rm.getRawFileContent(filePath);
    const textDecoder = util.TextDecoder.create('utf-8');
    return textDecoder.decodeToString(uint8Array);
  }
}
