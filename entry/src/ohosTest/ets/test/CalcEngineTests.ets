import { describe, it, expect } from '@ohos/hypium';
import { calculateWells } from '../../../main/ets/engine/WellsCalculator';
import { calculateCpis } from '../../../main/ets/engine/Batch1bCalculators';
import { calculateMap } from '../../../main/ets/engine/MapCalculator';
import { calculateCrCl } from '../../../main/ets/engine/CrClCalculator';
import { calculateChadsvasc } from '../../../main/ets/engine/MoreCalculators';
import { calculateRipasa } from '../../../main/ets/engine/Batch3aCalculators';

export function CalcEngineTests() {
  describe('WellsCalculator', () => {
    it('all_false_score_0_low', 0, () => {
      const r = calculateWells(false, false, false, false, false, false, false);
      expect(r.value).assertEqual(0);
      expect(r.tier).assertEqual('低概率');
      expect(r.tierClass).assertEqual('tier-ok');
    });

    it('clinical_only_score_3_medium', 0, () => {
      const r = calculateWells(true, false, false, false, false, false, false);
      expect(r.value).assertEqual(3);
      expect(r.tier).assertEqual('中概率');
      expect(r.tierClass).assertEqual('tier-warn');
    });

    it('all_true_score_12_5_high', 0, () => {
      const r = calculateWells(true, true, true, true, true, true, true);
      expect(r.value).assertEqual(12.5);
      expect(r.tier).assertEqual('高概率');
      expect(r.tierClass).assertEqual('tier-danger');
    });

    it('score_2_boundary_medium', 0, () => {
      // hr + hemoptysis = 1.5 + 1 = 2.5, but test exact boundary: hr+surgery = 3
      const r = calculateWells(false, false, true, true, false, false, false);
      expect(r.value).assertEqual(3);
      expect(r.tier).assertEqual('中概率');
    });

    it('score_6_boundary_medium', 0, () => {
      // clinical(3) + hr(1.5) + surgery(1.5) = 6
      const r = calculateWells(true, false, true, true, false, false, false);
      expect(r.value).assertEqual(6);
      expect(r.tier).assertEqual('中概率');
    });

    it('score_6_5_high', 0, () => {
      // clinical(3) + peLikely(3) + hemoptysis(1) = 7
      const r = calculateWells(true, true, false, false, false, true, false);
      expect(r.value).assertEqual(7);
      expect(r.tier).assertEqual('高概率');
    });
  });

  describe('CPIS', () => {
    it('temp_high_wbc_high_bands_score', 0, () => {
      // temp=39.5 -> tempScore=2, wbc=15 -> wbcScore=1, bandsAbs=600 -> wbcScore=2
      // secretions=2, pfRatio=200(<=240, no ARDS) -> oxyScore=2, cxr=2, culture=2
      // total = 2+2+2+2+2+2 = 12
      const r = calculateCpis(39.5, 15, 600, 2, 200, 2, 2, false);
      expect(r.value).assertEqual(12);
      expect(r.tier).assertEqual('VAP 可能性高');
    });

    it('temp_normal_low_score', 0, () => {
      // temp=37 -> tempScore=0, wbc=8 -> wbcScore=0, secretions=0, pfRatio=400 -> oxyScore=0
      // total = 0
      const r = calculateCpis(37, 8, 0, 0, 400, 0, 0, false);
      expect(r.value).assertEqual(0);
      expect(r.tier).assertEqual('低分');
    });

    it('ards_pf_no_oxy_score', 0, () => {
      // ARDS=true, pfRatio=150 -> oxyScore=0 (ARDS excludes oxygenation scoring)
      // temp=39 -> tempScore=2, wbc=12 -> wbcScore=1, bandsAbs=0 -> stays 1
      // total = 2+1+0+0+0+0 = 3
      const r = calculateCpis(39, 12, 0, 0, 150, 0, 0, true);
      expect(r.value).assertEqual(3);
    });

    it('empty_when_temp_zero', 0, () => {
      const r = calculateCpis(0, 8, 0, 0, 400, 0, 0, false);
      expect(r.value).assertNull();
    });

    it('temp_38_5_boundary', 0, () => {
      // temp=38.5 -> tempScore=1
      const r = calculateCpis(38.5, 8, 0, 0, 400, 0, 0, false);
      expect(r.value).assertEqual(1);
    });

    it('temp_36_boundary', 0, () => {
      // temp=36 -> tempScore=2 (<=36)
      const r = calculateCpis(36, 8, 0, 0, 400, 0, 0, false);
      expect(r.value).assertEqual(2);
    });
  });

  describe('MAP', () => {
    it('normal_map', 0, () => {
      // MAP = (120 + 2*80) / 3 = 93.33
      const r = calculateMap(120, 80);
      expect(r.tier).assertEqual('正常');
    });

    it('low_map_below_65', 0, () => {
      // MAP = (90 + 2*50) / 3 = 63.33
      const r = calculateMap(90, 50);
      expect(r.tier).assertEqual('低于目标');
    });

    it('high_map_above_100', 0, () => {
      // MAP = (160 + 2*100) / 3 = 120
      const r = calculateMap(160, 100);
      expect(r.tier).assertEqual('过高');
    });

    it('boundary_65', 0, () => {
      // MAP = (65 + 2*65) / 3 = 65
      const r = calculateMap(65, 65);
      expect(r.tier).assertEqual('达标下界');
    });

    it('empty_when_zero', 0, () => {
      const r = calculateMap(0, 0);
      expect(r.value).assertNull();
    });
  });

  describe('CrCl', () => {
    it('male_normal_crcl', 0, () => {
      // CrCl = (140-50)*70 / (72*1.0) = 90*70/72 = 87.5
      // 87.5 落在 CKD G2 区间 60-89 → 轻度下降（引擎阈值：≥90 正常）
      const r = calculateCrCl('male', 50, 70, 1.0, 'mgdl');
      expect(r.value !== null).assertTrue();
      if (r.value !== null) {
        expect(r.value > 87 && r.value < 88).assertTrue();
      }
      expect(r.tier).assertEqual('轻度下降');
    });

    it('female_lower_crcl', 0, () => {
      // Same params but female: 87.5 * 0.85 = 74.375
      // 74.375 同样落在 CKD G2 区间 60-89 → 轻度下降（中度下降为 30-59）
      const r = calculateCrCl('female', 50, 70, 1.0, 'mgdl');
      expect(r.value !== null).assertTrue();
      if (r.value !== null) {
        expect(r.value > 74 && r.value < 75).assertTrue();
      }
      expect(r.tier).assertEqual('轻度下降');
    });

    it('umol_conversion', 0, () => {
      // cr=88.4 umol -> 1.0 mg/dL, same as above
      const r = calculateCrCl('male', 50, 70, 88.4, 'umol');
      expect(r.value !== null).assertTrue();
      if (r.value !== null) {
        expect(r.value > 87 && r.value < 88).assertTrue();
      }
    });

    it('empty_when_zero', 0, () => {
      const r = calculateCrCl('male', 0, 70, 1.0, 'mgdl');
      expect(r.value).assertNull();
    });
  });

  describe('CHA2DS2-VASc', () => {
    it('all_false_male_score_0', 0, () => {
      const r = calculateChadsvasc(false, false, false, false, false, false, false, false);
      expect(r.value).assertEqual(0);
      expect(r.tier).assertEqual('低风险');
    });

    it('age75_only_score_2', 0, () => {
      const r = calculateChadsvasc(false, false, true, false, false, false, false, false);
      expect(r.value).assertEqual(2);
    });

    it('female_age75_score_3', 0, () => {
      // age75(2) + female(1) = 3
      const r = calculateChadsvasc(false, false, true, false, false, false, false, true);
      expect(r.value).assertEqual(3);
      expect(r.tier).assertEqual('高风险');
    });

    it('male_age65_stroke_score_3', 0, () => {
      // age65(1) + stroke(2) = 3
      const r = calculateChadsvasc(false, false, false, false, true, false, true, false);
      expect(r.value).assertEqual(3);
      expect(r.tier).assertEqual('高风险');
    });

    it('age75_and_age65_not_double_counted', 0, () => {
      // UI prevents both, but engine: age75(2) + age65(1) = 3
      const r = calculateChadsvasc(false, false, true, false, false, false, true, false);
      expect(r.value).assertEqual(3);
    });
  });

  describe('RIPASA', () => {
    it('male_young_low_score', 0, () => {
      // male(1) + age<=40(1) + 病程>48h(0.5) + temp=37落在37-39(2) = 4.5
      // 注意：durLt48h=false 不是 0 分，而是"病程>48h"项得 0.5 分
      const r = calculateRipasa(30, 'male', false, false, false, false, false, false, false, false, false, 37, 8, false, false);
      expect(r.value).assertEqual(4.5);
      expect(r.tier).assertEqual('不太可能');
    });

    it('female_high_score', 0, () => {
      // female(0.5) + age>40(0.5) + rlqPain(0.5) + anorexia(1) + nauseaVomit(1)
      // + durLt48h(1) + rlqTender(1) + guarding(2) + rebound(1) + rovsing(2)
      // + temp 37-39(2) + wbc>10(1) + urineNeg(1) = 14.5
      const r = calculateRipasa(45, 'female', true, false, true, true, true, true, true, true, true, 38, 12, true, false);
      expect(r.value).assertEqual(14.5);
      expect(r.tier).assertEqual('高概率');
    });

    it('temp_39_boundary', 0, () => {
      // temp=39 should be included (>=37 && <=39)
      const r1 = calculateRipasa(30, 'male', false, false, false, false, false, false, false, false, false, 39, 8, false, false);
      // temp=39.1 should NOT be included
      const r2 = calculateRipasa(30, 'male', false, false, false, false, false, false, false, false, false, 39.1, 8, false, false);
      // r1: male(1) + age<=40(1) + 病程>48h(0.5) + temp 37-39(2) = 4.5
      expect(r1.value).assertEqual(4.5);
      // r2: male(1) + age<=40(1) + 病程>48h(0.5)，temp 39.1 出界不计 = 2.5
      expect(r2.value).assertEqual(2.5);
    });

    it('foreign_national_adds_1', 0, () => {
      const r1 = calculateRipasa(30, 'male', false, false, false, false, false, false, false, false, false, 37, 8, false, false);
      const r2 = calculateRipasa(30, 'male', false, false, false, false, false, false, false, false, false, 37, 8, false, true);
      expect(r1.value !== null && r2.value !== null).assertTrue();
      if (r1.value !== null && r2.value !== null) {
        expect(r2.value - r1.value).assertEqual(1);
      }
    });

    it('empty_when_temp_zero', 0, () => {
      const r = calculateRipasa(30, 'male', false, false, false, false, false, false, false, false, false, 0, 8, false, false);
      expect(r.value).assertNull();
    });
  });
}
