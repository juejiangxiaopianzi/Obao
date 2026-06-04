---
name: obao-review
description: |
  Turn a weekly report into a deep-review share page. Input the report content + a one-paragraph self-intro (department / business modules / direct reports / red lines), output a single local HTML file with three pivot views (OKR / Topic / People), nested hover cards, and a side-drawer (original / AI analysis / Feishu comment draft). Lets an LLM follow up every loose end and pre-draft the comments you'd otherwise type by hand. Output is always in Chinese.

  把一份周报变成「深度审阅 share 页」。输入周报正文 + 一段自我介绍（部门/业务模块/下属/红线），产出一份本地浏览器能直接打开的 HTML 文件，含 3 视角表格（OKR / 专项 / 人）+ 双层悬浮卡 + 右侧抽屉（原文 / 分析 / 评论草稿）+ 卡片化呈现。让 LLM 帮你把一周的事追问到底，把可以丢给团队的飞书评论先草拟好。

  Triggers / 触发词: review my weekly report / 审周报 / 深度审阅 / workpad / obao / O包 / 周报 share 页 / 周报评论 / 帮我看下这份周报
---

# Obao · 周报深度审阅 Skill

把「一份周报 + 一段你的自我介绍」变成一份本地可打开的精致 HTML —— 像一个高级助理看完周报、写好了所有要追问的问题、把可以丢给团队的飞书评论先帮你草拟好。

---

## 触发判断

用户说以下意图时主动用本 skill：
- 「帮我审一下这份周报」
- 「obao / O包 跑一下」
- 「生成周报 share 页」
- 「这份周报你帮我深挖一下」
- 「把这份周报变成可以贴评论的样子」

不要在用户**真要把审阅意见同步到飞书/钉钉/Notion** 时用本 skill —— 那需要走外部 API 集成。本 skill 只产**单文件本地 HTML**。

---

## 定位（动手前先记死这条灵魂）

obao **不是通用秘书**，是**「带着你的立场和红线替你追问」的私人参谋**。

飞书有你全部平台数据，但它保持中立，给不出带杀气的追问；obao 不比"数据全"，只比三件飞书做不到的事：

1. **用你本人的立场 / 红线审** —— 同一份周报，你和别人关注的点不一样
2. **D1-D7 管理者追问纪律** —— 把你会怎么逼问、追到哪一层，沉淀成死规矩
3. **本地单文件、数据不上云** —— 周报 / OKR / 下属名都留在你电脑里

所以分身信息收集（onboarding）的铁律是：**飞书把你的数据全拿走了，所以 obao 一个字节平台数据都别重复收，只收飞书偷不走的三样——你怎么说话、你被什么坑过、什么板只有你能拍。**

---

## 两档架构（默认丝滑 · 进阶准确 · 是漏斗不是妥协）

obao 用两档化解「丝滑 vs 准确」的张力。**冲突时丝滑优先拿到用户，准确优先留住用户，两档是漏斗不是妥协。**

| 档 | 定位 | 入口条件 | 行为 |
|---|---|---|---|
| **丝滑档**（默认入口 · 拿用户） | 贴一份周报就能跑 | 无需 OKR · 自我介绍可选 | 用通用管理者规则先出一版 · **不反推任何 KR 数字**但保留追问 · 在产出里反向勾「我猜你的红线是 X，对吗」 |
| **准确档**（留用户） | 像你本人、判断准 | **强制**分身设定（至少 speak_style / 红线）+ OKR | 引 KR 原值做缺口分析 · 跑完整 D0-D7 自检 · 化词评论模仿你的语癖 |

- 丝滑档就是把 prompt.md 里「占位符为空兜底逻辑」**升格为一等公民**，不是异常处理。
- 冷启动可零 onboarding 直接跑丝滑档；用户每纠一次错、补一个字段，就往准确档靠一步（**边用边长**）。

---

## 输入与分身信息收集（onboarding 重设计）

### 这次审阅必给的两样（缺就问 · 严禁用范本）

| 必填 | 字段 | 没提供时怎么办 |
|---|---|---|
| ✅ | 周报原文（markdown / 纯文本） | **必须问用户要** · 不许编 · 不许用范本 |
| ⚠️ | 本季 OKR（KR 名 + 当前数字 + 目标数字） | 准确档必给；丝滑档可缺，缺时评论不出现任何数字对照 |

> ⛔ 严禁：用「演示范本」自动跑 demo · 没给周报就编一份周报 · 没给 OKR 就**从周报反推 KR 数字**（反推业务模块 OK · 反推 KR 数字 = 编 = 砸招牌）。

### 分身 onboarding —— 零填表 · 贴材料 + obao 提炼 + 你点头 · <5 分钟

**全程不让用户填表**。对每个字段都走「你贴材料 → obao 自动提炼出画像 → 给你看 → 你删改确认」三步。

#### MVP 必收 3 字段（都是飞书拿不到的独占信息）

| 字段（占位符） | 它是什么 | 采集方式（零填表） |
|---|---|---|
| `speak_style`（表达 DNA） | 你怎么说话：助词 / 高频开头 / 句长 / 错别字白名单 | 让用户贴 / 授权扫**过去 ~50 条飞书评论或 IM**，obao 自动提炼语癖画像 → 给用户看 → 删改确认 |
| `known_data_pitfalls`（数字陷阱） | 你审周报最常被什么数字糊弄 | 对话问 2-3 题：「你审周报最常被什么数字糊弄过？」「有没有『完成 X%』其实只是中间目标？」→ 提炼成陷阱清单 → 确认 |
| `red_lines_taxonomy`（红线 / 球分界） | 哪些板只有你能拍、哪些是下属的球 | 出 6-8 道「这件事**我拍 / 下属拍**」二选一连续题 → 直接生成「球 vs 红线」分界 |

#### 改采集方式 / 降级的字段

- `identity`（身份）：**降级**，飞书全有，开场一句话带过即可，不进 onboarding 字段表。
- `user_okrs`（OKR）：改成**「贴 OKR 文本 → obao 解析」**，不手填；解析后**逐条反问** `hidden_metrics`（这个 KR 你真正盯的隐含指标是啥）。
- `direct_reports`（下属）：**贴一份历史周报 → obao 反推人名 + 花名候选 → 你确认**，不手录花名册。

#### 边用边长（终身续费）

- 冷启动可**零 onboarding** 直接跑丝滑档，用通用规则先出一版。
- 在产出里反向勾确认：「我猜你的红线是 X，对吗」「这条我没敢追，因为不知道是不是你的陷阱」。
- `corrections`（纠错库）**永远被动累积**：用户说「这条不对」/ 在 share 页点「教 Obao」，Obao 就**真把它 append 到本地文件 `~/.obao-review/corrections.md`**（不是嘴上答应、不是写浏览器）。开局 Step 0 必读这个文件，下次不再犯。这是终身续费机制，不主动问。详见 prompt.md「纠错机制」。

### OKR 处理细则

- 用户**给了 OKR** → 评论里可引用具体数字、做缺口分析（准确档 · D3 才能落实）
- 用户**只给 KR 名字、没给数字** → **再问一次**「这个 KR 当前进度是多少？目标是多少？」并顺手反问 hidden_metrics
- 用户**说「没有 OKR / 业务太新没设」** → 走丝滑档，评论里**不许出现任何数字对照**，只追问进度 / 时间 / 责任
- 用户**说「不告诉你 OKR」** → 同上丝滑档，**不许从周报反推 KR 数字**

⛔ 反推**业务模块**（按事项归类）可以；反推**KR 数字**（"目标是 8%"）= 编造，立刻砸招牌。

---

## 7 步加工流程

### Step 1 · 读资源

读这 2 个文件理解上下文：
- `assets/template.html` ← HTML/CSS 模板（紫色 + 6 列 + 抽屉 · 不要重新发明）
- `assets/prompt.md` ← 完整 SYSTEM_PROMPT（9 步加工 + D1-D7 死规矩 + 3 视角 schema + A-J 红线）

### Step 2 · 处理周报输入

- 用户给 markdown / 文本 → 直接用
- 用户什么都没给 → **问用户要** · 不许跑

### Step 3 · 处理分身设定（自我介绍原文）

- 用户给了 → 整段保留 · 当作 prompt 上下文
- 用户**没给** → **必须问用户**：
  > "我不知道你的工作背景 · 没法替你审周报。给我一段自我介绍：你是什么部门 / 岗位 / 业务模块（几条主线）/ 下属是谁（含花名）/ 红线（什么事必须你亲自审）· 一段话搞定。"
- ⛔ **严禁默认填任何内容**

### Step 4 · LLM 加工（用 prompt.md 完整方法论）

按 prompt 9 步加工 · 产出符合 schema 的 JSON：

> ⚠️ schema 以 `assets/prompt.md` 为唯一权威。okr_view 是 `groups_by_business_module[].items[]` 两层结构，**没有 `krs` 中间层**（每个 item 自带 `kr_tag` / `kr_indicator`，不再嵌一层 KR）。

```json
{
  "review_id": "rv_xxx",
  "doc_meta": {"doc_title": "周报 5/20 - 松果产品运营部", ...},
  "okr_view": {
    "groups_by_business_module": [
      {
        "business_module": "用户增长",
        "icon": "📈",
        "items": [
          {
            "kr_tag": "<KR id · 内部用 · 不展示>",
            "item_title": "用户增长 · 加权拉新 CAC",
            "item_subtitle": "林深 · 信息流 vs 自然量",
            "kr_indicator": "加权 CAC ≤ 12 元",
            "this_week_quote": "信息流渠道 28 元，自然量 3 元",
            "ai_summary": "分端给了但缺加权汇总 · 无法判断是否 ≤12",
            "verdict": "⚠️ 缺汇总",
            "detailed_analysis": {
              "next_action": "补加权 CAC 汇总数",
              "feishu_comment_draft": "@林深 「信息流渠道 28 元，自然量 3 元」OKR 是「加权 CAC ≤ 12 元」呀\n①加权汇总下来多少？还在 12 以内不\n②信息流为啥比自然量贵那么多\n③是不是这周冲量买了一批",
              "comment_id": "c_001"
            },
            "owner_name": "林深"
          }
        ]
      }
    ]
  },
  "special_view": null,
  "person_view": { "groups_by_owner": [...] }
}
```

### Step 5 · 注入 template.html

template.html 是纯静态 HTML，**直接用 Python / shell sed 批量替换**关键字段：

- `{{doc_title}}` → 周报标题
- `{{intro_text}}` → 自我介绍原文
- 表格内每行 cells → JSON 对应字段
- 评论 icon 的 `data-comment` 属性 → feishu_comment_draft 转义后注入

### Step 6 · 输出落盘

存到当前用户的 Downloads 或 ~/obao/output/，文件名格式：

```
obao_review_{date}_{安全文件名}.html
```

### Step 7 · self_check

输出前自己确认：
- [ ] 所有事项都有 ai_callout
- [ ] feishu_comment_draft 长度 >= 80 字（不许敷衍）
- [ ] 各行 owner 是不同的人（不许「@ 全是同一个人」）
- [ ] doc_title / intro_text 不是范本，是用户真实给的内容
- [ ] 抽屉里的「原文」字段确实是用户粘贴的原文（不能漏）
- [ ] **D7 没破**：没给 OKR 的事项，评论里没有任何反推出来的假 KR 数字
- [ ] **检查 Step 8 触发条件**：用户给过飞书 docx / wiki URL 吗？给过就必须执行 Step 8，不许跳过

### Step 8 · Obao 直接发飞书（给了飞书 URL 时**必触发** · 用户不碰命令行）

> **核心原则：发评论是 Obao 的活，不是用户的活。**
> 用户绝不该被要求"复制 lark-cli 命令粘到终端"。lark-cli 是本 skill 的**前置能力**——没装就 Obao 自己装，然后 **Obao 自己调 lark-cli 把评论发出去**。用户只做一个决定：发哪几条。
> （单文件 HTML 预览页没有后端、发不了飞书；真正的发送发生在**当前 Claude Code 会话里**，由 Obao 执行。）

#### 8.0 · 前置：确保 lark-cli 可用（Obao 自己搞定）

1. **有没有飞书 URL？** 用户输入含 `https://[域].feishu.cn/docx/...`、`/wiki/...`、`larksuite.com/docx/...`？
   - 没有 → 跳过 Step 8。
2. **lark-cli 装了没？** 跑 `which lark-cli`：
   - 有 → 进下一步。
   - **没有 → Obao 自己装**：告诉用户一句「检测到没装 lark-cli，我装一下（这是发飞书的前置）」，然后真跑 `npm install -g @larksuite/cli`，装完 `which lark-cli` 复核。
   - 只有在 **npm 都没有 / 装失败（权限等）** 时，才退化为：告知用户手动装一次。
3. **登录态？** 跑一条只读命令探测（如 `lark-cli auth status`）。未登录 → 提示用户用 `!lark-cli auth login` 跑一次授权（登录态是用户级的、需浏览器授权，Obao 不能代登；这是唯一需要用户动手的一步，且一次性）。

#### 8.1 · 只问一个问题：发哪几条（对外动作，必须确认）

发到飞书评论区下属就能看到，是**对外、不可逆**动作，所以发之前**必须**让用户勾选——但这是"确认"，不是"让用户干活"。

用 `AskUserQuestion`（multiSelect=true，每屏 ≤4 条，IM 风预览）：

> "这份周报我整理了 N 条要追问的评论，挑哪几条由我直接发到飞书原周报对应段落？"
> - [选项 1] @林深 · 加权 CAC 汇总下来多少呀？还在 12 以内不
> - [选项 2] @苏野/王越 · 「暂未发现异常」具体到数是多少
> - ...

⛔ **死规矩**：必须问、必须用户勾选后才发。但**绝不**让用户去碰命令行。

#### 8.2 · 为每条提取定位片段 `selection_for_comment`

从**原文截 20-60 字连续片段**，尽量含**独特数字/专名**（避免重复段落定位错）。如锚 1.1 拉新就截「信息流渠道 28 元，自然量 3 元」。作为 `--selection-with-ellipsis` 传入，飞书自动划词定位。找不到独特片段 → 走 `--full-comment`。

#### 8.3 · Obao 自己调 lark-cli 发（dry-run 预检 → 真发，全程 Obao 跑）

对每条勾选的评论，**Obao 用 Bash 执行**（不是给用户命令）：

```bash
# ① 先 dry-run 预检（Obao 自己跑，给用户看一眼请求对不对）
lark-cli drive +add-comment --doc "<url>" \
  --selection-with-ellipsis "<selection>" \
  --content '[{"type":"text","text":"<draft>"}]' --dry-run
# ② 预检无误 → Obao 去掉 --dry-run 真发
lark-cli drive +add-comment --doc "<url>" \
  --selection-with-ellipsis "<selection>" \
  --content '[{"type":"text","text":"<draft>"}]'
```

dry-run 那步如果请求明显有问题（selection 为空、content 转义炸了）→ Obao 自己修，不把锅甩给用户。

#### 8.4 · 报告结果

> ✅ 已替你发 3 条到飞书原周报（@林深 / @苏野 / @何苗）
> ⚠️ 1 条 selection 没匹配上原文，已转全文档评论
> ❌ 1 条 lark-cli 报错：[错误] —— 我重试 / 你看下文档权限

#### 8.5 · 实在装不上时才退化

只有 npm 缺失 / 装不上 / 用户拒绝授权时，才退回"给用户复制好的草稿、自己贴飞书"。这是**退化路径**，不是默认。默认永远是 Obao 直接发。

---

## D1-D7 硬纪律（违反 = 重做）

> 注：本节是 SKILL.md 给的速记口诀；完整判定逻辑以 `assets/prompt.md` 的 D0-D7 死规矩 + A-J 红线为准。两处口径一致。

这是核心 prompt 沉淀的工作纪律：

- **D1 · 不许编**：用户没给的内容，不许用任何范本/虚构填充
- **D2 · 不许偷懒 owner**：5-10 行事项 owner 通常 3-5 个不同的人，去重只剩 1-2 个就是漏读了
- **D3 · 评论必须有锐度**：feishu_comment_draft 不许只说"加油"、必须问到具体数字 / 时间 / 责任
- **D4 · 跨期对照不能空**：有历史就对照、没历史就明说"N/A"，不许编趋势
- **D5 · 不预设结论**：让评论以问号结尾，让 owner 自己回答
- **D6 · 自我介绍是上下文**：用户的分身设定是输入，不是参考——不能改写、不能浓缩，原文整段保留
- **D7 · OKR 数字不许反推**：用户没给 KR 数字，绝对不能从周报里编一个"目标 8%"出来；评论里只能问"这条事项对应哪个 KR 进度？"，不许写假数字

---

## 输出形态硬规矩

- **必须是单文件 HTML**（路人浏览器双击能开）
- **CSS / JS 内联**（不要外部依赖）
- **3 视角表格全要**：OKR / 专项 / 人，**不能省**
- **每个事项**都要有：原文片段 + AI 分析 + 飞书评论草稿 + 下一步动作
- **抽屉交互**：点击事项右侧「💬」icon 弹抽屉，展示完整评论上下文
