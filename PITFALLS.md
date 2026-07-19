# MedCalc ArkTS/UI Pitfall Log

Every time a non-trivial UI/ArkTS bug is found and fixed, add it here. Consult this file before writing or reviewing `.ets` code to avoid repeat mistakes.

---

## 2026-07-09 Callout body lines not merging with header

**Symptom**: Obsidian `> [!info] title` callout renders as a tiny header-only box, while body lines (`> some text`) appear as separate yellow `quote` boxes below it.

**Root cause**: In `KbMarkdownParser`, after a `callout-header` line, subsequent `> text` lines were classified as `quote` (not `callout-body`) because the parser had no state tracking whether we were inside a callout. Without `callout-body` classification, the second-pass merge never grouped body lines with the header.

**Fix**: Added `inCallout` boolean flag. Set `true` on `callout-header`, classify following `> text` / `>text` lines as `callout-body` while `inCallout` is true. Reset `inCallout = false` on any non-quote line (blank, heading, list, table, hr, text). Bare `>` (callout internal blank separator) keeps `inCallout` alive.

**Rule**: Any parser that groups consecutive lines must use explicit state flags; do not rely on type-based second-pass merge alone when the first-pass type assignment depends on context.

---

## 2026-07-09 Standalone short quote renders as oversized background box

**Symptom**: A single short `> 心脏功能障碍 → 心输出量不足 → **终末器官低灌注**` renders as a tall yellow background box with disproportionate vertical space.

**Root cause**: The `quote` type used `Row { Row(height:'100%') + Text(padding:{10,10,6,6}) }` with `backgroundColor('#FFF8E1')`. The `height:'100%'` on the left border stripe forced the Row to be taller than the text needed, and the generous padding + background made it visually dominant for a short emphasis line.

**Fix**: Removed `backgroundColor`, removed `height:'100%'` (changed to fixed `height(14)`), reduced padding to `{left:8}` only, removed italic. Short quotes now render as a compact left-bordered line.

**Rule**: `height:'100%'` inside a Row whose height is determined by sibling content often causes oversized containers. Use fixed heights for decorative stripes. For short emphasis text, avoid full-width background boxes.

---

## 2026-07-09 Markdown table columns misaligned in Chinese/mixed content

**Symptom**: Table header `| # | 章节 | 文件 | 核心内容 |` and data rows have columns that don't line up — the `│` separator positions drift because Chinese characters are double-width but monospace font metrics differ.

**Root cause**: `stripTableMarkdown()` replaced `|` with ` │ ` and rendered the whole row as a single `Text` with `fontFamily('monospace')`. Column alignment depended on character-count, which fails with CJK fullwidth characters mixed with ASCII.

**Fix**: Added `cells: string[]` field to `MarkdownLine`. Added `parseTableCells()` to split `|a|b|c|` into `['a','b','c']` with inline markdown stripped. Renderer uses `Row { ForEach(cells, cell => Text(cell).layoutWeight(1)) }` so each column gets equal flex weight regardless of character width.

**Rule**: Never render Markdown tables as a single monospace Text line with `│` separators when CJK content is present. Always split into cells and use `Row`+`layoutWeight(1)` per cell.

---

## 2026-07-09 Emoji prefix in headings causes visual misalignment with left border

**Symptom**: `## 📐 指南结构` renders with the 📐 emoji overlapping or misaligned against the h2 left border (`border { left: 3 }`).

**Root cause**: `stripEmojiPrefix()` used a Unicode range regex with `/u` flag: `/^[\u{1F300}-\u{1F9FF}...]\s*/u`. While ArkTS supports `/u`, the regex was fragile and may not reliably strip all emoji variants (compound emoji like 🏷️ with VS16, variation selectors). If emoji survives stripping, it renders at the border edge and looks misaligned.

**Fix**: Replaced regex with hardcoded emoji list matching. Loop through known emoji strings, `startsWith()` check, then `substring()` + `trimStart()`.

**Rule**: Do not rely on Unicode-range regex for emoji stripping in ArkTS. Use explicit emoji string list + `startsWith()` for reliability. The `/u` flag works but Unicode ranges miss compound emoji (VS16, ZWJ sequences).

---

## 2026-07-09 Physical back key exits app instead of navigating back in knowledge base

**Symptom**: Pressing the physical back button on phone while viewing a knowledge article or category page exits the app to the home screen instead of going back to the previous view.

**Root cause**: Only `PatientDetailPage` had a `navDepth`/`backFlag` mechanism via `AppStorage`. `KnowledgeSearchPage` had no such mechanism. `Index.onBackPress()` only checked `patientNavDepth > 0`, so when on the KB tab with articles open, `patientNavDepth` was 0, `onBackPress()` returned `false`, and the system treated it as an exit.

**Fix**: Added `kbNavDepth`/`kbBackFlag` mirrors of the patient pattern. `KnowledgeSearchPage` calls `syncNavDepth()` whenever `browseMode` or `readingPage` changes (via `@Watch`). `Index.onBackPress()` checks `kbNavDepth > 0` before `patientNavDepth > 0`.

**Pattern for any sub-page navigation**:
1. Component tracks its own `navDepth` (0=root, 1=drill-down, 2=detail).
2. Sync depth to `AppStorage.setOrCreate('xxxNavDepth', depth)` on every navigation change.
3. Add `@Watch('onXxxBackFlagChanged') @StorageLink('xxxBackFlag')` + `navigateBack()` method.
4. `Index.onBackPress()` checks each tab's navDepth; if >0, increment that tab's backFlag, return `true`.

---

## 2026-07-09 PanGesture on outer Column ignored when Scroll child swallows touches

**Symptom**: `PanGesture` attached to an outer `Column` containing a `Scroll` child never fires; horizontal swipe does nothing.

**Root cause**: `Scroll` component consumes touch events for its own scroll gesture. `.gesture()` has lower priority than child gestures. Even `PanDirection.Horizontal` doesn't help because Scroll intercepts first.

**Fix**: Don't use PanGesture for back navigation. Use the `navDepth`/`backFlag` pattern instead. If swipe is truly needed, use `.parallelGesture()` on the `Scroll` itself (not the parent), but even this is unreliable on real devices.

**Rule**: For "swipe to go back" on HarmonyOS, prefer the physical back key + `navDepth`/`backFlag` mechanism. `PanGesture` on parents of `Scroll` is fundamentally broken; `.parallelGesture()` on `Scroll` works sometimes but is fragile.

---

## 2026-07-09 @Builder method returning PanGesture causes ArkTS compiler error

**Symptom**: `private swipeBackGesture(): PanGesture { return PanGesture(...)... }` causes error: `'PanGesture' refers to a value, but is being used as a type here`.

**Root cause**: ArkTS does not allow `PanGesture` as a return type annotation. Gesture objects are not valid return types for methods.

**Fix**: Inline the `PanGesture` directly at the `.parallelGesture()` call site instead of extracting to a method. Or avoid gestures entirely (use back-key pattern).

**Rule**: Never use `PanGesture`, `TapGesture`, etc. as return types of methods. If gesture reuse is needed, duplicate the inline code. In ArkTS, gesture builders are not first-class values that can be returned from methods.

---

## 2026-07-10 Stop-word stripping destroys compound clinical entity names

**Symptom**: Searching "社区获得性肺炎" (CAP) yields poor results because refineQuery strips "获得性" as a stop-word, leaving "社区 肺炎" which is not a clinically meaningful term pair. The OR expansion then matches any "肺炎" document, losing CAP specificity entirely.

**Root cause**: The STOPWORDS list contained "获得性" because it's a modifier in many contexts (e.g., "获得性免疫缺陷"). But in "社区获得性肺炎", "获得性" is part of the compound entity name — removing it changes the meaning from CAP to generic "community pneumonia".

**Fix**: Removed "获得性" from STOPWORDS. Added COMPOUND_PREFIXES list ("社区获得性", "医院获得性", "获得性免疫", "获得性肺炎") that is extracted and protected BEFORE stop-word stripping. refineQuery now checks for compound prefixes first, removes them intact, then applies stop-word stripping to remaining terms.

**Rule**: Stop-word stripping must respect compound entity boundaries. Clinical terms like "社区获得性肺炎" are single entities — internal components should not be stripped independently. When building a medical stop-word list, test against known compound entities to verify integrity is preserved.

---

## 2026-07-10 OR-expanded search loses specificity — core term filter needed

**Symptom**: LLM query expansion for "脓毒症" adds "败血症", "感染性休克", "Sepsis" etc. OR search then matches any document containing any expanded term. For "社区获得性肺炎", expanded to "CAP", "肺炎链球菌", "肺炎" — the term "肺炎" alone matches ~40+ documents, most not CAP-specific.

**Root cause**: Pure OR expansion maximizes recall but sacrifices precision. The original query's core semantic specificity is lost when expansion terms are much broader than the original.

**Fix**: Added two-stage filtering in smartSearch: (1) broad OR search to maximize recall, (2) filterByCoreTerms that prioritizes results matching original query's core terms (from refineQuery), demotes results matching only expanded terms. If core-matched results < limit, falls back to include expanded-only results.

**Rule**: In RAG pipelines with query expansion, always preserve original query specificity. OR expansion is for recall; core-term filtering is for precision. The pipeline should be: expand→broad search→core-term prioritize→LLM rerank→top-N.

---

## 2026-07-10 FTS5 title field missing topic keywords for numbered-chapter textbooks

**Symptom**: "实用重症医学" textbook chapters have titles like "第36章 脓毒症". FTS5 title field stores this as-is. While "脓毒症" is in the title, the chapter number prefix adds noise. More critically, tags in YAML frontmatter (e.g., "第五篇", "脓毒症", "机体反应与器官功能不全") contain additional topic keywords not in the title that could improve matching.

**Root cause**: extractTitle() only returns the YAML title field. The tags field contains topic keywords that would improve FTS5 title-match quality and help core-term filtering work better for textbook chapters.

**Fix**: Added extractTags() method to parse YAML tags array. buildIndex() now appends tags to the indexed title: `title + ' ' + tags.join(' ')`. This gives FTS5 more surface area for title matching without changing the displayed title. DB_VERSION bumped to 3 to trigger reindex.

**Rule**: When indexing documents with structured metadata (YAML frontmatter), extract and include all keyword-bearing fields (tags, categories, aliases) in the FTS title column. This improves both recall (more terms to match) and ranking (title matches rank higher than content matches in FTS5).

---

## 2026-07-10 FTS5 full-text indexing causes cross-topic noise in medical wiki

**Symptom**: Searching "重症肺炎" returns brain meningitis (脑膜炎) articles. Brain meningitis guidelines mention "肺炎球菌" (pneumococcus) and "肺炎链球菌" (S. pneumoniae) as pathogens — these are legitimate meningitis content, but FTS5 treats them as "肺炎" matches, causing the meningitis article to rank alongside actual pneumonia articles.

**Root cause**: FTS5 indexed the full article text (content column). Medical wiki pages naturally cross-reference related diseases — every guideline mentions differential diagnoses, pathogen names that overlap with other diseases. "肺炎球菌脑膜炎" contains "肺炎" but is about meningitis, not pneumonia. Full-text indexing cannot distinguish "article about pneumonia" from "article mentioning pneumonia-related terms".

**Fix**: Replaced full-text content indexing with metadata-only indexing (Karpathy LLM Wiki pattern). FTS5 `kb_index` now indexes only: title + tags + summary (from YAML frontmatter) + path keywords + wikilink targets. Full article text is stored in a separate `kb_content` table for reading but NOT indexed for search. Metadata naturally contains only the article's own topic, not mentions of related diseases. Also removed LLM rerank (B方案) since metadata-level search already has high precision — rerank was compensating for full-text noise that no longer exists.

**Rule**: For topic-focused wiki knowledge bases where articles cross-reference related topics, NEVER index full article text for search. Index only structured metadata (title, tags, summary, path, link targets) that reflects the article's own topic. Cross-topic mentions are content, not search signals. Full-text indexing in medical/academic wikis creates precision-killing noise from pathogen names, differential diagnoses, and comparative references.

---

## 2026-07-10 Cross-topic disease names in summary/tags still cause FTS5 noise after metadata-only indexing

**Symptom**: Even after switching to metadata-only FTS5 indexing, "重症肺炎" search could still match brain meningitis articles because their summary field contained "肺炎链球菌" as a pathogen name. Metadata was supposed to be topic-focused but YAML summary fields naturally mention cross-topic entities (pathogens, differential diagnoses, complications).

**Root cause**: Summary fields are human/LLM-written natural language that inevitably mentions related diseases. "细菌性脑膜炎抗生素方案：已知致病菌（肺炎链球菌/HIB/...）" — "肺炎链球菌" is legitimate meningitis content but triggers FTS5 match for "肺炎". Tags can also contain cross-topic terms (e.g., "AKI" tag in a sepsis article about sepsis-associated AKI).

**Fix**: Two-layer approach: (1) Data cleaning — systematically replaced cross-topic disease names in summaries/tags with non-triggering equivalents: "肺炎链球菌"→"S.pneumoniae(肺炎双球菌)", "脓毒性休克"→"septic shock", "心源性休克"→"CS(cardiogenic shock)", "液体复苏"→"容量复苏", "癫痫"→"seizure", etc. Scoped tags where the concept is a sub-type: "AKI"→"SA-AKI" in sepsis, "AKI"→"ACLF-AKI" in liver failure, "AKI"→"PPI-AKI" in stress ulcer. (2) Verification agent — added `verifyResultsWithLlm()` as final step in smartSearch. LLM judges each result as relevant/irrelevant based on whether the article's TOPIC is about the query disease, not just mentioning it. This is a binary acceptance filter (unlike rerank which only reorders).

**Rule**: In medical KB search, metadata-only indexing is necessary but not sufficient. Summary/tag fields will always contain some cross-topic disease names because clinical content is inherently interconnected. Two defenses needed: (1) Proactive data cleaning — replace cross-topic disease names with English abbreviations or scoped compound terms in summary/tags; (2) Verification agent — LLM-based acceptance filter that distinguishes "article about X" from "article mentioning X".

---

## Todos

1. **PDF上传扩展名硬编码** — `ImageStore.getExtFromUri()` 不认识 `.pdf`，返回 `jpg`，虽然后续 `copyFileSync` 能复制但扩展名不对，需加 `.pdf` 识别
2. **RULE_SEARCH_HINTS** — 症状名诊断（如"血小板减少"）搜 KB 时被 HLH/DIC/ITP 等多病种文章淹没，需加搜索定向词
3. **数据趋势图** — 同指标多次采集后可视化为折线图，包括评分趋势（SOFA、P/F等）
4. **诊断确认交互** — 用户可对 LLM 提示的诊断手动"确认/排除"
5. **真机跑完整流程验证** — 上传化验单确认预警/诊断正确触发
6. **`输入文本`按钮无 onClick** — `PatientDetailPage.ets` 中"输入文本"Button 没有绑定事件处理函数
