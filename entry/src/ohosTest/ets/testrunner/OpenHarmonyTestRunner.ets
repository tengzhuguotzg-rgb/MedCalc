import TestRunner from '@ohos.application.testRunner';
import { abilityDelegatorRegistry } from '@kit.TestKit';
import { Hypium } from '@ohos/hypium';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Want } from '@kit.AbilityKit';
import testsuite from '../test/List.test';

let abilityDelegator: abilityDelegatorRegistry.AbilityDelegator | undefined = undefined;
let abilityDelegatorArguments: abilityDelegatorRegistry.AbilityDelegatorArgs | undefined = undefined;

function onAbilityCreateCallback(): void {
  hilog.info(0x0000, 'testTag', 'onAbilityCreateCallback');
}

function addAbilityMonitorCallback(err: Error): void {
  hilog.info(0x0000, 'testTag', 'addAbilityMonitorCallback: %{public}s', JSON.stringify(err));
}

export default class OpenHarmonyTestRunner implements TestRunner {
  constructor() {
  }

  onPrepare(): void {
    hilog.info(0x0000, 'testTag', 'OpenHarmonyTestRunner OnPrepare');
  }

  async onRun(): Promise<void> {
    hilog.info(0x0000, 'testTag', 'OpenHarmonyTestRunner onRun');
    abilityDelegator = abilityDelegatorRegistry.getAbilityDelegator();
    abilityDelegatorArguments = abilityDelegatorRegistry.getArguments();
    const lMonitor: abilityDelegatorRegistry.AbilityMonitor = {
      abilityName: 'TestAbility',
      onAbilityCreate: onAbilityCreateCallback,
    };
    abilityDelegator.addAbilityMonitor(lMonitor, addAbilityMonitorCallback);
    const want: Want = {
      bundleName: abilityDelegatorArguments.bundleName,
      abilityName: 'TestAbility'
    };
    abilityDelegator.startAbility(want, (err: Error) => {
      hilog.info(0x0000, 'testTag', 'startAbility: %{public}s', JSON.stringify(err));
    });
    Hypium.hypiumTest(abilityDelegator, abilityDelegatorArguments, testsuite);
    hilog.info(0x0000, 'testTag', 'OpenHarmonyTestRunner hypiumTest started');
  }
}
