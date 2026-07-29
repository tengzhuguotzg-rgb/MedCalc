import hilog from '@ohos.hilog';
import TestRunner from '../test/TestRunner';

export default class TestAbility {
  onCreate(want: object, launchParam: object) {
    hilog.info(0x0000, 'testTag', '%{public}s', 'TestAbility onCreate');
  }
  onDestroy() {
    hilog.info(0x0000, 'testTag', '%{public}s', 'TestAbility onDestroy');
  }
  onWindowStageCreate(windowStage: object) {
    hilog.info(0x0000, 'testTag', '%{public}s', 'TestAbility onWindowStageCreate');
    const stage = windowStage as Record<string, Function>;
    stage.loadContent('pages/TestPage', (err: Error, data: object) => {
      if (err.message) {
        hilog.error(0x0000, 'testTag', 'Failed to load content. %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(0x0000, 'testTag', 'Loaded content. %{public}s', JSON.stringify(data));
    });
  }
  onWindowStageDestroy() {
    hilog.info(0x0000, 'testTag', '%{public}s', 'TestAbility onWindowStageDestroy');
  }
  onForeground() {
    hilog.info(0x0000, 'testTag', '%{public}s', 'TestAbility onForeground');
  }
  onBackground() {
    hilog.info(0x0000, 'testTag', '%{public}s', 'TestAbility onBackground');
  }
}
