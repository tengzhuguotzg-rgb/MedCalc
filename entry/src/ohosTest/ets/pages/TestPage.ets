@Entry
@Component
struct TestPage {
  build() {
    Column() {
      Text('MedCalc Engine Tests')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 100 })
      Text('Run via: aa test -s unittest OpenHarmonyTestRunner')
        .fontSize(14)
        .margin({ top: 20 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
  }
}
