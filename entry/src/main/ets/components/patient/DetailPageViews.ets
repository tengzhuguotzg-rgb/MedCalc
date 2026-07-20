import { PatientAlert, PatientLabAlert, PatientDiagnosis, PatientRecord, PatientDashboard } from '../../model/Patient';
import { DataFieldSpec } from '../../services/AssistantService';
import { AppColors } from '../../utils/AppColors';
import { MarkdownLine } from '../../utils/KbMarkdownParser';
import { DomainEntry, DiagnosisKbData, GuidelineRecommendation } from './PatientDetailTypes';
import { parseAlertResult, formatTime, getRecordIcon, getRecordLabel, getDataFieldCount, getDiagnosisNameByRuleId, getCategoryCount, getCategoryBorderColor, getEvidenceColor, getEvidenceBgColor, getWarningAlerts as getWarningAlertsUtil, getUrgencyColor, getUrgencyBgColor, getUrgencyLabel, getLlmConfirmLabel, getLlmConfirmColor, getLlmConfirmBgColor, formatDateTime, getDomainColor, getDomainDataCount, findFieldSpec, getFieldValueLabel, getFieldUnit, isDerivedFlagField, isDisplayableDataKey, getDiagnosesBySource, getDiagnosisKb } from './PatientDetailUtils';
import { AlertCardView, LabAlertCard } from './AlertSubviews';
import { KbMarkdownRenderer } from './KbMarkdownRenderer';
import { DiagnosisKbSection as DiagnosisKbSectionView } from './DiagnosisKbSection';

@Component
export struct AlertDetailPageView {
  @Prop dashboard: PatientDashboard = new PatientDashboard();
  @Link expandedAlertIds: Set<number>;
  onBack: () => void = () => {};

  private getWarningAlerts(): PatientAlert[] {
    return getWarningAlertsUtil(this.dashboard.alerts);
  }

  private isAlertExpanded(alertId: number): boolean {
    return this.expandedAlertIds.has(alertId);
  }

  private toggleAlert(alertId: number): void {
    if (this.expandedAlertIds.has(alertId)) {
      this.expandedAlertIds.delete(alertId);
    } else {
      this.expandedAlertIds.add(alertId);
    }
    this.expandedAlertIds = new Set(this.expandedAlertIds);
  }

  build() {
    Column() {
      Row() {
         Button($r('app.string.common_back'))
          .fontSize(14)
          .fontColor(AppColors.primary)
          .backgroundColor(Color.Transparent)
          .onClick(() => { this.onBack(); })
         Text($r('app.string.alert_detail_title'))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.primary)
          .layoutWeight(1)
          .margin({ left: 8 })
        if (this.getWarningAlerts().length + this.dashboard.labAlerts.length > 0) {
          Text((this.getWarningAlerts().length + this.dashboard.labAlerts.length).toString())
            .fontSize(12)
            .fontColor(AppColors.card)
            .backgroundColor(AppColors.danger)
            .borderRadius(10)
            .padding({ left: 6, right: 6, top: 1, bottom: 1 })
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor(AppColors.card)

      Scroll() {
        Column() {
          if (this.getWarningAlerts().length === 0 && this.dashboard.labAlerts.length === 0) {
             Text($r('app.string.alert_no_warning'))
              .fontSize(14)
              .fontColor(AppColors.textSecondary)
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding(40)
          } else {
            if (this.getWarningAlerts().length > 0) {
              Column() {
                Row() {
                   Text($r('app.string.alert_score_warning'))
                    .fontSize(13)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(AppColors.primary)
                }
                .width('100%')
                .margin({ bottom: 4 })
                ForEach(this.getWarningAlerts(), (alert: PatientAlert) => {
                  AlertCardView({
                    alert: alert,
                    isExpanded: this.isAlertExpanded(alert.id),
                    onToggle: () => { this.toggleAlert(alert.id); }
                  });
                }, (alert: PatientAlert) => alert.id.toString())
              }
              .width('100%')
              .margin({ bottom: 8 });
            }
            if (this.dashboard.labAlerts.length > 0) {
              Column() {
                Row() {
                   Text($r('app.string.alert_lab_warning'))
                    .fontSize(13)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(AppColors.primary)
                }
                .width('100%')
                .margin({ bottom: 4 })
                ForEach(this.dashboard.labAlerts, (la: PatientLabAlert) => {
                  LabAlertCard({ la: la });
                }, (la: PatientLabAlert) => la.id.toString())
              }
              .width('100%');
            }
          }
        }
        .padding({ left: 16, right: 16, top: 8, bottom: 16 })
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.surfaceMuted)
  }
}

@Component
export struct DiagnosisDetailPageView {
  @Prop dashboard: PatientDashboard = new PatientDashboard();
  @Prop currentPatientId: string = '';
  @Prop loading: boolean = false;
  @Link addDiagName: string;
  @Link addDiagCategory: string;
  @Link showAddDiagnosis: boolean;
  @Link diagnosisKbMap: DiagnosisKbData[];
  @Link expandedRefIds: Set<string>;
  @Prop adviceReadyRuleId: string = '';
  @Link activeAdviceRuleId: string;
  @Link summaryLines: MarkdownLine[];
  @Link showRecommendationsDetail: boolean;
  onBack: () => void = () => {};
  onReDiagnose: () => void = () => {};
  onToggleAddDiagnosis: () => void = () => {};
  onLoadDiagnosisKb: () => void = () => {};
  onLoadDiagnosisAdvice: (diag: PatientDiagnosis) => void = () => {};
  onDeleteUserDiagnosis: (diag: PatientDiagnosis) => void = () => {};

  @Builder
  DiagnosisCard(diag: PatientDiagnosis, isLlmGroup: boolean) {
    Column() {
      Row() {
        if (isLlmGroup) {
          Text('💡')
            .fontSize(12)
            .margin({ right: 4 })
        }
        Text(diag.name)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.primary)
          .layoutWeight(1)
        Text(getUrgencyLabel(diag.urgency))
          .fontSize(10)
          .fontColor(getUrgencyColor(diag.urgency))
          .backgroundColor(getUrgencyBgColor(diag.urgency))
          .borderRadius(4)
          .padding({ left: 4, right: 4, top: 1, bottom: 1 })
          .margin({ left: 4 })
        if (diag.source === 'rule' && diag.llmConfirmed !== 1) {
          Text(getLlmConfirmLabel(diag.llmConfirmed))
            .fontSize(10)
            .fontColor(getLlmConfirmColor(diag.llmConfirmed))
            .backgroundColor(getLlmConfirmBgColor(diag.llmConfirmed))
            .borderRadius(4)
            .padding({ left: 4, right: 4, top: 1, bottom: 1 })
            .margin({ left: 4 })
        }
        if (diag.source === 'user') {
          Text('×')
            .fontSize(14)
            .fontColor(AppColors.textSecondary)
            .margin({ left: 4 })
            .onClick(() => {
              this.onDeleteUserDiagnosis(diag);
            })
        }
      }
      .width('100%')
      if (diag.missingCriteria.length > 0) {
        Column() {
          Text('缺：' + diag.missingCriteria)
            .fontSize(11)
            .fontColor(AppColors.tierWarn)
            .width('100%')
        }
        .width('100%')
        .margin({ top: 4 })
        .padding(6)
        .backgroundColor(AppColors.tierWarnBg)
        .borderRadius(4)
      }
      if (diag.llmNote.length > 0) {
        Text(diag.llmNote)
          .fontSize(12)
          .fontColor(AppColors.textBody)
          .margin({ top: 4 })
          .width('100%')
      }
      Row() {
        Text(diag.category)
          .fontSize(10)
          .fontColor(AppColors.textSecondary)
          .backgroundColor(AppColors.surfaceMuted)
          .borderRadius(4)
          .padding({ left: 4, right: 4, top: 1, bottom: 1 })
        Text(formatDateTime(diag.triggeredAt))
          .fontSize(10)
          .fontColor(AppColors.textSecondary)
          .margin({ left: 8 })
      }
      .margin({ top: 4 })
      .width('100%')

      DiagnosisKbSectionView({
        diag: diag,
        currentPatientId: this.currentPatientId,
        diagnosisKbMap: $diagnosisKbMap,
        expandedRefIds: $expandedRefIds,
        adviceReadyRuleId: this.adviceReadyRuleId,
        activeAdviceRuleId: $activeAdviceRuleId,
        summaryLines: $summaryLines,
        showRecommendationsDetail: $showRecommendationsDetail,
        onLoadDiagnosisKb: () => { this.onLoadDiagnosisKb(); },
        onLoadDiagnosisAdvice: (d: PatientDiagnosis) => { this.onLoadDiagnosisAdvice(d); },
      });
    }
    .width('100%')
    .padding(10)
    .backgroundColor(diag.source === 'rule' ? AppColors.card : (diag.source === 'partial' ? AppColors.tierWarnBg : (diag.source === 'llm_hint' ? AppColors.aiAccentBg : AppColors.tierOkBg)))
    .borderRadius(8)
    .border({ width: { left: 4, right: 0, top: 0, bottom: 0 }, color: getUrgencyColor(diag.urgency) })
    .margin({ bottom: 6 })
  }

  @Builder
  DiagnosisGroup(source: string, label: ResourceStr, color: ResourceStr, isLlmGroup: boolean) {
    if (getDiagnosesBySource(this.dashboard.diagnoses, source).length > 0) {
      Column() {
        Row() {
          Column()
            .width(4)
            .height(16)
            .backgroundColor(color)
            .borderRadius(2)
            .margin({ right: 6 })
          Text(label)
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(color)
          Text(getDiagnosesBySource(this.dashboard.diagnoses, source).length.toString())
            .fontSize(11)
            .fontColor(AppColors.textSecondary)
            .margin({ left: 4 })
        }
        .width('100%')
        .margin({ top: 8, bottom: 4 })

        ForEach(getDiagnosesBySource(this.dashboard.diagnoses, source), (diag: PatientDiagnosis) => {
          Row() {
            this.DiagnosisCard(diag, isLlmGroup);
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)
        }, (diag: PatientDiagnosis) => diag.id.toString())
      }
      .width('100%');
    }
  }

  build() {
    Column() {
      Row() {
         Button($r('app.string.common_back'))
          .fontSize(14)
          .fontColor(AppColors.primary)
          .backgroundColor(Color.Transparent)
          .onClick(() => { this.onBack(); })
         Text($r('app.string.diagnosis_detail_title'))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.primary)
          .layoutWeight(1)
          .margin({ left: 8 })
        Row() {
          Text('+')
            .fontSize(14)
            .fontColor(AppColors.primary)
            .margin({ left: 6 })
            .onClick(() => { this.onToggleAddDiagnosis(); })
          Text('⟳')
            .fontSize(16)
            .fontColor(AppColors.tierOk)
            .margin({ left: 8 })
            .onClick(() => { this.onReDiagnose(); })
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor(AppColors.card)

      Scroll() {
        Column() {
          if (this.dashboard.diagnoses.length === 0) {
             Text($r('app.string.dashboard_no_diagnosis'))
              .fontSize(14)
              .fontColor(AppColors.textSecondary)
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding(40)
          } else {
            this.DiagnosisGroup('rule', $r('app.string.diagnosis_group_rule'), AppColors.primary, false);
            this.DiagnosisGroup('user', $r('app.string.diagnosis_group_user'), AppColors.tierOk, false);
            this.DiagnosisGroup('partial', $r('app.string.diagnosis_group_partial'), AppColors.tierWarn, false);
            this.DiagnosisGroup('llm_hint', $r('app.string.diagnosis_group_llm_hint'), AppColors.aiAccent, true);
          }
          Row() {
             Text($r('app.string.diagnosis_add_btn'))
              .fontSize(13)
              .fontColor(AppColors.primary)
              .margin({ top: 8 })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .onClick(() => { this.onToggleAddDiagnosis(); })
        }
        .padding({ left: 16, right: 16, top: 8, bottom: 16 })
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.surfaceMuted)
  }
}

@Component
export struct RecommendationsDetailPageView {
  @Prop dashboard: PatientDashboard = new PatientDashboard();
  @Link activeAdviceRuleId: string;
  @Prop summaryLines: MarkdownLine[] = [];
  @Link expandedCategories: Set<string>;
  @Prop diagnosisKbMap: DiagnosisKbData[] = [];

  onBack: () => void = () => {};

  @Builder
  RecommendationCategorySection(ruleId: string, category: string, title: string) {
    if (getDiagnosisKb(this.diagnosisKbMap, ruleId) !== null) {
      if (getCategoryCount(getDiagnosisKb(this.diagnosisKbMap, ruleId)!.recommendations, category) > 0) {
        Column() {
          Row() {
            Row()
              .width(3)
              .height(14)
              .backgroundColor(getCategoryBorderColor(category))
              .borderRadius(2)
              .margin({ right: 6 });
            Text(title)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.primary);
            Text(getCategoryCount(getDiagnosisKb(this.diagnosisKbMap, ruleId)!.recommendations, category).toString() + '条')
              .fontSize(11)
              .fontColor(AppColors.textSecondary)
              .margin({ left: 6 });
            Blank();
            Text(this.expandedCategories.has(category) ? $r('app.string.kb_collapse_label') : $r('app.string.kb_expand_label'))
              .fontSize(11)
              .fontColor(AppColors.primary);
          }
          .width('100%')
          .margin({ top: 8, bottom: 4 })
          .onClick(() => {
            if (this.expandedCategories.has(category)) {
              this.expandedCategories.delete(category);
            } else {
              this.expandedCategories.add(category);
            }
            this.expandedCategories = new Set(this.expandedCategories);
          });

          if (this.expandedCategories.has(category)) {
            ForEach(getDiagnosisKb(this.diagnosisKbMap, ruleId)!.recommendations, (rec: GuidelineRecommendation) => {
              if (rec.category === category) {
                Column() {
                  Text(rec.text)
                    .fontSize(13)
                    .fontColor(AppColors.textBody)
                    .width('100%');
                  Row() {
                    if (rec.type.length > 0) {
                      Text(rec.type)
                        .fontSize(9)
                        .fontColor(rec.type === '推荐意见' ? AppColors.tierOk : (rec.type === '知识要点' ? AppColors.primary : AppColors.aiAccent))
                        .backgroundColor(rec.type === '推荐意见' ? AppColors.tierOkBg : (rec.type === '知识要点' ? AppColors.background : AppColors.aiAccentBg))
                        .borderRadius(3)
                        .padding({ left: 4, right: 4, top: 1, bottom: 1 });
                    }
                    if (rec.evidenceLevel.length > 0 && rec.evidenceLevel !== '未标注' && rec.evidenceLevel !== '-') {
                      Text(rec.evidenceLevel)
                        .fontSize(10)
                        .fontColor(getEvidenceColor(rec.evidenceLevel))
                        .backgroundColor(getEvidenceBgColor(rec.evidenceLevel))
                        .borderRadius(3)
                        .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                        .margin({ left: 4 });
                    }
                    Blank();
                    if (rec.source.length > 0) {
                      Text(rec.source)
                        .fontSize(9)
                        .fontColor(AppColors.textFaint)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .layoutWeight(1)
                        .textAlign(TextAlign.End);
                    }
                  }
                  .width('100%')
                  .margin({ top: 2 });
                }
                .width('100%')
                .alignItems(HorizontalAlign.Start)
                .padding({ top: 4, bottom: 4, left: 8 })
                .border({ width: { left: 2, right: 0, top: 0, bottom: 0 }, color: getCategoryBorderColor(category) })
                .margin({ bottom: 4 });
              }
            }, (rec: GuidelineRecommendation, index: number) => category + index.toString())
          }
        }
        .width('100%');
      }
    }
  }

  build() {
    Column() {
      Row() {
         Button($r('app.string.common_back'))
          .fontSize(14)
          .fontColor(AppColors.primary)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.onBack();
            this.activeAdviceRuleId = '';
          })
        Text(getDiagnosisNameByRuleId(this.dashboard.diagnoses, this.activeAdviceRuleId) + ' · 指南建议')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.primary)
          .layoutWeight(1)
          .margin({ left: 8 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor(AppColors.card);

      Scroll() {
        Column() {
          if (this.activeAdviceRuleId.length > 0 && getDiagnosisKb(this.diagnosisKbMap, this.activeAdviceRuleId) !== null) {
            if (getDiagnosisKb(this.diagnosisKbMap, this.activeAdviceRuleId)!.isLowRelevance) {
              Row() {
                 Text($r('app.string.kb_low_rel_warning'))
                  .fontSize(11)
                  .fontColor(AppColors.warningText)
                  .fontWeight(FontWeight.Medium)
                 Text($r('app.string.kb_low_rel_hint'))
                  .fontSize(10)
                  .fontColor(AppColors.textFaint)
                  .margin({ left: 6 })
              }
              .width('100%')
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .backgroundColor(AppColors.tierWarnBg)
              .borderRadius(6)
              .margin({ bottom: 8 });
            }
            if (getDiagnosisKb(this.diagnosisKbMap, this.activeAdviceRuleId)!.summary.length > 0) {
              Column() {
                Row() {
                   Text($r('app.string.kb_clinical_keypoints'))
                    .fontSize(14)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(AppColors.primary);
                }
                .width('100%')
                .margin({ bottom: 4 });
                 Text($r('app.string.kb_ai_summary_disclaimer'))
                  .fontSize(10)
                  .fontColor(AppColors.textFaint)
                  .width('100%')
                  .margin({ bottom: 6 });
                KbMarkdownRenderer({ lines: this.summaryLines });
              }
              .width('100%')
              .padding(10)
              .backgroundColor(AppColors.tierWarnBg)
              .borderRadius(8)
              .border({ width: 1, color: AppColors.divider })
              .margin({ bottom: 8 });
            }
            this.RecommendationCategorySection(this.activeAdviceRuleId, '病理生理', '病理生理');
            this.RecommendationCategorySection(this.activeAdviceRuleId, '诊断要点', '诊断要点');
            this.RecommendationCategorySection(this.activeAdviceRuleId, '监测评估', '监测评估');
            this.RecommendationCategorySection(this.activeAdviceRuleId, '治疗建议', '治疗建议');
          }
        }
        .padding({ left: 16, right: 16, top: 8, bottom: 16 })
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.surfaceMuted)
  }
}

@Component
export struct DataDetailPageView {
  @Prop dashboard: PatientDashboard = new PatientDashboard();
  @Prop domainEntries: DomainEntry[] = [];
  @Prop currentPatientId: string = '';
  @Link expandedDomains: Set<string>;
  @Prop dataFieldSpecs: DataFieldSpec[] = [];
  onBack: () => void = () => {};
  onTimelineRequest: (fieldKey: string) => void = () => {};

  build() {
    Column() {
      Row() {
         Button($r('app.string.common_back'))
          .fontSize(14)
          .fontColor(AppColors.primary)
          .backgroundColor(Color.Transparent)
          .onClick(() => { this.onBack(); })
         Text($r('app.string.data_detail_title'))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.primary)
          .layoutWeight(1)
          .margin({ left: 8 })
        Text(getDataFieldCount(this.dashboard, this.dataFieldSpecs) + '项')
          .fontSize(13)
          .fontColor(AppColors.textSecondary)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor(AppColors.card)

      Scroll() {
        Column() {
          if (getDataFieldCount(this.dashboard, this.dataFieldSpecs) === 0) {
             Text($r('app.string.dashboard_no_data'))
              .fontSize(14)
              .fontColor(AppColors.textSecondary)
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding(40)
          } else {
            ForEach(this.domainEntries, (entry: DomainEntry) => {
              Column() {
                Row() {
                  Column()
                    .width(4)
                    .height(16)
                    .backgroundColor(getDomainColor(entry.name))
                    .borderRadius(2)
                    .margin({ right: 8 })
                  Text(entry.name)
                    .fontSize(13)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(AppColors.primary)
                    .layoutWeight(1)
                  Text(getDomainDataCount(entry.keys, this.dashboard, this.dataFieldSpecs) + '项')
                    .fontSize(10)
                    .fontColor(AppColors.card)
                    .backgroundColor(getDomainColor(entry.name))
                    .borderRadius(8)
                    .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                    .margin({ right: 6 })
                  Text(this.expandedDomains.has(entry.name) ? ' ▲' : ' ▼')
                    .fontSize(10)
                    .fontColor(AppColors.textSecondary)
                }
                .width('100%')
                .onClick(() => {
                  if (this.expandedDomains.has(entry.name)) {
                    this.expandedDomains.delete(entry.name);
                  } else {
                    this.expandedDomains.add(entry.name);
                  }
                  this.expandedDomains = new Set(this.expandedDomains);
                })

                if (this.expandedDomains.has(entry.name)) {
                  Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start, alignContent: FlexAlign.Start }) {
                    ForEach(entry.keys, (key: string) => {
                      if (this.dashboard.latestData.has(key) && isDisplayableDataKey(key, this.dataFieldSpecs)) {
                        Column() {
                          Text(getFieldValueLabel(key, this.dataFieldSpecs))
                            .fontSize(10)
                            .fontColor(AppColors.textSecondary)
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                          Row() {
                            Text(this.dashboard.latestData.get(key))
                              .fontSize(14)
                              .fontColor(AppColors.primary)
                              .fontWeight(FontWeight.Bold)
                            if (getFieldUnit(key, this.dataFieldSpecs).length > 0) {
                              Text(getFieldUnit(key, this.dataFieldSpecs))
                                .fontSize(10)
                                .fontColor(AppColors.textSecondary)
                                .margin({ left: 2 })
                            }
                          }
                          .margin({ top: 2 })
                        }
                        .width('48%')
                        .padding({ left: 8, right: 8, top: 6, bottom: 6 })
                        .backgroundColor(AppColors.surfaceMuted)
                        .borderRadius(6)
                        .margin({ bottom: 4, right: '2%' })
                        .alignItems(HorizontalAlign.Start)
                        .onClick(() => {
                          this.onTimelineRequest(key);
                        })
                      }
                    }, (key: string) => key)
                  }
                  .width('100%')
                  .padding({ top: 6 })
                }
              }
              .width('100%')
              .padding(10)
              .backgroundColor(AppColors.card)
              .borderRadius(8)
              .margin({ bottom: 6 })
            }, (entry: DomainEntry) => entry.name)
          }
        }
        .padding({ left: 16, right: 16, top: 8, bottom: 16 })
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.surfaceMuted)
  }
}

@Component
export struct RecordsDetailPageView {
  @Prop dashboard: PatientDashboard = new PatientDashboard();
  @Link expandedRecordIds: Set<string>;
  @Link deleteRecordId: string;
  @Link showDeleteConfirm: boolean;
  onBack: () => void = () => {};

  build() {
    Column() {
      Row() {
         Button($r('app.string.common_back'))
          .fontSize(14)
          .fontColor(AppColors.primary)
          .backgroundColor(Color.Transparent)
          .onClick(() => { this.onBack(); })
         Text($r('app.string.records_detail_title'))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.primary)
          .layoutWeight(1)
          .margin({ left: 8 })
        Text(this.dashboard.records.length + '条')
          .fontSize(13)
          .fontColor(AppColors.textSecondary)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor(AppColors.card)

      Scroll() {
        Column() {
          if (this.dashboard.records.length === 0) {
             Text($r('app.string.dashboard_no_records'))
              .fontSize(14)
              .fontColor(AppColors.textSecondary)
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding(40)
          } else {
            ForEach(this.dashboard.records, (record: PatientRecord) => {
              Column() {
                Row() {
                  Text(getRecordIcon(record.type))
                    .fontSize(14)
                    .margin({ right: 8 })
                  Text(getRecordLabel(record))
                    .fontSize(13)
                    .fontColor(AppColors.primary)
                    .layoutWeight(1)
                   Text($r('app.string.common_delete'))
                    .fontSize(12)
                    .fontColor(AppColors.warning)
                    .margin({ right: 8 })
                    .onClick(() => {
                      this.deleteRecordId = record.id;
                      this.showDeleteConfirm = true;
                    })
                  Text(formatTime(record.timestamp))
                    .fontSize(12)
                    .fontColor(AppColors.textSecondary)
                    .margin({ right: 4 })
                  Text(this.expandedRecordIds.has(record.id) ? ' ▲' : ' ▼')
                    .fontSize(10)
                    .fontColor(AppColors.textSecondary)
                }
                .width('100%')
                .onClick(() => {
                  if (this.expandedRecordIds.has(record.id)) {
                    this.expandedRecordIds.delete(record.id);
                  } else {
                    this.expandedRecordIds.add(record.id);
                  }
                  this.expandedRecordIds = new Set(this.expandedRecordIds);
                })
                if (this.expandedRecordIds.has(record.id) && record.extractedJson.length > 0) {
                  Text(record.extractedJson)
                    .fontSize(11)
                    .fontColor(AppColors.textBody)
                    .width('100%')
                    .padding({ top: 6, bottom: 6 })
                    .lineHeight(16)
                }
              }
              .width('100%')
              .padding(10)
              .backgroundColor(AppColors.card)
              .borderRadius(8)
              .margin({ bottom: 4 })
            }, (record: PatientRecord) => record.id)
          }
        }
        .padding({ left: 16, right: 16, top: 8, bottom: 16 })
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.surfaceMuted)
  }
}
