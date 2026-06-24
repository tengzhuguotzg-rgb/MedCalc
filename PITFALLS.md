# 踩坑记录

## ArkTS 语法

### 小数输入不要用 InputType.Number
鸿蒙数字键盘不带小数点，需要输小数的字段（体温、体重、剂量等）不要设 `.type(InputType.Number)`，默认键盘即可。

### 多选按钮显示不全 → 用 FlexWrap
长文本按钮在 `Row` + `layoutWeight` 里会被挤到看不见。**修复**：改用 `Flex({ wrap: FlexWrap.Wrap })`，按钮用 `padding` + `margin` 定宽，空间不够自动换行。

### onChange 不要做计算
`parseFloat("0.")` 返回 0 → state 变 0 → 重绘 → 输入框丢焦点/删不动。
**原则**：onChange 只存原始字符串，计算由按钮触发。

### Anthropic 格式的 content 是数组
MiniMax 等兼容 Anthropic API 的返回 `content: [{type:"thinking",...}, {type:"text", text:"..."}]`。必须遍历找 `type==="text"` 的项，不能直接取 `[0]`。

### 禁止 any/unknown
ArkTS 规则 `arkts-no-any-unknown`。用 `Record<string, object>` + `as` 转换代替。

### JSON.parse 需要 as 转换
`JSON.parse` 返回 `object | null`，用 `as Record<string, object>` 转后才能索引。

## LLM 推荐

### 格式越简单越好
让 LLM 输出 `id|名称|原因` → LLM 开始思考过程 → 返回思考内容 → 解析失败。只让输出逗号分隔的 ID 最稳定。

### 不要用关键词匹配
LLM 的医学知识比关键词更准。`kw` 里的"钠""校正"等泛化词会误导。只给 `description`（临床用途）即可。

### 解析器永远有回退
LLM 不一定会按格式输出。字符串扫 ID/名称做兜底。

### 先确认 API 响应结构
不同厂商响应体格式不同。先 curl 看一眼再写解析器。

## 临床逻辑

### 评分标准要逐项核对原文
原项目 KDIGO 中 `cr1 >= 1.5` 是绝对值（mg/dL），标准应是 `ratio >= 1.5`（倍基线）。原代码有 bug，移植时要修。

### SOFA 肾脏取最大值
尿量和肌酐分取 `Math.max`，不是 `else if` 互斥。

### 特殊药物特殊处理
垂体后叶素用 U/min、不按体重，和其他升压药不同。同类但不同单位。

### 双向换算用按钮
"已知A求B"型计算器（如升压药换算），用按钮触发比边输边算更稳，避免输入抖动。

### ForEach 在 @Builder 里不响应状态变化
`@Builder` 内 `ForEach` 的 Button 在父组件 state 变化后不会更新样式。**原因**：ArkUI 按 key 复用组件，key 不变则不更新属性。

**修复**：ForEach 的 key 要包含判断依据：
```typescript
ForEach(items, (item) => { Button(...).color(value === item ? ...) },
  (item) => item.toString() + '-' + value.toString())
```
这样 value 变化时 key 变，组件重建，样式刷新。

### @Builder 的参数不是响应式的
`@Builder func(label: string, value: number)` — 当父组件 `@State` 变化后 `build()` 重跑，`@Builder` 会重新调用，但内部创建的子组件可能被缓存而不更新。

**不能用 `@Builder` 转发响应式数据**。需要响应 state 变化的 UI 片段必须用 `@Component` + `@Prop` 实现。`@Prop` 才是一向数据绑定，父 state 变 → 子 `@Prop` 变 → 子重绘。
