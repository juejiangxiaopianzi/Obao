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

## 输入（**全部缺就问用户 · 严禁用任何兜底范本**）

| 必填 | 字段 | 没提供时怎么办 |
|---|---|---|
| ✅ | 周报原文（markdown / 纯文本） | **必须问用户要** · 不许编 · 不许用范本 |
| ✅ | 用户自我介绍（一段话 · 业务模块 / 下属花名 / 红线 / 关注风格） | **必须问用户要** · 不许默认填任何内容 |
| ✅ | OKR 列表（本季 KR 名 + 当前数字 + 目标数字） | **必须问用户要** · 没有 KR 数字，"评论锐度"无从谈起 |
| ⏳ | 历史周报（跨期对比用） | 没历史就在 trend_4w 字段填 "N/A · 无历史可对照" |

### ⛔ 严禁

- ❌ 用任何「演示范本」自动跑 demo
- ❌ 用户没填自我介绍 → 默认填一段虚构 / 真实内容
- ❌ 用户没给周报 → 编一份周报
- ❌ 用户没给 OKR → **从周报反推 KR 数字**（反推业务模块 OK，反推 KR 数字 = 编 = 砸招牌）

正确做法：

> **缺哪个就问哪个 · 用 AskUserQuestion 工具 · 或直接说**：
> 「我需要你先告诉我以下信息才能跑：
> ① 你的自我介绍（部门 / 业务模块 / 下属 / 红线 一段话）
> ② 这次要审的周报正文
> ③ 你本季 OKR（KR 名字 + 当前进度数字 + 目标数字，比如「DAU 月增长 · 当前 5.2% · 目标 8%」）」

### OKR 处理细则

- 用户**给了 OKR** → 评论里可以引用具体数字、做缺口分析（D3 死规矩才能落实）
- 用户**只给了 KR 名字、没给数字** → **再问一次**「这个 KR 当前进度是多少？目标是多少？」
- 用户**说"没有 OKR / 业务太新没设"** → 接受，但**评论里不许出现任何数字对照**，只追问进度 / 时间 / 责任
- 用户**说"不告诉你 OKR"** → 接受，同上，**不许从周报反推 KR 数字**

⛔ 反推**业务模块**（按事项归类）可以；反推**KR 数字**（"目标是 8%"）= 编造，立刻砸招牌。

---

## 7 步加工流程

### Step 1 · 读资源

读这 2 个文件理解上下文：
- `assets/template.html` ← HTML/CSS 模板（紫色 + 6 列 + 抽屉 · 不要重新发明）
- `assets/prompt.md` ← 完整 SYSTEM_PROMPT（9 步加工 + D1-D6 死规矩 + 3 视角 schema）

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

```json
{
  "review_id": "rv_xxx",
  "doc_meta": {"doc_title": "周报 5/20 - 产品运营部", ...},
  "okr_view": {
    "groups_by_business_module": [
      {
        "module_name": "运营增长",
        "krs": [
          {
            "kr_title": "DAU 月增长 8%",
            "items": [
              {
                "item_title": "5月增长活动复盘",
                "item_subtitle": "owner: 张三 · 进度 70%",
                "raw_text": "本周完成增长活动复盘...",
                "comments": {
                  "ai_callout": "增长率仅 5.2%，与目标 8% 有缺口...",
                  "feishu_comment_draft": "@张三 5 月增长 5.2% vs 目标 8%...\n①缺口主要在哪个渠道？\n②6 月有没有补救动作？\n③ROI 拐点是否还在？\n④对 Q3 目标有没有影响？",
                  "next_action": "等 6 月 5 日前给出补救计划"
                },
                "owner_name": "张三"
              }
            ]
          }
        ]
      }
    ]
  },
  "topic_view": [...],
  "people_view": [...]
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
- [ ] **检查 Step 8 触发条件**：用户给过飞书 docx / wiki URL 吗？给过就必须执行 Step 8，不许跳过

### Step 8 · 飞书评论同步（用户给了飞书 URL 时**必触发** · 不许跳）

**触发判断（按顺序执行）**：

1. 用户的输入里**是否**含飞书文档 URL 或 wiki URL？
   - 飞书 URL 形如：`https://[公司域].feishu.cn/docx/...`、`https://[域].feishu.cn/wiki/...`、`https://[域].larksuite.com/docx/...`
   - 如果**有 → 进入第 2 步**
   - 如果**没有 → 跳过 Step 8**，HTML 完成即可结束

2. 跑 `which lark-cli` 探测本机是否装了飞书 CLI：
   - **有 lark-cli → 进入第 3 步**
   - **没 lark-cli** → 友好告知用户：「检测到你给了飞书文档 URL，但本机没装 lark-cli。装上之后可以让我帮你一键发评论。装法：`npm install -g @larksuiteoapi/lark-cli`」然后结束

3. **强制询问用户**（不许默认跳过，必须用 AskUserQuestion 或直接发问）：

   > "你给了飞书文档 URL + 本机有 lark-cli。要不要我把 N 条评论草稿**逐条**发到原文档对应段落？（你可以选哪几条要发）"

   ⛔ **死规矩**：上面这句话是**必须问的**。即使你觉得用户可能不想发，也要让用户自己拒绝，不许 Agent 替用户决定跳过。

如果用户 yes：

#### 8.1 · 让 LLM 为每条评论提取「定位片段」

在 Step 4 加工时，已经为每条评论生成了 `feishu_comment_draft`，但还需要一个 `selection_for_comment` 字段：

- 从原文截取 **20-60 字的连续片段**，最好包含一个**独特数字或专有名词**（避免文档里有重复段落）
- 这个片段将作为 `--selection-with-ellipsis` 传给 lark-cli，飞书会自动定位到这个片段并加局部评论
- 如果实在找不到独特片段（比如评论是针对整体的），就走全文档评论（`--full-comment`）

#### 8.2 · 让用户逐条勾选

用 `AskUserQuestion` 工具，**每次最多 4 条评论一起列**（小红书风格简短预览）：

> "找到 N 条评论草稿。哪几条要发到飞书？"
> - [选项 1] @张三 · 5 月增长 5.2% vs 目标 8% · 缺口在哪个渠道...
> - [选项 2] @李四 · Q3 大盘对公口径不一致...
> - ...

**multiSelect=true**。用户勾选哪几条就发哪几条。

#### 8.3 · 调 lark-cli 发评论

对每条勾选的评论：

```bash
lark-cli drive +add-comment \
  --doc "<doc_url_or_token>" \
  --selection-with-ellipsis "<selection_for_comment>" \
  --content '[{"type":"text","text":"<feishu_comment_draft>"}]' \
  --dry-run
```

**强制先 dry-run** 一次给用户看请求长啥样，确认后再去掉 `--dry-run` 真发。

#### 8.4 · 报告结果

发完报告：

> ✅ 已发 3 条评论到飞书 docx
> ⚠️ 1 条 selection 没匹配上原文（已转为全文档评论）
> ❌ 1 条 lark-cli 返回错误：[错误信息]

#### 8.5 · 没装 lark-cli 时

直接跳过 Step 8。HTML 文件里的评论草稿用户自己复制粘贴。**不要**提示"建议你装 lark-cli"——开源用户可能根本不用飞书。

---

## D1-D6 硬纪律（违反 = 重做）

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
