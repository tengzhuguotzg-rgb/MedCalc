import { Hypium } from '@ohos/hypium';
import { abilityDelegatorRegistry } from '@kit.TestKit';
import { CalcEngineTests } from './CalcEngineTests';

export default class TestRunner {
  static run() {
    const abilityDelegator: abilityDelegatorRegistry.AbilityDelegator =
      abilityDelegatorRegistry.getAbilityDelegator();
    const abilityDelegatorArguments: abilityDelegatorRegistry.AbilityDelegatorArgs =
      abilityDelegatorRegistry.getArguments();

    Hypium.hypiumTest(abilityDelegator, abilityDelegatorArguments, () => {
      CalcEngineTests();
    });
  }
}
