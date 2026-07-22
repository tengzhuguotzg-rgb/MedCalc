# H5 知识库 TOC 点击跳转 — 未解决

## 问题
KnowledgeSearchPage TOC 目录点击只关面板不滚动定位，是假功能。

## 目标
点击 TOC 条目后，Scroll 滚动到对应标题位置。

## 已尝试方案及失败原因

### 1. Scroll+Column 内给标题元素加 `.id()` + `componentUtils.getRectangleById` + `scrollTo`
- **结果**：在 `@Builder MarkdownLineView` 的 if-else 链中给 h1/h2/h3 元素追加 `.id()`，触发 ArkTS 编译器级联报错 100+ 条
- **原因**：ArkTS 严格模式下，条件渲染分支内的组件加 `.id()` 等属性方法会被视为 "does not meet UI component syntax"，级联污染整个 @Builder 及其中调用的其他 @Builder（CalloutView、CodeBlockView 等）

### 2. 改 Scroll+Column+ForEach 为 List+ListItem，使用 `scrollToIndex`
- **结果**：`@Builder` 调用在 `ListItem` 内报 "does not meet UI component syntax"
- **原因**：ArkTS 不允许 `ListItem { this.BuilderMethod() }` 写法

### 3. 直接在 ForEach 回调内加 `index` 参数
- **结果**：同样触发级联编译错误
- **原因**：ForEach itemGenerator 签名变化导致 @Builder 调用上下文不兼容

## 关键约束
- `Scroll` 不支持 `scrollToIndex`，只有 `List`/`Grid`/`WaterFlow` 支持
- `@Builder MarkdownLineView` 内有 if-else 链（h1~h4、callout、codeBlock、annotation、kvQuote、li、quote 等），对属性修改极其敏感
- `MarkdownLineView` 内部调用 `this.CalloutView()`、`this.CodeBlockView()` 等 @Builder，任何修改都会级联影响

## 可能的解决方向

### A. 将 MarkdownLineView 拆成独立 @Component
把 `MarkdownLineView` 从 `@Builder` 改为 `@Component struct MarkdownLineItem`，通过 `@Prop ml: MarkdownLine` 传入。`@Component` 内的 if-else 链可能允许 `.id()`。
- **风险**：@Component 也不能在 ListItem 内直接使用（需要再套一层），且 @Builder 互调问题可能依旧
- **工作量**：中

### B. 给整个 ForEach 条目加 id
不改 MarkdownLineView 内部，而是在外层 ForEach 的每个条目外包一层 Column 并加 `.id('toc_h_' + index)`：
```ts
ForEach(this.markdownLines, (ml: MarkdownLine, index: number) => {
  Column() {
    this.MarkdownLineView(ml);
  }
  .id('toc_h_' + index)
}, ...)
```
这样 `componentUtils.getRectangleById('toc_h_5')` 可以定位到第 6 行的位置。
- **风险**：ForEach 回调内调 @Builder 可能仍有问题；多套一层 Column 可能影响布局
- **工作量**：小

### C. 用 onAppear 记录位置
在标题 onAppear 时记录其 `componentUtils` 位置到 Map，TOC 点击时查表 scrollTo。不需要 `.id()`。
- **风险**：onAppear 回调内能否调用 componentUtils 待验证
- **工作量**：小

### D. 使用 openCustomDialog（API 12+ 推荐）
不解决 TOC 跳转，延后到第三轮。

## 当前状态
- H4B（隐藏死按钮）✅ 已改
- M9（KB 返回键）✅ 已改
- H5（TOC 跳转）❌ 待解决
- 建议：先提交 H4B+M9，H5 单独攻坚
