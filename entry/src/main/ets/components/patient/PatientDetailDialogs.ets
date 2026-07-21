import { PatientDataPoint, PatientRecord } from '../../model/Patient';
import { DataFieldSpec } from '../../services/AssistantService';
import { PatientService } from '../../services/PatientService';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { formatDateTime, getFieldValueLabel, getFieldUnit } from './PatientDetailUtils';
import { DIAGNOSIS_CATEGORIES } from '../../model/DiagnosisRules';

@Component
export struct TimelineDialog {
  @Prop timelineField: string = '';
  @Prop timelineData: PatientDataPoint[] = [];
  @Link showTimelineDialog: boolean;
  @Prop dataFieldSpecs: DataFieldSpec[] = [];
  onOpenExamTimeEditor: (dp: PatientDataPoint) => void = () => {};

  build() {
    Column() {
      Column() {
        Text(getFieldValueLabel(this.timelineField, this.dataFieldSpecs) + ' 时间线')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.primary)
          .margin({ bottom: 12 })

        if (this.timelineData.length === 0) {
           Text($r('app.string.timeline_no_history'))
            .fontSize(13)
            .fontColor(AppColors.textSecondary)
        } else {
          ForEach(this.timelineData, (dp: PatientDataPoint) => {
            Column() {
              Row() {
                Text(dp.value + ' ' + getFieldUnit(this.timelineField, this.dataFieldSpecs))
                  .fontSize(14)
                  .fontColor(AppColors.primary)
                  .fontWeight(FontWeight.Bold)
                  .layoutWeight(1)
              }
              .width('100%')
              Row() {
                 Text($r('app.string.timeline_report'))
                  .fontSize(10)
                  .fontColor(AppColors.onPrimary)
                  .backgroundColor(dp.examTime > 0 ? AppColors.tierOk : AppColors.danger)
                  .borderRadius(3)
                  .padding({ left: 3, right: 3, top: 1, bottom: 1 })
                  .margin({ right: 4 })
                if (dp.examTime > 0) {
                  Text(formatDateTime(dp.examTime))
                    .fontSize(12)
                    .fontColor(AppColors.primary)
                    .layoutWeight(1)
                   Text($r('app.string.common_edit'))
                    .fontSize(10)
                    .fontColor(AppColors.tierOk)
                    .margin({ left: 4 })
                    .onClick(() => {
                      this.onOpenExamTimeEditor(dp);
                    })
                } else {
                   Text($r('app.string.timeline_unlink_exam'))
                    .fontSize(12)
                    .fontColor(AppColors.danger)
                    .layoutWeight(1)
                   Text($r('app.string.dialog_manual_submit'))
                    .fontSize(10)
.fontColor(AppColors.onPrimary)
                     .backgroundColor(AppColors.tierOk)
                    .borderRadius(3)
                    .padding({ left: 3, right: 3, top: 1, bottom: 1 })
                    .margin({ left: 4 })
                    .onClick(() => {
                      this.onOpenExamTimeEditor(dp);
                    })
                }
              }
              .width('100%')
              .margin({ top: 2 })
              Row() {
                 Text($r('app.string.timeline_upload'))
                  .fontSize(10)
                  .fontColor(AppColors.textSecondary)
                  .margin({ right: 4 })
                Text(formatDateTime(dp.timestamp))
                  .fontSize(11)
                  .fontColor(AppColors.textSecondary)
              }
              .width('100%')
              .margin({ top: 1 })
            }
            .width('100%')
            .padding({ top: 8, bottom: 8 })
            .borderRadius(6)
            .backgroundColor(AppColors.surfaceSubtle)
            .padding({ left: 8, right: 8, top: 8, bottom: 8 })
            .margin({ bottom: 6 })
          }, (dp: PatientDataPoint) => dp.id.toString())
        }

          Button($r('app.string.common_close'))
           .fontSize(14)
           .fontColor(AppColors.onPrimary)
           .backgroundColor(AppColors.primary)
          .borderRadius(8)
          .height(36)
          .width('100%')
          .margin({ top: 12 })
          .onClick(() => { this.showTimelineDialog = false; })
      }
      .padding(20)
      .backgroundColor(AppColors.card)
      .borderRadius(AppDimens.cardRadius)
      .width('85%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0,0,0,0.4)')
    .justifyContent(FlexAlign.Center)
  }
}

@Component
export struct ExamTimeEditorDialog {
  @Link editExamYear: number;
  @Link editExamMonth: number;
  @Link editExamDay: number;
  @Link editExamHour: number;
  @Link editExamMinute: number;
  @Link showExamTimeEditor: boolean;
  onSave: () => void = () => {};

  build() {
    Column() {
      Column() {
         Text($r('app.string.dialog_exam_time_title'))
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.primary)
          .margin({ bottom: 12 })

        DatePicker({
          selected: new Date(this.editExamYear, this.editExamMonth - 1, this.editExamDay)
        })
          .onChange((value: DatePickerResult) => {
            if (value.year !== undefined) this.editExamYear = value.year as number;
            if (value.month !== undefined) this.editExamMonth = (value.month as number) + 1;
            if (value.day !== undefined) this.editExamDay = value.day as number;
          })

        TimePicker({
          selected: new Date(2025, 0, 1, this.editExamHour, this.editExamMinute)
        })
          .onChange((value: TimePickerResult) => {
            if (value.hour !== undefined) this.editExamHour = value.hour as number;
            if (value.minute !== undefined) this.editExamMinute = value.minute as number;
          })
          .margin({ top: 8 })

        Row() {
           Button($r('app.string.common_cancel'))
            .fontSize(14)
            .fontColor(AppColors.textSecondary)
            .backgroundColor(AppColors.fillNeutral)
            .borderRadius(8)
            .height(36)
            .layoutWeight(1)
            .onClick(() => {
              this.showExamTimeEditor = false;
            })
           Button($r('app.string.common_save'))
             .fontSize(14)
             .fontColor(AppColors.onPrimary)
             .backgroundColor(AppColors.tierOk)
            .borderRadius(8)
            .height(36)
            .layoutWeight(1)
            .margin({ left: 8 })
            .onClick(() => {
              this.onSave();
            })
        }
        .width('100%')
        .margin({ top: 12 })
      }
      .padding(20)
      .backgroundColor(AppColors.card)
      .borderRadius(AppDimens.cardRadius)
      .width('85%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0,0,0,0.4)')
    .justifyContent(FlexAlign.Center)
  }
}

@Component
export struct ManualInputDialog {
  @Link showManualInput: boolean;
  @Link manualFieldKey: string;
  @Link manualFieldValue: string;
  @Link manualFilterKeyword: string;
  @Prop dataFieldSpecs: DataFieldSpec[] = [];
  @Prop currentPatientId: string = '';
  onManualInputSave: (fieldKey: string, fieldValue: string) => void = () => {};

  build() {
    Column() {
      Column() {
         Text($r('app.string.dialog_manual_input_title'))
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.primary)
          .margin({ bottom: 12 })

         TextInput({ placeholder: $r('app.string.dialog_manual_search_hint') })
          .height(40)
          .fontSize(14)
          .margin({ bottom: 8 })
          .onChange((value: string) => { this.manualFilterKeyword = value; })

        List({ space: 4 }) {
          ForEach(this.dataFieldSpecs, (spec: DataFieldSpec) => {
            if (spec.type === 'number') {
              if (this.manualFilterKeyword.length === 0 || spec.label.indexOf(this.manualFilterKeyword) >= 0 || spec.key.indexOf(this.manualFilterKeyword) >= 0) {
                ListItem() {
                  Row() {
                    Text(spec.label)
                      .fontSize(13)
                      .fontColor(AppColors.primary)
                      .layoutWeight(1)
                    if (spec.unit.length > 0) {
                      Text(spec.unit)
                        .fontSize(11)
                        .fontColor(AppColors.textSecondary)
                    }
                  }
                  .width('100%')
                  .padding(8)
                  .backgroundColor(this.manualFieldKey === spec.key ? AppColors.fillBeige : AppColors.surfaceSubtle)
                  .borderRadius(6)
                  .onClick(() => { this.manualFieldKey = spec.key; })
                }
              }
            }
          }, (spec: DataFieldSpec) => spec.key)
        }
        .height(200)
        .margin({ bottom: 8 })

         TextInput({ placeholder: $r('app.string.dialog_manual_value_hint') })
          .height(40)
          .fontSize(14)
          .type(InputType.NUMBER_DECIMAL)
          .margin({ bottom: 12 })
          .onChange((value: string) => { this.manualFieldValue = value; })

        Row() {
           Button($r('app.string.common_cancel'))
            .fontSize(14)
            .fontColor(AppColors.textSecondary)
            .backgroundColor(AppColors.fillNeutral)
            .borderRadius(8)
            .height(36)
            .layoutWeight(1)
            .onClick(() => {
              this.showManualInput = false;
              this.manualFieldKey = '';
              this.manualFieldValue = '';
            })
           Button($r('app.string.dialog_manual_submit'))
             .fontSize(14)
             .fontColor(AppColors.onPrimary)
             .backgroundColor(AppColors.primary)
            .borderRadius(8)
            .height(36)
            .layoutWeight(1)
            .margin({ left: 8 })
            .onClick(() => {
              if (this.manualFieldKey.length > 0 && this.manualFieldValue.length > 0) {
                this.onManualInputSave(this.manualFieldKey, this.manualFieldValue);
              }
            })
        }
        .width('100%')
      }
      .padding(20)
      .backgroundColor(AppColors.card)
      .borderRadius(AppDimens.cardRadius)
      .width('85%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0,0,0,0.4)')
    .justifyContent(FlexAlign.Center)
  }
}

@Component
export struct DeleteConfirmDialog {
  @Link showDeleteConfirm: boolean;
  @Link deleteRecordId: string;
  onDelete: (recordId: string) => void = () => {};

  build() {
    Column() {
      Column() {
         Text($r('app.string.dialog_delete_title'))
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.primary)
          .margin({ bottom: 8 })
         Text($r('app.string.dialog_delete_record_msg'))
          .fontSize(13)
          .fontColor(AppColors.textBody)
          .lineHeight(20)
          .margin({ bottom: 16 })
        Row() {
           Button($r('app.string.common_cancel'))
            .fontSize(14)
            .fontColor(AppColors.textSecondary)
            .backgroundColor(AppColors.fillNeutral)
            .borderRadius(8)
            .height(36)
            .layoutWeight(1)
            .onClick(() => {
              this.showDeleteConfirm = false;
              this.deleteRecordId = '';
            })
           Button($r('app.string.common_delete'))
              .fontSize(14)
              .fontColor(AppColors.onPrimary)
              .backgroundColor(AppColors.danger)
            .borderRadius(8)
            .height(36)
            .layoutWeight(1)
            .margin({ left: 8 })
            .onClick(() => {
              if (this.deleteRecordId.length > 0) {
                this.onDelete(this.deleteRecordId);
              }
            })
        }
        .width('100%')
      }
      .padding(20)
      .backgroundColor(AppColors.card)
      .borderRadius(AppDimens.cardRadius)
      .width('85%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0,0,0,0.4)')
    .justifyContent(FlexAlign.Center)
  }
}

@Component
export struct AddDiagnosisDialog {
  @Link showAddDiagnosis: boolean;
  @Link addDiagName: string;
  @Link addDiagCategory: string;
  @Prop currentPatientId: string = '';
  onAddDiagnosis: (name: string, category: string) => void = () => {};

  build() {
    Column() {
      Column() {
         Text($r('app.string.dialog_add_diagnosis_title'))
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.primary)
          .margin({ bottom: 16 })

         TextInput({ placeholder: $r('app.string.dialog_add_diag_ph_name'), text: this.addDiagName })
          .fontSize(14)
          .width('100%')
          .onChange((value: string) => {
            this.addDiagName = value;
          })

         Text($r('app.string.dialog_add_diag_category'))
          .fontSize(13)
          .fontColor(AppColors.textBody)
          .margin({ top: 12, bottom: 6 })

        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          ForEach(DIAGNOSIS_CATEGORIES, (cat: string) => {
            Text(cat)
              .fontSize(12)
              .fontColor(this.addDiagCategory === cat ? AppColors.card : AppColors.primary)
              .backgroundColor(this.addDiagCategory === cat ? AppColors.primary : AppColors.fillBeige)
              .borderRadius(4)
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .margin({ right: 4, bottom: 4 })
              .onClick(() => {
                this.addDiagCategory = cat;
              })
          }, (cat: string) => cat)
        }

        Row() {
           Text($r('app.string.common_cancel'))
            .fontSize(14)
            .fontColor(AppColors.textSecondary)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .padding(10)
            .onClick(() => {
              this.showAddDiagnosis = false;
            })
            Text($r('app.string.common_add'))
             .fontSize(14)
             .fontColor(AppColors.onPrimary)
             .backgroundColor(AppColors.primary)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .padding(10)
            .borderRadius(6)
            .onClick(() => {
              if (this.addDiagName.trim().length > 0) {
                this.onAddDiagnosis(this.addDiagName.trim(), this.addDiagCategory);
              }
            })
        }
        .width('100%')
        .margin({ top: 20 })
      }
      .padding(20)
      .backgroundColor(AppColors.card)
      .borderRadius(AppDimens.cardRadius)
      .width('85%')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('rgba(0,0,0,0.4)')
    .onClick(() => {
      this.showAddDiagnosis = false;
    })
  }
}
