import TestRunner from '../test/TestRunner';

@Entry
@Component
struct TestPage {
  aboutToAppear() {
    TestRunner.run();
  }

  build() {
    Column() {
      Text('MedCalc Engine Tests')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 100 })
      Text('Tests are running. Check hilog for results.')
        .fontSize(14)
        .margin({ top: 20 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
  }
}
