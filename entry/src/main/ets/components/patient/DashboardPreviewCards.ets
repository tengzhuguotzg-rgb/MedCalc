import { PatientDashboard, PatientAlert, PatientLabAlert, PatientDiagnosis, PatientRecord } from '../../model/Patient';
import { AppColors } from '../../utils/AppColors';
import { DomainEntry } from './PatientDetailTypes';
import { getTierColor, getTierBgColor } from '../../engine/CalcEngine';
import {
  parseAlertResult, getUrgencyColor, getUrgencyLabel, getLabAlertUrgencyColor,
  getRecordIcon, getRecordLabel, formatTime,
  getWarningAlerts, getDiagnosisCategoryTags, getDataFieldCount, getDataPreviewItems,
  getRecordPreviewItems
} from './PatientDetailUtils';

@Component
export struct AlertPreviewCard {
  @Prop dashboard: PatientDashboard = new PatientDashboard();
  onTap: () => void = () => {};

  build() {
    Column() {
      Row() {
        Text('预警')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.primary)
        if (getWarningAlerts(this.dashboard.alerts).length + this.dashboard.labAlerts.length > 0) {
          Text((getWarningAlerts(this.dashboard.alerts).length + this.dashboard.labAlerts.length).toString())
            .fontSize(12)
            .fontColor(AppColors.card)
            .backgroundColor(AppColors.danger)
            .borderRadius(10)
            .padding({ left: 6, right: 6, top: 1, bottom: 1 })
            .margin({ left: 6 })
        }
        Blank()
      }
      .width('100%')

      if (getWarningAlerts(this.dashboard.alerts).length > 0) {
        Column() {
          ForEach(getWarningAlerts(this.dashboard.alerts).slice(0, 3), (alert: PatientAlert) => {
            Row() {
              Column()
                .width(3)
                .height(12)
                .backgroundColor(getTierColor(parseAlertResult(alert).tierClass))
                .borderRadius(1)
                .margin({ right: 6 })
              Text(alert.calcName)
                .fontSize(13)
                .fontColor(AppColors.primary)
                .layoutWeight(1)
              Text(parseAlertResult(alert).tier)
                .fontSize(11)
                .fontColor(getTierColor(parseAlertResult(alert).tierClass))
                .maxLines(1)
            }
            .width('100%')
            .padding({ top: 4, bottom: 4 })
          }, (alert: PatientAlert) => alert.id.toString())
          if (getWarningAlerts(this.dashboard.alerts).length > 3) {
            Text('还有' + (getWarningAlerts(this.dashboard.alerts).length - 3) + '项评分预警...')
              .fontSize(11)
              .fontColor(AppColors.textSecondary)
              .margin({ top: 2 })
          }
        }
        .width('100%')
        .margin({ top: 8 })
      }

      if (this.dashboard.labAlerts.length > 0) {
        Column() {
          Row()
            .width('100%')
            .height(1)
            .backgroundColor(AppColors.divider)
            .margin({ top: 4, bottom: 4 });
          ForEach(this.dashboard.labAlerts.slice(0, 3), (la: PatientLabAlert) => {
            Row() {
              Column()
                .width(3)
                .height(12)
                .backgroundColor(getLabAlertUrgencyColor(la.urgency))
                .borderRadius(1)
                .margin({ right: 6 })
              Text(la.fieldLabel + ' ' + la.value)
                .fontSize(12)
                .fontColor(AppColors.primary)
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(la.threshold)
                .fontSize(10)
                .fontColor(getLabAlertUrgencyColor(la.urgency))
                .maxLines(1)
            }
            .width('100%')
            .padding({ top: 3, bottom: 3 })
          }, (la: PatientLabAlert) => la.id.toString())
          if (this.dashboard.labAlerts.length > 3) {
            Text('还有' + (this.dashboard.labAlerts.length - 3) + '项检验预警...')
              .fontSize(11)
              .fontColor(AppColors.textSecondary)
              .margin({ top: 2 })
          }
        }
        .width('100%')
        .margin({ top: 4 })
      }

      if (getWarningAlerts(this.dashboard.alerts).length === 0 && this.dashboard.labAlerts.length === 0) {
        Text('暂无异常预警')
          .fontSize(12)
          .fontColor(AppColors.textSecondary)
          .margin({ top: 4 })
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor(AppColors.card)
    .borderRadius(10)
    .margin({ bottom: 8 })
    .onClick(() => { this.onTap(); })
  }
}

@Component
export struct DiagnosisPreviewCard {
  @Prop dashboard: PatientDashboard = new PatientDashboard();
  onTap: () => void = () => {};

  build() {
    Column() {
      Row() {
        Text('诊断')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.primary)
        if (this.dashboard.diagnosisCount > 0) {
          Text(this.dashboard.diagnosisCount.toString())
            .fontSize(12)
            .fontColor(AppColors.card)
            .backgroundColor(AppColors.primary)
            .borderRadius(10)
            .padding({ left: 6, right: 6, top: 1, bottom: 1 })
            .margin({ left: 6 })
        }
        Blank()
        Row() {
          ForEach(getDiagnosisCategoryTags(this.dashboard.diagnoses).slice(0, 4), (tag: string) => {
            Text(tag)
              .fontSize(10)
              .fontColor(AppColors.primary)
              .backgroundColor(AppColors.fillBeige)
              .borderRadius(4)
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .margin({ left: 3 })
          }, (tag: string) => tag)
        }
      }
      .width('100%')

      if (this.dashboard.diagnoses.length > 0) {
        Column() {
          ForEach(this.dashboard.diagnoses.slice(0, 3), (diag: PatientDiagnosis) => {
            Row() {
              Column()
                .width(3)
                .height(14)
                .backgroundColor(getUrgencyColor(diag.urgency))
                .borderRadius(1)
                .margin({ right: 6 })
              Text(diag.name)
                .fontSize(13)
                .fontColor(AppColors.primary)
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(getUrgencyLabel(diag.urgency))
                .fontSize(9)
                .fontColor(getUrgencyColor(diag.urgency))
                .margin({ left: 4 })
            }
            .width('100%')
            .padding({ top: 3, bottom: 3 })
          }, (diag: PatientDiagnosis) => diag.id.toString())
          if (this.dashboard.diagnoses.length > 3) {
            Text('还有' + (this.dashboard.diagnoses.length - 3) + '项...')
              .fontSize(11)
              .fontColor(AppColors.textSecondary)
              .margin({ top: 2 })
          }
        }
        .width('100%')
        .margin({ top: 8 })
      } else {
        Text('暂无诊断')
          .fontSize(12)
          .fontColor(AppColors.textSecondary)
          .margin({ top: 4 })
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor(AppColors.card)
    .borderRadius(10)
    .margin({ bottom: 12 })
    .onClick(() => { this.onTap(); })
  }
}

@Component
export struct DataPreviewCard {
  @Prop dashboard: PatientDashboard = new PatientDashboard();
  @Prop domainEntries: DomainEntry[] = [];
  @Prop dataFieldCount: number = 0;
  @Prop dataPreviewItems: string[] = [];
  onTap: () => void = () => {};

  build() {
    Column() {
      Row() {
        Text('结构化数据')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.primary)
        if (this.dataFieldCount > 0) {
          Text(this.dataFieldCount.toString())
            .fontSize(12)
            .fontColor(AppColors.card)
            .backgroundColor(AppColors.tierOk)
            .borderRadius(10)
            .padding({ left: 6, right: 6, top: 1, bottom: 1 })
            .margin({ left: 6 })
        }
        Blank()
        Row() {
          ForEach(this.domainEntries.slice(0, 4), (entry: DomainEntry) => {
            Text(entry.name)
              .fontSize(10)
              .fontColor(AppColors.tierOk)
              .backgroundColor(AppColors.fillBeige)
              .borderRadius(4)
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .margin({ left: 3 })
          }, (entry: DomainEntry) => entry.name)
        }
      }
      .width('100%')

      if (this.dataFieldCount > 0) {
        Column() {
          ForEach(this.dataPreviewItems, (item: string) => {
            Row() {
              Column()
                .width(3)
                .height(14)
                .backgroundColor(AppColors.tierOk)
                .borderRadius(1)
                .margin({ right: 6 })
              Text(item)
                .fontSize(13)
                .fontColor(AppColors.primary)
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .padding({ top: 3, bottom: 3 })
          }, (item: string, index: number) => index.toString())
          if (this.dataFieldCount > 5) {
            Text('还有' + (this.dataFieldCount - 5) + '项...')
              .fontSize(11)
              .fontColor(AppColors.textSecondary)
              .margin({ top: 2 })
          }
        }
        .width('100%')
        .margin({ top: 8 })
      } else {
        Text('暂无数据，上传报告或手动录入')
          .fontSize(12)
          .fontColor(AppColors.textSecondary)
          .margin({ top: 4 })
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor(AppColors.card)
    .borderRadius(10)
    .margin({ bottom: 8 })
    .onClick(() => { this.onTap(); })
  }
}

@Component
export struct RecordsPreviewCard {
  @Prop dashboard: PatientDashboard = new PatientDashboard();
  @Prop recordPreviewItems: string[] = [];
  onTap: () => void = () => {};

  build() {
    Column() {
      Row() {
        Text('上传记录')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.primary)
        if (this.dashboard.records.length > 0) {
          Text(this.dashboard.records.length.toString())
            .fontSize(12)
            .fontColor(AppColors.card)
            .backgroundColor(AppColors.textSecondary)
            .borderRadius(10)
            .padding({ left: 6, right: 6, top: 1, bottom: 1 })
            .margin({ left: 6 })
        }
        Blank()
        if (this.dashboard.records.length > 3) {
          Text('查看全部')
            .fontSize(12)
            .fontColor(AppColors.tierOk)
        }
      }
      .width('100%')

      if (this.dashboard.records.length > 0) {
        Column() {
          ForEach(this.recordPreviewItems, (item: string) => {
            Row() {
              Column()
                .width(3)
                .height(14)
                .backgroundColor(AppColors.textSecondary)
                .borderRadius(1)
                .margin({ right: 6 })
              Text(item)
                .fontSize(13)
                .fontColor(AppColors.primary)
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .padding({ top: 3, bottom: 3 })
          }, (item: string, index: number) => index.toString())
          if (this.dashboard.records.length > 3) {
            Text('还有' + (this.dashboard.records.length - 3) + '条...')
              .fontSize(11)
              .fontColor(AppColors.textSecondary)
              .margin({ top: 2 })
          }
        }
        .width('100%')
        .margin({ top: 8 })
      } else {
        Text('暂无上传记录')
          .fontSize(12)
          .fontColor(AppColors.textSecondary)
          .margin({ top: 4 })
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor(AppColors.card)
    .borderRadius(10)
    .margin({ bottom: 12 })
    .onClick(() => { this.onTap(); })
  }
}
