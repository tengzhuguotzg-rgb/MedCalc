import { PatientDiagnosis } from '../../model/Patient';
import { AppColors } from '../../utils/AppColors';
import { SearchResult } from '../../services/KnowledgeService';
import { DiagnosisKbData, AgentStep } from './PatientDetailTypes';
import { getKbSearchResultTitle, getKbGuidelineName, getRecommendationSummary, getDiagnosisKb } from './PatientDetailUtils';
import { MarkdownLine, parseKbMarkdown } from '../../utils/KbMarkdownParser';
import { PreferencesService } from '../../services/PreferencesService';

@Component
export struct DiagnosisKbSection {
  @Prop diag: PatientDiagnosis = new PatientDiagnosis();
  @Prop currentPatientId: string = '';
  @Link diagnosisKbMap: DiagnosisKbData[];
  @Link expandedRefIds: Set<string>;
  @Prop adviceReadyRuleId: string = '';
  @Link activeAdviceRuleId: string;
  @Link summaryLines: MarkdownLine[];
  @Link showRecommendationsDetail: boolean;
  @Consume kbReaderPath: string;
  @Consume kbReaderTitle: string;
  @Consume showKbReader: boolean;
  onLoadDiagnosisKb: () => void = () => {};
  onLoadDiagnosisAdvice: (diag: PatientDiagnosis) => void = () => {};

  build() {
    if (getDiagnosisKb(this.diagnosisKbMap, this.diag.ruleId) !== null) {
      Column() {
        Row()
          .width('100%')
          .height(1)
          .backgroundColor(AppColors.divider)
          .margin({ top: 8, bottom: 8 });

        Row() {
          Text('指南参考')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.primary);
          if (getDiagnosisKb(this.diagnosisKbMap,this.diag.ruleId)!.searchResults.length > 0) {
            Text(this.expandedRefIds.has(this.diag.ruleId) ? ' ▲' : ' ▼')
              .fontSize(11)
              .fontColor(AppColors.textSecondary)
              .margin({ left: 4 });
            Text(getDiagnosisKb(this.diagnosisKbMap,this.diag.ruleId)!.searchResults.length.toString() + '篇')
              .fontSize(10)
              .fontColor(AppColors.textSecondary)
              .margin({ left: 4 });
          }
          Blank();
          if (!getDiagnosisKb(this.diagnosisKbMap,this.diag.ruleId)!.loadingKb) {
            Text('重搜')
              .fontSize(10)
              .fontColor(AppColors.warningText)
              .backgroundColor(AppColors.tierWarnBg)
              .borderRadius(3)
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .margin({ right: 8 })
              .onClick(() => {
                this.diagnosisKbMap = this.diagnosisKbMap.filter((d: DiagnosisKbData): boolean => d.ruleId !== this.diag.ruleId);
                this.expandedRefIds.delete(this.diag.ruleId);
                this.expandedRefIds = new Set(this.expandedRefIds);
                const prefsService = PreferencesService.getInstance();
                prefsService.saveDiagnosisKbData(this.currentPatientId, this.diag.ruleId, '');
                this.onLoadDiagnosisKb();
              });
          }
          if (getDiagnosisKb(this.diagnosisKbMap,this.diag.ruleId)!.searchResults.length > 0) {
            Text(this.expandedRefIds.has(this.diag.ruleId) ? '收起' : '展开')
              .fontSize(11)
              .fontColor(AppColors.primary);
          }
        }
        .width('100%')
        .onClick(() => {
          if (this.expandedRefIds.has(this.diag.ruleId)) {
            this.expandedRefIds.delete(this.diag.ruleId);
          } else {
            this.expandedRefIds.add(this.diag.ruleId);
          }
          this.expandedRefIds = new Set(this.expandedRefIds);
        });

        if (getDiagnosisKb(this.diagnosisKbMap,this.diag.ruleId)!.loadingKb) {
          this.AgentStepList(getDiagnosisKb(this.diagnosisKbMap,this.diag.ruleId)!.agentSteps, false);
        } else if (this.expandedRefIds.has(this.diag.ruleId) && getDiagnosisKb(this.diagnosisKbMap,this.diag.ruleId)!.searchResults.length > 0) {
          Column() {
            ForEach(getDiagnosisKb(this.diagnosisKbMap,this.diag.ruleId)!.searchResults, (sr: SearchResult) => {
              Column() {
                Row() {
                  Text(getKbSearchResultTitle(sr))
                    .fontSize(10)
                    .fontColor(AppColors.primary)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .layoutWeight(1);
                  if (getDiagnosisKb(this.diagnosisKbMap,this.diag.ruleId)!.partialPaths.indexOf(sr.path) >= 0) {
                    Text('片段')
                      .fontSize(8)
                      .fontColor(AppColors.warningText)
                      .backgroundColor(AppColors.tierWarnBg)
                      .borderRadius(2)
                      .padding({ left: 3, right: 3, top: 0, bottom: 0 })
                      .margin({ left: 4 });
                  }
                }
                .width('100%');
                Text(getKbGuidelineName(sr))
                  .fontSize(9)
                  .fontColor(AppColors.textSecondary)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width('100%');
              }
              .width('100%')
              .padding({ top: 4, bottom: 4 })
              .onClick(() => {
                this.kbReaderPath = sr.path;
                this.kbReaderTitle = getKbSearchResultTitle(sr);
                this.showKbReader = true;
              });
            }, (sr: SearchResult) => sr.path);
          }
          .margin({ top: 4 });
        }

        Row()
          .width('100%')
          .height(1)
          .backgroundColor(AppColors.divider)
          .margin({ top: 8, bottom: 8 });

        if (getDiagnosisKb(this.diagnosisKbMap,this.diag.ruleId)!.loadingKb) {
          Row() {
            LoadingProgress().width(14).height(14).color(AppColors.textSecondary);
            Text('搜索指南中...')
              .fontSize(11)
              .fontColor(AppColors.textSecondary)
              .margin({ left: 6 });
          }
          .margin({ top: 6 });
        } else if (getDiagnosisKb(this.diagnosisKbMap,this.diag.ruleId)!.loadingAdvice) {
          this.AgentStepList(getDiagnosisKb(this.diagnosisKbMap,this.diag.ruleId)!.agentSteps, true);
        } else if (getDiagnosisKb(this.diagnosisKbMap,this.diag.ruleId)!.recommendations.length > 0) {
          Row() {
            Text('指南建议 · ' + getRecommendationSummary(getDiagnosisKb(this.diagnosisKbMap,this.diag.ruleId)!.recommendations))
              .fontSize(12)
              .fontColor(AppColors.primary)
              .fontWeight(FontWeight.Medium);
            Blank();
            if (this.adviceReadyRuleId === this.diag.ruleId) {
              Text('已就绪')
                .fontSize(10)
                .fontColor(AppColors.tierOk)
                .backgroundColor(AppColors.tierOkBg)
                .borderRadius(3)
                .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                .margin({ right: 4 });
            }
            Text('查看 >')
              .fontSize(12)
              .fontColor(AppColors.primary);
          }
          .width('100%')
          .padding({ top: 6, bottom: 6 })
          .onClick(() => {
            this.activeAdviceRuleId = this.diag.ruleId;
            const kbData2 = getDiagnosisKb(this.diagnosisKbMap,this.diag.ruleId);
            this.summaryLines = kbData2 !== null && kbData2.summary.length > 0 ? parseKbMarkdown(kbData2.summary) : [];
            this.showRecommendationsDetail = true;
          });
        } else if (getDiagnosisKb(this.diagnosisKbMap,this.diag.ruleId)!.adviceError.length > 0) {
          Column() {
            Row() {
              Text(getDiagnosisKb(this.diagnosisKbMap,this.diag.ruleId)!.adviceError)
                .fontSize(10)
                .fontColor(AppColors.tierWarn)
                .layoutWeight(1)
                .maxLines(3)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            Row() {
              if (getDiagnosisKb(this.diagnosisKbMap,this.diag.ruleId)!.summary.length > 0) {
                Text('详情 >')
                  .fontSize(10)
                  .fontColor(AppColors.primary)
                  .onClick(() => {
                    this.activeAdviceRuleId = this.diag.ruleId;
                    const kbD = getDiagnosisKb(this.diagnosisKbMap,this.diag.ruleId);
                    this.summaryLines = kbD !== null && kbD.summary.length > 0 ? parseKbMarkdown(kbD.summary) : [];
                    this.showRecommendationsDetail = true;
                  });
              }
              if (getDiagnosisKb(this.diagnosisKbMap,this.diag.ruleId)!.searchResults.length > 0) {
                Text('重试建议')
                  .fontSize(10)
                  .fontColor(AppColors.primary)
                  .margin({ left: 8 })
                  .onClick(() => {
                    const kbD2 = getDiagnosisKb(this.diagnosisKbMap,this.diag.ruleId);
                    if (kbD2 !== null) {
                      kbD2.loadingAdvice = true;
                      kbD2.adviceError = '';
                      kbD2.recommendations = [];
                      this.diagnosisKbMap = [...this.diagnosisKbMap];
                      this.onLoadDiagnosisAdvice(this.diag);
                    }
                  });
              }
              Blank();
              Text('重搜')
                .fontSize(10)
                .fontColor(AppColors.primary)
                .onClick(() => {
                  this.diagnosisKbMap = this.diagnosisKbMap.filter((d: DiagnosisKbData): boolean => d.ruleId !== this.diag.ruleId);
                  this.expandedRefIds.delete(this.diag.ruleId);
                  this.expandedRefIds = new Set(this.expandedRefIds);
                  const prefsService = PreferencesService.getInstance();
                  prefsService.saveDiagnosisKbData(this.currentPatientId, this.diag.ruleId, '');
                  this.onLoadDiagnosisKb();
                });
            }
            .width('100%')
            .margin({ top: 2 })
          }
          .width('100%')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(AppColors.tierWarnBg)
          .borderRadius(4)
          .margin({ top: 4 });
        } else if (getDiagnosisKb(this.diagnosisKbMap,this.diag.ruleId)!.verifiedPaths.length > 0) {
          Row() {
            Text('查看指南建议')
              .fontSize(12)
              .fontColor(AppColors.primary);
            Blank();
            Text('>')
              .fontSize(12)
              .fontColor(AppColors.primary);
          }
          .width('100%')
          .padding({ top: 6, bottom: 6 })
          .onClick(() => { this.onLoadDiagnosisAdvice(this.diag); });
        } else {
          Text('暂无指南建议')
            .fontSize(11)
            .fontColor(AppColors.textSecondary)
            .margin({ top: 4 });
        }
      }
      .width('100%');
    }
  }

  @Builder
  AgentStepList(steps: AgentStep[], showError: boolean) {
    Column() {
      ForEach(steps, (step: AgentStep) => {
        Row() {
          if (step.status === 'done') {
            Text('✓')
              .fontSize(10)
              .fontColor(AppColors.tierOk)
              .margin({ right: 4 });
          } else if (showError && step.status === 'error') {
            Text('✗')
              .fontSize(10)
              .fontColor(AppColors.tierWarn)
              .margin({ right: 4 });
          } else {
            LoadingProgress().width(10).height(10).color(AppColors.textSecondary)
              .margin({ right: 4 });
          }
          Text(step.agent)
            .fontSize(10)
            .fontWeight(step.status === 'running' ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(step.status === 'running' ? AppColors.primary : AppColors.textSecondary);
          if (step.output.length > 0) {
            Text(step.output)
              .fontSize(9)
              .fontColor(AppColors.textSecondary)
              .margin({ left: 4 });
          }
        }
        .width('100%')
        .padding({ top: 2, bottom: 2 });
      }, (step: AgentStep, index: number) => step.agent + index.toString());
    }
    .margin({ top: 4, left: 4 })
    .width('100%');
  }
}
