# AI 推荐计算器 - 多轮卡片式澄清增强

- 日期：2026-07-27
- 状态：已确认，待实现
- 涉及文件：`entry/src/main/ets/components/LlmDialog.ets`、`entry/src/main/ets/services/LlmService.ets`

## 1. 背景与问题

应用现有 88 个临床计算器，分布在 8 个医学亚专科。用户通过侧边栏按分类浏览选择，但当计算器数量多、用户不确定该用哪个时，靠分类浏览效率低。

现有 AI 推荐功能（`LlmDialog`）采用单轮交互：用户输入一句自然语言病情描述，LLM 从 88 个计算器中返回最多 4 个 calcId，用户点"跳转"切换。存在两个问题：

1. **匹配精度不足**：system prompt 只用了 `description` 和 `whenToUse` 两个字段，未使用注册表里已填充的 `kw`（关键词）字段；且用户单句描述往往不足以精准表达临床需求（如"脑子有问题"可能指向 NIHSS / ICH / GCS / CAM-ICU 等多个计算器）。
2. **推荐不可解释**：LLM 只返回 calcId，`LlmRecommendation.reason` 字段始终为空字符串，用户无法判断"为什么推荐它"，也就无法自行判断推荐是否准确。

## 2. 目标

在不改变"推荐 + 跳转"核心交互、不引入新依赖的前提下，通过**动态多轮卡片式澄清**提升推荐匹配精度，并让推荐结果可解释。

## 3. 非目标

- 不做计算器字段预填（跳转后用户仍自行填写计算器输入）
- 不做语音输入（医学专业术语识别率低、病房环境嘈杂）
- 不做离线标签筛选器（未配置 LLM 时仅禁用，不退化备选方案）
- 不改动注册表结构、引擎层、其他计算器组件、AssistantService

## 4. 核心思路

把"单轮输入 -> 推荐"升级为**动态多轮澄清**：

```
用户输入自然语言
   ↓
循环（最多3轮）：
  LLM 基于"累积上下文"返回 confidence 与 action
  ├─ action==="recommend" 或 confidence≥0.7 或已达第3轮 -> 退出循环，进推荐
  └─ action==="clarify" -> 返回 1-2 个澄清维度（带选项按钮）-> 用户点选 -> 下一轮
   ↓
合并"原始输入 + 各轮澄清答案"作为最终上下文 -> LLM 返回带理由的推荐 -> 用户跳转
```

三个提升匹配精度的手段：
1. 给 LLM 更多匹配维度（注册表的 `kw` 关键词，此前未使用）
2. LLM 主动追问，而非要求用户重写整句
3. 用按钮选项降低用户回答成本（用户全程最多点选，无需二次打字）

## 5. 预设澄清维度

不依赖 LLM 凭空生成问题，预定义 6 个通用临床澄清维度。LLM 每轮从中选 1-2 个最相关的返回，保证问题可控、一致。

| 维度 key | 触发场景 | 选项示例 |
|---|---|---|
| `acuity` 急慢性 | 通用 | [急性][慢性][不确定] |
| `setting` 场景 | 通用 | [ICU][急诊][病房][门诊] |
| `hasLabs` 有无检验值 | 代谢/肾/肝/感染 | [有化验单][无][即将出] |
| `imaging` 影像 | 神经/呼吸/心血管 | [有CT][有MRI][有超声][无] |
| `ventilation` 通气 | 呼吸/危重 | [机械通气][无创][鼻导管][无] |
| `medication` 用药 | 心血管/代谢 | [升压药][抗凝][降糖][无] |

维度定义在 `LlmService.ets` 中以常量数组维护，便于后续增删。

## 6. LLM 交互协议

### 6.1 统一单端点

每轮调用同一个函数 `sendClarifyRound`，通过累积的对话上下文让 LLM 判断"继续问还是出推荐"。不区分"澄清端点"和"推荐端点"，简化调用逻辑。

### 6.2 请求构造

system prompt 包含：
- 全部 88 计算器的 `id / name / enName / kw / whenToUse`（**新增 kw 与 enName**，此前仅 description + whenToUse）
- 6 个澄清维度定义（key / 触发场景 / 选项示例）
- 输出格式约束（必须返回指定 JSON 结构）
- few-shot 示例（2-3 个：足够精准直接推荐 / 需1轮澄清 / 需2轮澄清）

messages 历史：首轮为用户原始输入；后续轮次追加 user 消息（格式化后的澄清答案，如"病情急慢性：急性；影像：有CT"）。保留全部历史，让 LLM 看到累积信息。

`max_tokens` 从现有 512 调整为 800（reason 文本 + 多轮 JSON 体积更大）。

### 6.3 响应结构（统一 JSON）

```json
{
  "confidence": 0.55,
  "action": "clarify",
  "questions": [
    {
      "dimension": "acuity",
      "prompt": "病情是急性还是慢性？",
      "options": ["急性", "慢性", "不确定"]
    }
  ]
}
```

当 `action === "recommend"` 时：

```json
{
  "confidence": 0.85,
  "action": "recommend",
  "recommendations": [
    { "id": "nihss", "reason": "急性脑卒中 + 有CT，NIHSS 用于溶栓决策和严重度分层" },
    { "id": "ich", "reason": "脑出血量评估，与 NIHSS 互补判断预后" }
  ]
}
```

### 6.4 停止条件

满足以下任一条件即退出循环进入推荐：
1. `action === "recommend"`（LLM 主动判断信息已足够）
2. `confidence >= 0.7`（即使 LLM 仍想问，达到阈值直接要求其出推荐）
3. 已完成第 3 轮澄清（硬上限，防无限循环）。第 3 轮请求时在 user message 追加指令"已达到最大澄清轮数，请基于现有信息直接给出推荐"，强制 LLM 返回 `action: "recommend"`。若 LLM 仍返回 clarify，忽略 action 直接取其 recommendations 字段（若为空则走降级保护）。

### 6.5 降级保护

LLM 返回非法 JSON、action 字段不识别、或 recommendations 为空时，走兜底逻辑：
- 复用现有 `parseRecommendations` 的暴力搜索策略（在原文中搜 id/name/enName）
- 用搜索结果生成无 reason 的推荐列表
- 不卡死用户，保证至少能出结果

### 6.6 错误处理

- 网络失败/超时：抛出 Error，由 UI 层显示错误信息 + "重试"按钮，保留已输入内容和已澄清答案
- HTTP 非 200：抛出含状态码和响应摘要的 Error

## 7. UI 交互流程

### 7.1 状态机

弹窗内状态从 2 态扩展为 4 态：

```
INPUT -> THINKING -> CLARIFY ⇄ THINKING -> RESULT
                       ↑____(下一轮)____↓
```

- `INPUT`：输入框 + 发送按钮（与现有一致）
- `THINKING`：LoadingProgress，文案"分析中..."
- `CLARIFY`：显示当前轮澄清卡片 + 历史已选答案折叠 + "确认继续" + "跳过直接推荐"
- `RESULT`：推荐结果卡片列表（含 reason）

### 7.2 CLARIFY 态布局

```
┌─────────────────────────────┐
│ AI 推荐计算器           ✕   │
│ ─────────────────────────── │
│ [输入框：描述病情...]        │
│ [发送]                       │
│                             │
│ 已选：急性 / 有CT  ▼         │  ← 历史折叠，点击展开
│                             │
│ 澄清第 2/3 轮                │
│ 为精准推荐，请补充：          │
│                             │
│ 用药情况？                   │
│ [升压药] [抗凝] [降糖] [无]  │  ← 单选 toggle，点选高亮
│                             │
│ [确认，继续分析 ->]           │  ← 选完后 enable
│ [跳过，直接推荐]              │  ← 始终可用
└─────────────────────────────┘
```

### 7.3 交互细节

- 澄清区顶部显示"第 N/3 轮"，让用户有预期
- 每个维度单选 toggle，点选即高亮，可切换
- "确认，继续分析"在当前轮所有维度都选完后 enable
- "跳过，直接推荐"始终可用，用户可随时终止澄清，用已有信息请求推荐
- 历史澄清问答折叠显示在输入框下方（如"已选：急性 / 有CT"），点击可展开查看全部，让用户看到累积了什么信息
- 用户确认后回到 THINKING 态，下一步可能进 CLARIFY（下一轮）也可能直接进 RESULT

### 7.4 RESULT 态布局

```
✅ 推荐结果

① NIHSS 卒中
   💬 急性脑卒中+有CT，用于溶栓决策和严重度分层
   [跳转 ->]

② ICH 评分
   💬 脑出血量评估，与 NIHSS 互补判断预后
   [跳转 ->]
```

- 结果卡片在现有 name + description 基础上，新增 reason 行，用 💬 图标前缀区分
- reason 为空时（兜底场景）不显示该行，只显示 description

### 7.5 状态清理

- 用户点"跳转"：切换 currentCalc，关闭弹窗，清空所有状态
- 用户点 ✕ 关闭：清空所有状态（输入、澄清历史、结果），下次重新开始
- 与现有 closeDialog 行为一致

## 8. 改动范围

### 8.1 LlmService.ets

| 改动项 | 说明 |
|---|---|
| 新增类型 `ClarifyQuestion` | `{ dimension: string; prompt: string; options: string[] }` |
| 新增类型 `ClarifyResponse` | `{ confidence: number; action: 'clarify'\|'recommend'; questions?: ClarifyQuestion[]; recommendations?: LlmRecommendation[] }` |
| 新增常量 `CLARIFY_DIMENSIONS` | 6 个维度的定义数组 |
| 新增函数 `sendClarifyRound` | 统一多轮调用入口，参数含 config、messages 历史；返回 `ClarifyResponse` |
| 改造 `buildSystemPrompt` | 拆为 `buildClarifySystemPrompt`：加入 kw/enName/维度定义/输出格式约束/few-shot |
| 改造 `parseRecommendations` | 解析新增 confidence/action/questions/reason 字段；保留兜底暴力搜索逻辑 |
| 调整 `max_tokens` | 512 -> 800 |
| `LlmRecommendation` | reason 字段真正填充（现有接口已有该字段，无需改结构） |

保留：`sendLlmRequest`（旧单轮函数，LlmDialog 不再调用，但保留以免其他调用点依赖）、`sendVisionRequest`、所有 HTTP/鉴权基础设施。

### 8.2 LlmDialog.ets

| 改动项 | 说明 |
|---|---|
| 新增状态 `dialogState` | `'input'\|'thinking'\|'clarify'\|'result'` |
| 新增状态 `clarifyRound` | 当前轮次（1-3） |
| 新增状态 `clarifyQuestions` | 当前轮 `ClarifyQuestion[]` |
| 新增状态 `clarifyAnswers` | 累积的 `{ dimension, answer }[]` |
| 新增状态 `llmMessages` | 累积的对话历史，传给 `sendClarifyRound` |
| 新增 Builder `ClarifyArea` | 渲染澄清卡片 + 历史折叠 + 确认/跳过按钮 |
| 改造 `ResultArea` / `RecommendationCard` | 新增 reason 行（💬 前缀） |
| 改造 `sendQuery` | 改为调用 `sendClarifyRound`，按响应 action 驱动状态机 |
| 新增方法 `submitClarify` | 格式化澄清答案追加到 llmMessages，调下一轮 |
| 新增方法 `skipToRecommend` | 用已有信息强制请求推荐（action=recommend） |

保留：浮动按钮 FAB 及拖拽逻辑、`getActiveService`/`jumpToCalculator`/`closeDialog`、整体弹窗结构。

### 8.3 不改动

- `model/CalculatorRegistry.ets`（kw 等字段已存在，直接读取）
- `engine/*`（不涉及计算逻辑）
- `services/AssistantService.ets`（助手页的另一套 LLM 流程，独立）
- 其他计算器组件
- 无新增文件、无新增依赖

## 9. 数据流示意

```
用户输入 "脑子有问题"
   │
   ▼ sendClarifyRound(config, [{role:user, content:"脑子有问题"}])
LLM 返回 { confidence:0.4, action:"clarify",
          questions:[{dimension:"acuity", options:[急性,慢性,不确定]},
                     {dimension:"imaging", options:[有CT,有MRI,无]}] }
   │
   ▼ 用户点选 [急性] [有CT]
submitClarify: llmMessages 追加 {role:user, content:"病情急慢性：急性；影像：有CT"}
   │
   ▼ sendClarifyRound(config, llmMessages)
LLM 返回 { confidence:0.6, action:"clarify",
          questions:[{dimension:"medication", options:[升压药,抗凝,降糖,无]}] }
   │
   ▼ 用户点选 [无]
submitClarify: llmMessages 追加 {role:user, content:"用药情况：无"}
   │
   ▼ sendClarifyRound(config, llmMessages)  (第3轮，强制要求 recommend)
LLM 返回 { confidence:0.85, action:"recommend",
          recommendations:[{id:"nihss", reason:"..."}, {id:"ich", reason:"..."}] }
   │
   ▼ 渲染 RESULT 态，用户点"跳转"
jumpToCalculator("nihss")
```

## 10. 测试要点

因项目无自动化测试框架，采用手动验证：

1. **精准输入直达**：输入"急性脑卒中 NIHSS 评分"，期望 confidence 高、可能 0 轮澄清直接推荐 nihss
2. **模糊输入多轮**：输入"脑子有问题"，期望经 1-2 轮澄清后推荐 nihss/ich/gcs 等
3. **跳过功能**：任意澄清轮点"跳过直接推荐"，期望用已有信息出推荐不卡死
4. **第3轮硬上限**：构造持续低 confidence 的输入，期望第3轮后强制出推荐
5. **非法响应降级**：模拟 LLM 返回乱码，期望走兜底暴力搜索出推荐
6. **未配置 LLM**：不配置 API 时点按钮，期望显示"请先配置"
7. **reason 展示**：推荐结果含 reason 时正常显示，兜底无 reason 时不显示该行
8. **状态清理**：关闭弹窗再打开，期望全部状态重置

## 11. 后续可扩展

- 增减澄清维度：修改 `CLARIFY_DIMENSIONS` 常量即可
- 调整 confidence 阈值或最大轮数：常量化，便于调参
- 若 ArkUI 未来支持组件动态实例化，可结合本协议实现推荐后自动预填字段
