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
          Text('无历史记录')
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
                Text('报告')
                  .fontSize(10)
                  .fontColor(AppColors.card)
                  .backgroundColor(dp.examTime > 0 ? AppColors.tierOk : AppColors.danger)
                  .borderRadius(3)
                  .padding({ left: 3, right: 3, top: 1, bottom: 1 })
                  .margin({ right: 4 })
                if (dp.examTime > 0) {
                  Text(formatDateTime(dp.examTime))
                    .fontSize(12)
                    .fontColor(AppColors.primary)
                    .layoutWeight(1)
                  Text('修改')
                    .fontSize(10)
                    .fontColor(AppColors.tierOk)
                    .margin({ left: 4 })
                    .onClick(() => {
                      this.onOpenExamTimeEditor(dp);
                    })
                } else {
                  Text('未设置')
                    .fontSize(12)
                    .fontColor(AppColors.danger)
                    .layoutWeight(1)
                  Text('录入')
                    .fontSize(10)
                    .fontColor(AppColors.card)
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
                Text('上传')
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

        Button('关闭')
          .fontSize(14)
          .fontColor(AppColors.card)
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
        Text('设置报告时间')
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
          Button('取消')
            .fontSize(14)
            .fontColor(AppColors.textSecondary)
            .backgroundColor(AppColors.fillNeutral)
            .borderRadius(8)
            .height(36)
            .layoutWeight(1)
            .onClick(() => {
              this.showExamTimeEditor = false;
            })
          Button('保存')
            .fontSize(14)
            .fontColor(AppColors.card)
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
        Text('手动录入')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.primary)
          .margin({ bottom: 12 })

        TextInput({ placeholder: '搜索字段名...' })
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
                    Text(spec.key)
                      .fontSize(11)
                      .fontColor(AppColors.textSecondary)
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

        TextInput({ placeholder: '输入数值' })
          .height(40)
          .fontSize(14)
          .type(InputType.NUMBER_DECIMAL)
          .margin({ bottom: 12 })
          .onChange((value: string) => { this.manualFieldValue = value; })

        Row() {
          Button('取消')
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
          Button('录入')
            .fontSize(14)
            .fontColor(AppColors.card)
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
        Text('确认删除')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.primary)
          .margin({ bottom: 8 })
        Text('删除此记录后，由它提供的数据将被一并删除，预警也将重新计算。')
          .fontSize(13)
          .fontColor(AppColors.textBody)
          .lineHeight(20)
          .margin({ bottom: 16 })
        Row() {
          Button('取消')
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
          Button('删除')
            .fontSize(14)
            .fontColor(AppColors.card)
            .backgroundColor(AppColors.warning)
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
        Text('添加诊断')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.primary)
          .margin({ bottom: 16 })

        TextInput({ placeholder: '诊断名称', text: this.addDiagName })
          .fontSize(14)
          .width('100%')
          .onChange((value: string) => {
            this.addDiagName = value;
          })

        Text('分类')
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
          Text('取消')
            .fontSize(14)
            .fontColor(AppColors.textSecondary)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .padding(10)
            .onClick(() => {
              this.showAddDiagnosis = false;
            })
          Text('添加')
            .fontSize(14)
            .fontColor(AppColors.card)
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
