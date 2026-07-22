import { SearchResult } from '../../services/KnowledgeService';

export class DomainEntry {
  name: string = '';
  keys: string[] = [];
  hasData: boolean = false;
}

export class ParsedRecommendations {
  recommendations: GuidelineRecommendation[] = [];
  summary: string = '';
  gaps: GapSignal[] = [];
}

export class GuidelineRecommendation {
  text: string = '';
  evidenceLevel: string = '';
  source: string = '';
  category: string = '';
  type: string = '';
}

export class PathScore {
  path: string = '';
  score: number = 0;
}

export class AgentStep {
  agent: string = '';
  status: string = '';
  input: string = '';
  output: string = '';
  durationMs: number = 0;

  toJson(): Record<string, Object> {
    return {
      'agent': this.agent,
      'status': this.status,
      'input': this.input,
      'output': this.output,
      'durationMs': this.durationMs,
    };
  }

  static fromJson(obj: Record<string, Object>): AgentStep {
    const s = new AgentStep();
    s.agent = (obj['agent'] as string) || '';
    s.status = (obj['status'] as string) || '';
    s.input = (obj['input'] as string) || '';
    s.output = (obj['output'] as string) || '';
    s.durationMs = (obj['durationMs'] as number) || 0;
    return s;
  }
}

export class AuditIssue {
  index: number = 0;
  type: string = '';
  description: string = '';
}

export class GapSignal {
  category: string = '';
  supplementaryTerms: string[] = [];
}

export class AuditAgentResult {
  issues: AuditIssue[] = [];
  gaps: GapSignal[] = [];
}

export class DiagnosisKbData {
  ruleId: string = '';
  searchResults: SearchResult[] = [];
  verifiedPaths: string[] = [];
  partialPaths: string[] = [];
  candidatePaths: string[] = [];
  recommendations: GuidelineRecommendation[] = [];
  loadingKb: boolean = false;
  loadingAdvice: boolean = false;
  summary: string = '';
  verifyInfo: string = '';
  isLowRelevance: boolean = false;
  adviceError: string = '';
  agentSteps: AgentStep[] = [];
  feedbackRound: number = 0;
  expandedInfo: string = '';
  matchedDirs: string[] = [];
  expandedSearchTerms: string[] = [];
  expandedEtiologyTerms: string[] = [];
  expandedTreatmentTerms: string[] = [];
  expandedMonitoringTerms: string[] = [];

  toJson(): string {
    const srList: Record<string, string>[] = [];
    for (const sr of this.searchResults) {
      srList.push({ 'path': sr.path, 'title': sr.title });
    }
    const recList: Record<string, string>[] = [];
    for (const rec of this.recommendations) {
      recList.push({ 'text': rec.text, 'evidenceLevel': rec.evidenceLevel, 'source': rec.source, 'category': rec.category, 'type': rec.type });
    }
    const stepsList: Record<string, Object>[] = [];
    for (const step of this.agentSteps) {
      stepsList.push(step.toJson());
    }
    const obj: Record<string, Object> = {
      'ruleId': this.ruleId,
      'searchResults': srList,
      'verifiedPaths': this.verifiedPaths,
      'partialPaths': this.partialPaths,
      'candidatePaths': this.candidatePaths,
      'recommendations': recList,
      'summary': this.summary,
      'verifyInfo': this.verifyInfo,
      'isLowRelevance': this.isLowRelevance,
      'adviceError': this.adviceError,
      'agentSteps': stepsList,
      'feedbackRound': this.feedbackRound,
      'expandedInfo': this.expandedInfo,
      'matchedDirs': this.matchedDirs,
      'expandedSearchTerms': this.expandedSearchTerms,
      'expandedEtiologyTerms': this.expandedEtiologyTerms,
      'expandedTreatmentTerms': this.expandedTreatmentTerms,
      'expandedMonitoringTerms': this.expandedMonitoringTerms,
    };
    return JSON.stringify(obj);
  }

  static fromJson(jsonStr: string): DiagnosisKbData | null {
    const parsed: Object | null = JSON.parse(jsonStr);
    if (parsed === null) {
      return null;
    }
    const obj = parsed as Record<string, Object>;
    const d = new DiagnosisKbData();
    d.ruleId = (obj['ruleId'] as string) || '';
    const srArr = obj['searchResults'] as Array<Record<string, string>>;
    if (srArr !== undefined && srArr !== null) {
      for (const sr of srArr) {
        const searchResult = new SearchResult();
        searchResult.path = sr['path'] || '';
        searchResult.title = sr['title'] || '';
        d.searchResults.push(searchResult);
      }
    }
    const vpArr = obj['verifiedPaths'] as Array<string>;
    if (vpArr !== undefined && vpArr !== null) {
      d.verifiedPaths = vpArr;
    }
    const ppArr = obj['partialPaths'] as Array<string>;
    if (ppArr !== undefined && ppArr !== null) {
      d.partialPaths = ppArr;
    }
    const recArr = obj['recommendations'] as Array<Record<string, string>>;
    if (recArr !== undefined && recArr !== null) {
      for (const rec of recArr) {
        const gr = new GuidelineRecommendation();
        gr.text = rec['text'] || '';
        gr.evidenceLevel = rec['evidenceLevel'] || '未标注';
        gr.source = rec['source'] || '';
        gr.category = rec['category'] || '';
        gr.type = rec['type'] || '';
        d.recommendations.push(gr);
      }
    }
    d.summary = (obj['summary'] as string) || '';
    d.verifyInfo = (obj['verifyInfo'] as string) || '';
    d.isLowRelevance = (obj['isLowRelevance'] as boolean) || false;
    d.adviceError = (obj['adviceError'] as string) || '';
    const cpArr = obj['candidatePaths'] as Array<string>;
    if (cpArr !== undefined && cpArr !== null) {
      d.candidatePaths = cpArr;
    }
    const stepsArr = obj['agentSteps'] as Array<Record<string, Object>>;
    if (stepsArr !== undefined && stepsArr !== null) {
      for (const stepObj of stepsArr) {
        d.agentSteps.push(AgentStep.fromJson(stepObj));
      }
    }
    d.feedbackRound = (obj['feedbackRound'] as number) || 0;
    d.expandedInfo = (obj['expandedInfo'] as string) || '';
    const mdArr = obj['matchedDirs'] as Array<string>;
    if (mdArr !== undefined && mdArr !== null) {
      d.matchedDirs = mdArr;
    }
    const estArr = obj['expandedSearchTerms'] as Array<string>;
    if (estArr !== undefined && estArr !== null) { d.expandedSearchTerms = estArr; }
    const eetArr = obj['expandedEtiologyTerms'] as Array<string>;
    if (eetArr !== undefined && eetArr !== null) { d.expandedEtiologyTerms = eetArr; }
    const ettArr = obj['expandedTreatmentTerms'] as Array<string>;
    if (ettArr !== undefined && ettArr !== null) { d.expandedTreatmentTerms = ettArr; }
    const emtArr = obj['expandedMonitoringTerms'] as Array<string>;
    if (emtArr !== undefined && emtArr !== null) { d.expandedMonitoringTerms = emtArr; }
    return d;
  }
}
