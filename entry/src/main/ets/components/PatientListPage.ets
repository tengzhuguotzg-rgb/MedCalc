import { Patient } from '../model/Patient';
import { PatientService } from '../services/PatientService';

@Component
export struct PatientListPage {
  @Link currentPatientId: string;
  @State patients: Patient[] = [];
  @State searchKeyword: string = '';
  @State alertCounts: Map<string, number> = new Map();
  @State showCreateDialog: boolean = false;
  @State newName: string = '';
  @State newBedNo: string = '';
  @State newAge: string = '';
  @State newSex: string = 'male';
  @State deletePatientId: string = '';
  @State showDeleteConfirm: boolean = false;

  private patientService: PatientService = PatientService.getInstance();

  aboutToAppear() {
    this.refresh();
  }

  async refresh() {
    this.patients = await this.patientService.getPatients(this.searchKeyword);
    this.alertCounts = await this.patientService.getAlertCounts();
  }

  getAlertCount(patientId: string): number {
    const val = this.alertCounts.get(patientId);
    return val !== undefined ? val : 0;
  }

  formatTime(ts: number): string {
    const diff = Date.now() - ts;
    if (diff < 60000) {
      return '刚刚';
    }
    if (diff < 3600000) {
      return Math.floor(diff / 60000) + '分钟前';
    }
    if (diff < 86400000) {
      return Math.floor(diff / 3600000) + '小时前';
    }
    return Math.floor(diff / 86400000) + '天前';
  }

  build() {
    Column() {
      Row() {
        Text('病历管理')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F3D2F')
          .layoutWeight(1)
        Button('+ 新建')
          .fontSize(12)
          .fontColor('#FFFFFF')
          .backgroundColor('#1F3D2F')
          .borderRadius(8)
          .height(32)
          .padding({ left: 12, right: 12 })
          .onClick(() => {
            this.showCreateDialog = true;
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      TextInput({ placeholder: '搜索姓名/床号...' })
        .height(48)
        .fontSize(14)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .margin({ left: 16, right: 16, bottom: 12 })
        .onChange((value: string) => {
          this.searchKeyword = value;
          this.refresh();
        })

      if (this.patients.length === 0) {
        Column() {
          Text('还没有患者记录')
            .fontSize(16)
            .fontColor('#5F6654')
            .margin({ bottom: 8 })
          Text('点击右上角新建患者开始')
            .fontSize(13)
            .fontColor('#5F6654')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        List({ space: 8 }) {
          ForEach(this.patients, (patient: Patient) => {
            ListItem() {
              Row() {
                Column() {
                  Row() {
                    Text(patient.name)
                      .fontSize(16)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#1F3D2F')
                      .margin({ right: 8 })
                    if (patient.bedNo.length > 0) {
                      Text(patient.bedNo + '床')
                        .fontSize(12)
                        .fontColor('#5F6654')
                        .backgroundColor('#E8E5D8')
                        .borderRadius(4)
                        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    }
                  }
                  .margin({ bottom: 4 })
                  Text(this.formatTime(patient.updatedAt))
                    .fontSize(12)
                    .fontColor('#5F6654')
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Column() {
                  if (this.getAlertCount(patient.id) > 0) {
                    Text(this.getAlertCount(patient.id) + '条预警')
                      .fontSize(12)
                      .fontColor('#E76F2C')
                      .fontWeight(FontWeight.Bold)
                  } else {
                    Text('暂无预警')
                      .fontSize(12)
                      .fontColor('#3D6B4F')
                  }
                  Text('删除')
                    .fontSize(12)
                    .fontColor('#B1452A')
                    .padding({ left: 14, right: 14, top: 14, bottom: 14 })
                    .margin({ top: 4 })
                    .onClick(() => {
                      this.deletePatientId = patient.id;
                      this.showDeleteConfirm = true;
                    })
                }
                .alignItems(HorizontalAlign.End)
              }
              .width('100%')
              .padding(12)
              .backgroundColor('#FFFFFF')
              .borderRadius(10)
              .onClick(() => {
                this.currentPatientId = patient.id;
              })
            }
          }, (patient: Patient) => patient.id)
        }
        .layoutWeight(1)
        .padding({ left: 16, right: 16 })
      }

      if (this.showCreateDialog) {
        this.CreateDialog();
      }
      if (this.showDeleteConfirm) {
        this.DeleteConfirmDialog();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F4EF')
  }

  @Builder
  CreateDialog() {
    Column() {
      Column() {
        Text('新建患者')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F3D2F')
          .margin({ bottom: 16 })

        TextInput({ placeholder: '姓名*' })
          .height(48)
          .fontSize(14)
          .margin({ bottom: 8 })
          .onChange((value: string) => { this.newName = value; })

        TextInput({ placeholder: '床号' })
          .height(48)
          .fontSize(14)
          .margin({ bottom: 8 })
          .onChange((value: string) => { this.newBedNo = value; })

        TextInput({ placeholder: '年龄' })
          .height(48)
          .fontSize(14)
          .type(InputType.Number)
          .margin({ bottom: 8 })
          .onChange((value: string) => { this.newAge = value; })

        Row() {
          Text('性别')
            .fontSize(14)
            .fontColor('#1F2421')
            .layoutWeight(1)
          Button('男')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.newSex === 'male' ? '#FFFFFF' : '#2D5440')
            .backgroundColor(this.newSex === 'male' ? '#1F3D2F' : '#F5F5F5')
            .border({ width: 1, color: this.newSex === 'male' ? '#1F3D2F' : '#E0E0E0' })
            .borderRadius(8)
            .height(44)
            .layoutWeight(1)
            .onClick(() => { this.newSex = 'male'; })
          Button('女')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.newSex === 'female' ? '#FFFFFF' : '#2D5440')
            .backgroundColor(this.newSex === 'female' ? '#1F3D2F' : '#F5F5F5')
            .border({ width: 1, color: this.newSex === 'female' ? '#1F3D2F' : '#E0E0E0' })
            .borderRadius(8)
            .height(44)
            .layoutWeight(1)
            .margin({ left: 6 })
            .onClick(() => { this.newSex = 'female'; })
        }
        .width('100%')
        .margin({ bottom: 16 })

        Row() {
          Button('取消')
            .fontSize(14)
            .fontColor('#5F6654')
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .height(48)
            .layoutWeight(1)
            .onClick(() => {
              this.showCreateDialog = false;
              this.newName = '';
              this.newBedNo = '';
              this.newAge = '';
              this.newSex = 'male';
            })
          Button('创建')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor('#1F3D2F')
            .borderRadius(8)
            .height(48)
            .layoutWeight(1)
            .margin({ left: 12 })
            .onClick(async () => {
              if (this.newName.length > 0) {
                await this.patientService.createPatient(
                  this.newName,
                  this.newBedNo,
                  parseFloat(this.newAge) || 0,
                  this.newSex
                );
                this.showCreateDialog = false;
                this.newName = '';
                this.newBedNo = '';
                this.newAge = '';
                this.newSex = 'male';
                this.refresh();
              }
            })
        }
        .width('100%')
      }
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .width('85%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0,0,0,0.4)')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  DeleteConfirmDialog() {
    Column() {
      Column() {
        Text('确认删除患者')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F3D2F')
          .margin({ bottom: 8 })
        Text('删除后该患者的所有数据、上传记录和预警将被永久清除，无法恢复。')
          .fontSize(13)
          .fontColor('#4A5247')
          .lineHeight(20)
          .margin({ bottom: 16 })
        Row() {
          Button('取消')
            .fontSize(14)
            .fontColor('#5F6654')
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .height(36)
            .layoutWeight(1)
            .onClick(() => {
              this.showDeleteConfirm = false;
              this.deletePatientId = '';
            })
          Button('删除')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor('#E76F2C')
            .borderRadius(8)
            .height(36)
            .layoutWeight(1)
            .margin({ left: 8 })
            .onClick(async () => {
              if (this.deletePatientId.length > 0) {
                await this.patientService.deletePatient(this.deletePatientId);
                this.showDeleteConfirm = false;
                this.deletePatientId = '';
                this.refresh();
              }
            })
        }
        .width('100%')
      }
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .width('85%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0,0,0,0.4)')
    .justifyContent(FlexAlign.Center)
  }
}
