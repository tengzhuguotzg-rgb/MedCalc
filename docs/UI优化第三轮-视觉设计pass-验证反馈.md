# UI 优化第三轮 · 视觉设计 Pass — 技术验证反馈

> 验证时间：2026-07-25
> 验证对象：`docs/UI优化建议-第三轮-视觉设计pass.md` 中的两个技术风险点
> 验证结论：**两个风险均已消除，施工单整体可行**

---

## 一、SVG fillColor 动态着色 — ✅ 可行，需加资源规范

### 验证结论

ArkUI `Image($r('app.media.xxx')).fillColor($r('app.color.xxx'))` **支持 SVG 动态着色**，深浅色模式用同一 SVG + 不同 fillColor 即可，无需为暗色单独出图。

### 前提约束（必须遵守）

| 规则 | 原因 |
|------|------|
| SVG 必须用 **fill 绘制**，禁止 stroke | fillColor 只作用于 fill 区域，对 stroke 无效 |
| SVG 内禁止 `currentColor` | currentColor 是 CSS 变量，无法被 fillColor 覆盖 |
| SVG 默认色设 `fill="#000000"` | 黑底便于 fillColor 完全覆盖上色 |
| 容器必须 `.backgroundColor(Color.Transparent)` | 避免灰色底渗出（Button 等组件有默认灰色背景） |
| 避免 `<style>` 内联样式 | 可能干扰 fillColor 着色 |
| 避免 opacity / filter 属性 | 可能影响颜色渲染 |

### 建议新增纪律（补入施工单红线）

```
V1-SVG-01: 所有 SVG 资源必须走 fill 路径，无 stroke，无 currentColor，无 <style> 内联
V1-SVG-02: SVG sourcing 完成后，用脚本批量检查：
           grep -r 'stroke=' resources/base/media/ic_*.svg  → 必须 0 匹配
           grep -r 'currentColor' resources/base/media/ic_*.svg → 必须 0 匹配
V1-SVG-03: 图标组件封装为 IconButton（Row + Image + fillColor + Transparent 背景），
           Tab/顶栏/Sidebar 统一用该组件，不直接写 Image
```

### 推荐的 IconButton 封装

```typescript
@Component
export struct IconButton {
  iconResource: Resource = $r('app.media.ic_placeholder');
  iconColor: ResourceColor = AppColors.textSecondary;
  iconSize: number = 22;
  btnSize: number = AppDimens.touchTarget;
  onClick?: () => void;

  build() {
    Row() {
      Image(this.iconResource)
        .width(this.iconSize)
        .height(this.iconSize)
        .fillColor(this.iconColor)
        .objectFit(ImageFit.Contain)
    }
    .width(this.btnSize)
    .height(this.btnSize)
    .backgroundColor(Color.Transparent)
    .justifyContent(FlexAlign.Center)
    .onClick(() => this.onClick?.())
  }
}
```

---

## 二、fontFeature tabular-nums — ✅ 原生支持，无需 fallback

### 验证结论

ArkUI `Text` 组件原生支持 `fontFeature` 属性，官方 API 文档明确列出，用途示例就是"数字等宽特性"。

### 用法

```typescript
Text(this.mainText())
  .fontFeature('tnum')    // tabular-nums，等宽数字
  .fontSize(40)
  .fontWeight(FontWeight.Bold)
```

### 对 V2 ResultCard Hero 化的影响

- 施工单中"若 ArkTS fontFeature 不支持则用等宽字体族"的 fallback 方案**不需要**
- 直接用 `fontFeature('tnum')` 即可，等宽效果由系统字体提供，无需额外字体资源

---

## 三、V6 微动效 — 动画中断策略需补充

### 问题

施工单验收条目提了"快速连续输入时结果动画不鬼畜（动画被打断应直接到终态）"，但**没有给出缓解方案**。

### 推荐方案

**方案 A（推荐）：用 `animation()` 属性动画代替 `animateTo`**

属性动画天然支持中断——新值到来时自动从当前状态跳到新终态，不会鬼畜：

```typescript
@Component
export struct ResultCard {
  @Prop displayValue: string = '';
  @Prop tierClass: string = '';

  // 用 @State 驱动属性动画
  @State private resultOpacity: number = 0;
  @State private resultTranslateY: number = 4;

  aboutToAppear() {
    this.resultOpacity = 1;
    this.resultTranslateY = 0;
  }

  build() {
    Text(this.displayValue)
      .opacity(this.resultOpacity)
      .translate({ y: this.resultTranslateY })
      .animation({
        duration: 200,
        curve: Curve.EaseOut
      })
  }
}
```

**方案 B：`animateTo` + `onFinish` 标记**

如果必须用 `animateTo`，需加防重入锁：

```typescript
private animating: boolean = false;

updateResult() {
  if (this.animating) {
    // 跳终态，不播动画
    this.displayValue = newValue;
    return;
  }
  this.animating = true;
  animateTo({ duration: 200, onFinish: () => { this.animating = false; } }, () => {
    this.displayValue = newValue;
  });
}
```

### 建议新增纪律

```
V6-ANIM-01: ResultCard 结果出现动画用 animation() 属性动画，不用 animateTo
V6-ANIM-02: OptionChip 选中过渡用 animation({ duration: 150 })，不用 animateTo
V6-ANIM-03: 禁止对命令式方法（scrollTo 等）使用 animateTo 包裹
```

---

## 四、其余项快速复核

| 项 | 判断 | 备注 |
|---|---|---|
| V3 letterSpacing | ✅ 合理 | 建议先 `rg letterSpacing *.ets` 出完整清单再逐处标红/绿，不要边改边找 |
| V4 SectionTitle 38 文件替换 | ⚠️ 回归面最大 | 建议写替换脚本（sed/AST）+ diff 确认 + 批量 arkts_check，不手动逐文件改 |
| V5 卡片描边 | ✅ 低成本 | 和病历页已修方案一致，1 行代码 |
| V7 暗色精调 | ✅ 必做 | 放最后是对的 |

---

## 五、建议对施工单的修订

1. **红线新增** V1-SVG-01/02/03 三条 SVG 资源规范
2. **红线新增** V6-ANIM-01/02/03 三条动画纪律
3. **V2 删除** fontFeature fallback 描述（"若 ArkTS fontFeature 不支持则用等宽字体族"），直接用 `fontFeature('tnum')`
4. **V4 新增** 纪律：写替换脚本 + diff 确认 + 批量 arkts_check，不手动逐文件改
5. **V3 新增** 工序：先 grep 出 letterSpacing 完整清单，标注中文/西文/混排分类，再逐处处理

---

## 六、结论

**施工单整体可行，两个技术风险（SVG fillColor / fontFeature）已验证通过。** 建议按原施工顺序开工，开工前将上述修订合入施工单即可。
