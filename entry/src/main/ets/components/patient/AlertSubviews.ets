import { PatientAlert, PatientLabAlert } from '../../model/Patient';
import { AppColors } from '../../utils/AppColors';
import { parseAlertResult, formatResultValue, formatDateTime, getLabAlertUrgencyColor, getLabAlertUrgencyLabel } from './PatientDetailUtils';
import { getTierColor, getTierBgColor } from '../../engine/CalcEngine';

@Component
export struct LabAlertCard {
  @Prop la: PatientLabAlert = new PatientLabAlert();

  build() {
    Column() {
      Row() {
        Column()
          .width(4)
          .height(16)
          .backgroundColor(getLabAlertUrgencyColor(this.la.urgency))
          .borderRadius(2)
          .margin({ right: 8 })
        Column() {
          Text(this.la.name)
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.primary)
            .width('100%')
          Row() {
            Text(this.la.fieldLabel + ' ' + this.la.value + ' ' + this.la.unit)
              .fontSize(12)
              .fontColor(AppColors.textBody)
              .layoutWeight(1)
            Text(this.la.threshold)
              .fontSize(11)
              .fontColor(getLabAlertUrgencyColor(this.la.urgency))
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          .margin({ top: 2 })
          if (this.la.description.length > 0) {
            Text(this.la.description)
              .fontSize(11)
              .fontColor(AppColors.textSecondary)
              .width('100%')
              .margin({ top: 2 })
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        Text(getLabAlertUrgencyLabel(this.la.urgency))
          .fontSize(10)
          .fontColor(AppColors.onPrimary)
          .backgroundColor(getLabAlertUrgencyColor(this.la.urgency))
          .borderRadius(4)
          .padding({ left: 4, right: 4, top: 1, bottom: 1 })
          .margin({ left: 4 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
    }
    .width('100%')
    .padding(10)
    .backgroundColor(AppColors.card)
    .borderRadius(8)
    .margin({ bottom: 6 })
  }
}

@Component
export struct AlertDetailContent {
  @Prop alert: PatientAlert = new PatientAlert();

  build() {
    Column() {
      if (parseAlertResult(this.alert).value !== null) {
        Row() {
          Text(formatResultValue(parseAlertResult(this.alert).value))
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.primary)
          Text(parseAlertResult(this.alert).unit)
            .fontSize(12)
            .fontColor(AppColors.textSecondary)
            .margin({ left: 4, top: 10 })
        }
        .margin({ top: 6, bottom: 4 })
      }
      Text(parseAlertResult(this.alert).tier)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(getTierColor(parseAlertResult(this.alert).tierClass))
        .backgroundColor(getTierBgColor(parseAlertResult(this.alert).tierClass))
        .borderRadius(20)
        .padding({ left: 8, right: 8, top: 2, bottom: 2 })
        .margin({ bottom: 6 })
      if (parseAlertResult(this.alert).footnote.length > 0) {
        Text(parseAlertResult(this.alert).footnote)
          .fontSize(12)
          .fontColor(AppColors.textBody)
          .lineHeight(18)
      }
      Text(formatDateTime(this.alert.triggeredAt))
        .fontSize(11)
        .fontColor(AppColors.textSecondary)
        .margin({ top: 4 })
    }
    .width('100%')
    .padding({ top: 6 })
    .alignItems(HorizontalAlign.Start)
  }
}

@Component
export struct AlertCardView {
  @Prop alert: PatientAlert = new PatientAlert();
  @Prop isExpanded: boolean = false;
  onToggle: () => void = () => {};

  build() {
    Column() {
      Row() {
        Column()
          .width(4)
          .height(16)
          .backgroundColor(getTierColor(parseAlertResult(this.alert).tierClass))
          .borderRadius(2)
          .margin({ right: 8 })
        Text(this.alert.calcName)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.primary)
          .layoutWeight(1)
        Text(parseAlertResult(this.alert).tier)
          .fontSize(11)
          .fontColor(getTierColor(parseAlertResult(this.alert).tierClass))
          .maxLines(1)
          .margin({ right: 6 })
        Text(this.alert.completeness + '%')
          .fontSize(12)
          .fontColor(AppColors.textSecondary)
        Text(this.isExpanded ? ' ▲' : ' ▼')
          .fontSize(10)
          .fontColor(AppColors.textSecondary)
          .margin({ left: 4 })
      }
      .width('100%')
      .onClick(() => { this.onToggle(); })

      if (this.isExpanded) {
        AlertDetailContent({ alert: this.alert });
      }
    }
    .width('100%')
    .padding(10)
    .backgroundColor(AppColors.card)
    .borderRadius(8)
    .margin({ bottom: 6 })
  }
}
