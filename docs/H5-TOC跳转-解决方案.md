# H5 知识库 TOC 跳转 — 解决方案

> 2026-07-21，针对 `H5-TOC跳转-未解决.md`。
> 结论：之前三次尝试全都在"给 @Builder 内部/ForEach 签名动手术"，这正是编译器级联报错的根源。**正确思路是反向的：在解析期把锚点 id 盖章到数据上，渲染层只做条件包裹，一行 @Builder 内部代码都不碰。**

## 为什么之前会失败（根因分析）

- 尝试 1（@Builder if-else 分支内加 `.id()`）：ArkTS 对 @Builder 内条件分支的属性链语法检查极严，一处不合规就连锁污染整个 @Builder 及下游调用（CalloutView/CodeBlockView 等），100+ 报错里只有最早的一两条是真错误。
- 尝试 2（List+ListItem 内调 @Builder）：`ListItem` 必须是 `List` 的**直接子节点**。原结构是 `Scroll { Column { ForEach {...} } }`，如果只把 ForEach 内容换成 ListItem 而忘了把外层 Column 一起拆掉，报的就是 "does not meet UI component syntax"，且报错行会错误地指向 @Builder 调用处。
- 尝试 3（ForEach 加 index 参数）：`ForEach(arr, (item, index) => {...})` 本身是合法 ArkTS（`:825` 的 keyGenerator 已经在用 index）。级联报错大概率是尝试 1/2 的残留代码未清理干净。但仍不推荐这条路——见下方更稳的做法。

## 推荐方案：解析期盖章 + 条件包裹 + getRectangleById

**核心原理**：`Scroll + Column` 不是虚拟化容器，所有子组件都真实参与布局，因此 `componentUtils.getRectangleById` 对屏外元素也能拿到正确位置。不需要 List，不需要 scrollToIndex。

### 第 1 步：MarkdownLine 加锚点字段（KbMarkdownParser.ets:3）

```ts
export class MarkdownLine {
  // ...现有字段不动
  anchorId: string = '';   // 仅 h2/h3 标题行非空，如 'kb_toc_0'
}
```

### 第 2 步：新增从已解析行生成 TOC 的函数（KbMarkdownParser.ets）

`extractToc(content)` 扫的是原始文本，和 `parseKbMarkdown` 的产物可能因 callout 合并等不对齐。**改为以解析结果为单一数据源**，顺序天然一致，也不会受重复标题影响：

```ts
export function extractTocFromLines(lines: MarkdownLine[]): TocEntry[] {
  const entries: TocEntry[] = [];
  let k = 0;
  for (const ml of lines) {
    if (ml.type === 'h2' || ml.type === 'h3') {
      ml.anchorId = 'kb_toc_' + k.toString();   // 顺便盖章
      const entry = new TocEntry();
      entry.text = stripMarkdownInline(ml.text); // 与渲染文本一致
      entry.level = ml.type === 'h2' ? 2 : 3;
      entry.anchor = ml.anchorId;
      entries.push(entry);
      k++;
    }
  }
  return entries;
}
```

注意顺序：必须先 `parseKbMarkdown` 再 `extractTocFromLines`（盖章发生在遍历时）。页面两个调用点（`KnowledgeSearchPage.ets:164`、`:181`）改为：

```ts
this.markdownLines = parseKbMarkdown(page.content);
this.tocEntries = extractTocFromLines(this.markdownLines);
```

### 第 3 步：ForEach 处条件包裹（KnowledgeSearchPage.ets:823）

不动 MarkdownLineView 内部，不加 index 参数，只在回调里加二分支：

```ts
ForEach(this.markdownLines, (ml: MarkdownLine) => {
  if (ml.anchorId.length > 0) {
    Column() {
      this.MarkdownLineView(ml);
    }
    .width('100%')
    .id(ml.anchorId);
  } else {
    this.MarkdownLineView(ml);
  }
}, (ml: MarkdownLine, index: number) => index.toString());
```

外包的 Column 是布局中性容器（width 100%、无 padding/margin），不影响现有排版。

### 第 4 步：TOC 点击滚动（KnowledgeSearchPage.ets:788）

给阅读区 Scroll 也加个 id：`:806` 的 `Scroll(this.pageScroller)` 链上加 `.id('kb_scroll')`。然后：

```ts
.onClick(() => {
  this.showToc = false;
  const targetId = entry.anchor;
  setTimeout(() => {                      // 等 dropdown 收起、布局稳定
    const scrollRect = componentUtils.getRectangleById('kb_scroll');
    const targetRect = componentUtils.getRectangleById(targetId);
    const cur = this.pageScroller.currentOffset();
    this.pageScroller.scrollTo({
      xOffset: 0,
      yOffset: cur.yOffset + (targetRect.windowOffset.y - scrollRect.windowOffset.y),
      animation: true
    });
  }, 100);
})
```

- `componentUtils` 需要 `import { componentUtils } from '@kit.ArkUI';`
- `currentOffset()` 返回 `{ xOffset, yOffset }`；`getRectangleById` 的 `windowOffset` 是相对窗口的，两者相减再叠加当前滚动量即得绝对位置
- setTimeout 延迟 50–100ms 足够；若首次点击偶发无效，可把延迟加大到 200ms

### 编译风险自查清单

1. 每次只改一步就编译一次，不要攒着——级联报错时只有第一条是真错误
2. 若第 3 步仍报错，先 `git stash` 确认基线能编译，再单独应用第 3 步——用来区分"新写法有问题"还是"旧残留没清干净"（本项目 PITFALLS 已有先例：报错归因被误导）
3. `.id()` 只允许加在系统组件上（Column/Text/Row 都可以），不能加在 `this.MarkdownLineView(...)` 这种 @Builder 调用的结果上——这是尝试 1 最可能踩中的硬约束

## 备选方案（不推荐本轮做）

List 化 + `scrollToIndex` 是长期更优解（长指南文档有虚拟化收益），但需要：把 sourceInfo 头和 PageFooter 也改造成 ListItem（索引整体 +1）、验证 List 在 layoutWeight(1) 下的高度、回归 Markdown 全部行型的渲染。工作量和回归面都大，第三轮再议。

## 验证

1. 打开一篇多 h2/h3 的长文（如神经重症镇痛镇静 index），点开 TOC，逐条点击，应平滑滚动到对应标题
2. 重复标题（如有）各自跳转正确（盖章按出现顺序，不受重名影响）
3. 跳转后 TOC 已收起；物理返回键行为不变（M9 已修的链路不受影响）
