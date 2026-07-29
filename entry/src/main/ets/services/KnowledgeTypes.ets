// KnowledgeTypes.ets
// 知识库相关共享数据类型，被 KnowledgeService / KnowledgeIndex / KnowledgeSearch 三方共同依赖。
// 单独抽出以避免 service 文件之间的循环 import。

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

export class ExpandedQueryResult {
  searchTerms: string[] = [];
  directories: string[] = [];
  etiologyTerms: string[] = [];
  treatmentTerms: string[] = [];
  monitoringTerms: string[] = [];
  allTerms: string[] = [];
}

export class SmartSearchResult {
  expanded: ExpandedQueryResult = new ExpandedQueryResult();
  matchedDirs: string[] = [];
  candidatePaths: string[] = [];
}

// smartSearch 的结构化返回值：替代原 KnowledgeService 上的 lastExpandedCount/lastPartialPaths/lastVerifyFallback
// 三个零读者的 side-band 字段，折叠到返回值里消除隐性时序耦合。
export class SmartSearchOutcome {
  results: SearchResult[] = [];
  expandedCount: number = 0;
  partialPaths: string[] = [];
  verifyFallback: boolean = false;
}

// verifyResultsWithLlm 的结构化返回值：替代原 side-band 字段
export class VerifyResult {
  verified: SearchResult[] = [];
  partialPaths: string[] = [];
  fallback: boolean = false;
}
