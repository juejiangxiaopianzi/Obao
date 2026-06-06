# Obao · 周报深度审阅 Skill

> 让 LLM 把每份周报追问到底，把该丢给团队的追问，直接发回原周报。

**Obao** 是给 Claude Code / OpenClaw / Cursor / Codex 用的 skill。装上以后，你把一份周报（+ 一段自我介绍）丢给它，它像一个高级助理看完周报、写好所有要追问的问题、@ 到对的人。中文叫 **O包**。

## 就一个 skill：`obao-review`（自己适应环境）

不用记好几个、不用选。**审周报就这一个 skill**，它开局自己探测能怎么碰飞书：

| 优先级 | 你的环境 | 走哪条 |
|---|---|---|
| ① | 飞书里的智能体（有原生云文档/评论工具） | **飞书副本闭环**（用原生工具） |
| ② | 飞书外的 agent（Claude Code 等，装了 lark-cli 且登录） | **飞书副本闭环**（用 lark-cli） |
| ③ | 没飞书 / 没工具 | **本地 HTML 审阅页**（兜底） |

**飞书副本闭环**（①②共用）：复制一份周报副本当承载页 → 把追问标成文档评论 → 你在副本上**改/删/回复**就是纠正 → 你说「可以推送了」→ 把认可的发回**原周报**（真 @）+ 把纠正沉淀成 bad→good 案例（越用越准）+ 删副本。

> 为什么副本而不是本地 HTML 当主力？本地 HTML 是**死文件**——你改了 agent 看不见、回路不通；飞书文档是**双向**的，纠正才能真反哺。HTML 只在没飞书时兜底。

---

## 它解决什么问题

每周读下属周报，你大概有 3 种状态：

| 状态 | 大多数人怎么处理 |
|---|---|
| 没时间细看 | 扫一眼，回个"收到"或"辛苦了" |
| 细看了，但写评论太累 | 心里有问号，但不想敲字，下次开会再说 |
| 真细看 + 真写评论 | 一份周报花 1 小时，每周耗光精力 |

Obao 干的事：**Claude 替你完成 3 的工作量，10 分钟以内**。

输出长这样：

```
┌──────────────────────────────────────────┐
│  周报 5/20 审阅 · 产品运营部             │
├──────────────────────────────────────────┤
│  [OKR 视角]  [专项视角]  [人视角]        │
├──────────────────────────────────────────┤
│  业务线 │ KR      │ 事项     │ owner │ 💬│
│  增长   │ CAC≤12元│ 拉新CAC  │ 林深   │ 💬│
│  ...                                      │
└──────────────────────────────────────────┘
       ↓ 点 💬
┌────────── 抽屉 ──────────────────────────┐
│  原文片段 → AI 分析 → 评论草稿           │
│                                          │
│  @林深 拉新 CAC 信息流 28 / 自然量 3 呀   │
│  ① 加权汇总下来多少，还在 12 以内不？     │
│  ② 信息流为啥比自然量贵这么多？          │
│  ③ 这批量的次留怎么样？                  │
└──────────────────────────────────────────┘
```

---

## 快速开始

### 前置条件

- macOS / Linux
- 至少装好下面**任一**支持的 Agent：
  - [Claude Code](https://claude.com/claude-code)
  - [Cursor](https://cursor.com)
  - [Codex CLI](https://github.com/openai/codex)
  - [OpenClaw](https://openclaw.ai) — Peter Steinberger 的开源个人 AI 网关，覆盖飞书/微信/Slack/Telegram 等多通道

### 安装（统一一条命令）

```bash
git clone https://github.com/juejiangxiaopianzi/Obao.git obao
cd obao
./install.sh
```

`install.sh` 会自动检测你本机用哪些 Agent，把 skill 装到对应目录：

| Agent | 安装路径 | 检测条件 |
|---|---|---|
| Claude Code | `~/.claude/skills/obao-review/` | 存在 `~/.claude/` |
| Cursor | `~/.cursor/skills/obao-review/` | 存在 `~/.cursor/` |
| Codex CLI | `~/.codex/skills/obao-review/` | 存在 `~/.codex/` |
| OpenClaw | `~/.openclaw/skills/obao-review/` | 存在 `~/.openclaw/` |
| 通用 Agent 池 | `~/.agents/skills/obao-review/` | 存在 `~/.agents/` |

**多个 Agent 都装了？** `install.sh` 会同时装到对应目录，你用哪个 Agent 都能直接触发。
**只装了其中一个？** 没装的会自动跳过，输出 `⊘` 标记。
**已存在同名 skill？** 直接覆盖（不再保留 backup —— 留 backup 会污染 Agent 的 skill 列表）。

### 使用 · 按你用的 Agent 选

通用流程：打开你的 Agent，**输入「帮我审一下这份周报」**，Agent 会自动加载 obao-review skill 并向你要 2 件输入：
- 周报正文（markdown / 纯文本）
- 自我介绍（部门 / 业务模块 / 下属花名 / 红线 · 一段话）

下面是各 Agent 的具体启动方式 ↓

---

#### 🔵 Claude Code 用户

```bash
# 启动（在任意终端）
claude
```

直接对话框输入：

```
帮我审一下这份周报
```

如果 skill 没自动加载，重启 Claude Code 一次（关掉再开），让它重新扫 `~/.claude/skills/` 目录。

---

#### 🟣 Cursor 用户

1. 打开 Cursor，按 `⌘ + L` 打开 Chat 面板
2. 在 Chat 输入：

   ```
   帮我审一下这份周报
   ```

3. Cursor 会从 `~/.cursor/skills/obao-review/` 加载 skill 并执行

> ⚠️ **触发词冲突提醒**
> 如果你以前在 `~/.cursor/skills/` 装过别的同名 obao skill（比如公司内部版的 `name: obao`），可能跟本 skill 触发词重叠。
> 本 skill 的 frontmatter `name` 是 `obao-review`，**不**是 `obao`，触发词主要靠「**审周报 / 深度审阅 / workpad / 帮我看下这份周报**」。
> 跟「O宝 / 欧宝 / 诊断对齐」这类公司 obao 触发词错开了。
> 如果还是冲突，把那个老 skill 改名或删掉就行：`mv ~/.cursor/skills/obao{,.old}`

---

#### 🟢 Codex CLI 用户

如果你还没装 Codex CLI：

```bash
# 用 npm 装（需要 Node ≥ 18）
npm install -g @openai/codex
# 或访问 https://github.com/openai/codex 看官方安装说明
```

跑 Obao install.sh 后，skill 已落到 `~/.codex/skills/obao-review/`。启动：

```bash
codex
```

在 codex 交互界面输入：

```
帮我审一下这份周报
```

Codex 会按 `~/.codex/skills/obao-review/SKILL.md` 的流程引导你。

> 💡 Codex CLI 跑 Step 8 飞书一键评论：和其他 Agent 一样，需要本机装 lark-cli。

---

#### 🦞 OpenClaw 用户

[OpenClaw](https://openclaw.ai) 是 Peter Steinberger 的开源个人 AI 网关，把飞书 / 微信 / Slack / Telegram / Discord 等通道连接到底层 AI agent。

如果你还没装 OpenClaw：

```bash
brew install openclaw/tap/openclaw
# 或访问 https://openclaw.ai 看官方安装说明
```

跑 Obao install.sh 后，skill 已落到 `~/.openclaw/skills/obao-review/`（这是 OpenClaw 默认扫的 skill 路径之一）。

**在 OpenClaw 里触发的方式**（任选一种）：

1. **clawbot CLI**：直接命令行跑
   ```bash
   clawbot run --skill obao-review
   ```

2. **聊天通道**（绑定后）：在飞书 / Slack / Telegram 等里 @ 你的 OpenClaw bot：
   ```
   @bot 帮我审一下这份周报
   ```

3. **Workspace 级覆盖**：项目目录里建 `<workspace>/skills/obao-review/`，会优先于 `~/.openclaw/skills/` 加载

> 💡 OpenClaw 的 skill 加载优先级（高 → 低）：
> `<workspace>/skills` → `<workspace>/.agents/skills` → `~/.agents/skills` → `~/.openclaw/skills` → 内置
>
> `install.sh` 默认装到 `~/.openclaw/skills/` 和 `~/.agents/skills/` 两个位置，都是常驻可用。

---

### 第一次没头绪？用项目里的示例

```bash
cat examples/sample-self-intro.md         # 一段虚构的产品经理自我介绍
cat examples/sample-weekly-report.md      # 一份虚构的 5/20 周报
```

把这两份内容贴给 Agent，让它跑一次 `obao-review`。等 30 秒，你会拿到一份本地 HTML 文件，浏览器打开就能看。

示例渲染效果：[`examples/sample-output.html`](./examples/sample-output.html)（仓库里直接预览）

---

## 核心设计：6 个硬纪律（D1-D6）

Obao 的 prompt 不是"建议"，是**死规矩**。这是我自己用了 3 个月，反复 callout 失败再迭代出来的：

| | 规矩 | 为什么 |
|---|---|---|
| **D1** | 不许编 | 用户没给的内容，不许用任何范本/虚构填充 |
| **D2** | 不许偷懒 owner | 5-10 行事项 owner 通常是 3-5 个不同的人，去重只剩 1-2 个就是漏读了 |
| **D3** | 评论必须有锐度 | 不许只说"加油"，必须问到具体数字 / 时间 / 责任 |
| **D4** | 跨期对照不能空 | 有历史就对照、没历史就明说"N/A"，不许编趋势 |
| **D5** | 不预设结论 | 让评论以问号结尾，让 owner 自己回答 |
| **D6** | 自我介绍是上下文 | 用户的分身设定原文整段保留，不能改写、不能浓缩 |

完整方法论看 [`skill/assets/prompt.md`](./skill/assets/prompt.md)（17K 字，9 步加工流程）。

---

## 设计思路

### 为什么是 Claude Skill 而不是网页/App？

- **数据不离开你的电脑** —— 周报 / 下属名 / OKR 都是敏感的，Obao 跑在你本地 Claude 里
- **你可以自己改 prompt** —— 不喜欢评论语气？打开 `prompt.md` 改一行就行
- **天然集成你的工作流** —— 你可能已经用 Claude Code 写代码 / 整理材料，这只是多一个 skill

### 为什么输出是 HTML？

- **可分享给团队**：发一个文件，对方浏览器直接开，不用装东西
- **可截图发飞书**：3 视角表格 + 抽屉，截图就是天然的审阅意见
- **可保留追溯**：每周一份 HTML，自己的"管理日志"

---

## 与同类工具的区别

| | Obao | 通用 LLM 对话 | 商业 SaaS（如 [...]）|
|---|---|---|---|
| 数据隐私 | 本地 | 看你用哪个 | 全在云端 |
| 评论质量 | 6 条死规矩约束 | 飘忽 | 模板化 |
| 学习成本 | 一份自我介绍 | 每次重新解释上下文 | 配置半天 |
| 价格 | 免费 | 看你用哪个 | 通常 ¥500+/月 |
| 二次开发 | 改 markdown 就行 | 不行 | 不行 |

---

## 路线图

| 状态 | 功能 |
|---|---|
| ✅ | 单份周报 → HTML 审阅 |
| ✅ | 3 视角（OKR / 专项 / 人）+ 抽屉 + 评论草稿 |
| 🚧 | 跨周对照（自动 diff 上一周报）|
| 🚧 | 飞书评论一键同步（OAuth）|
| 🚧 | 多周 trend 视图 |
| 💡 | 团队多人协作版（私有部署） |

---

## 贡献

欢迎 PR 改 prompt、template、新增可选 skill 模块。注意：

- 不要把真实公司数据 PR 进示例（示例一律用虚构的「松果」App 数据）
- 改 prompt 时保留 D1-D7 硬纪律的精神（具体话术可以改）
- 新增 skill 走 `skills/your-skill-name/` 子目录

---

## 更新日志

### v0.6.0（2026-06）
- **三合一**：把 `obao-aily-review` / `obao-feishu-loop` / `obao-review` 收成**一个 `obao-review`**。方法论是一套，"用什么方式碰飞书"由 skill **开局自己探测**（飞书原生工具 → lark-cli → HTML 兜底），不再分成几个 skill、不再有触发词打架和选错的问题。

### v0.5.0（2026-06）
- **新增 `obao-aily-review`**：给**飞书 aily 智能体**用的周报审阅闭环，全程用 aily **内置的飞书云文档/评论/任务工具**——零 lark-cli、不新建应用、不要求分享文档、不让用户跑终端命令。飞书里的智能体本就该用自己的原生工具。
- 同一套方法论（审 → 副本承载 → 评论纠正 → 推回原周报 → 案例库自学）现有三种实现：飞书里的 agent 用原生工具、飞书外的 agent 用 lark-cli、没飞书的退 HTML。

### v0.4.0（2026-06）
- **新主线 `obao-feishu-loop`**：完全基于飞书文档的审阅闭环。复制周报副本当承载页 → 追问做成划词评论（@ 只写名字不通知人）→ 你在副本上改/删/回复 = 纠正 → 「可以推送了」→ 发回原周报（真 @）+ 把纠正沉淀成 **bad→good 案例库** + **自动删副本**。
- **解决 HTML 死文件问题**：本地 HTML 你改了 agent 看不见；飞书副本双向可读回，纠正才能真反哺。
- **案例库自学**（`~/.obao-review/corrections.md`）：每被纠正一次沉淀一个「❌bad 问法 → ✅good 问法 + 触发场景 + 你真正关心」，下次开局加载、主动套用，越用越准；评论里只放问题、不带 Obao 自述。
- 仓库改为多 skill 结构 `skills/{obao-feishu-loop, obao-review}`，`install.sh` 一次装两个。`obao-review`（HTML）降级为无飞书兜底。

### v0.3.0（2026-06）
- **交互结构重做**：顶部总判断卡 + 周报原文为主体（**选中即可划词评论**）+ 可切「按人 / 按 KR」卡片汇总。退役旧的三表 + 抽屉。
- **PIA 风视觉**：Apple/system-blue 风（白底 + slate + 蓝），零装饰 emoji，状态用「色点 + 文字」胶囊。
- **诚实化交互**：删掉假的「已推 / 撤回」按钮；评论草稿 @ 可改、可编辑；不再让用户复制命令。
- **Obao 直接发飞书**：`lark-cli` 是前置能力，没装 Obao 自己装，并**直接调它发评论**（@ 到人、锚定原文），用户不碰命令行。
- **「教 Obao」真落盘**：纠正 append 到本地 `~/.obao-review/corrections.md`，开局必读，下次不再犯（不再写浏览器 localStorage）。

### v0.2.0（2026-06）
- **两条铁律**：评论一律「化词评论」（口语 IM 风 / 原文划词 / 拒公文体）；@ 谁全部从文档自动识别（花名册只补真名、不做白名单）。
- **定位坐实**：Obao = 带着你的立场和红线替你追问的私人参谋；护城河 = 本人立场审 + D1-D7 追问纪律 + 本地不上云。
- **分身 onboarding 重设计**：只收飞书拿不到的三样为 MVP（怎么说话 / 被什么坑过 / 什么板只有你拍），全程零填表、边用边长。
- **两档架构**：丝滑档（无 OKR 也能跑，默认入口）/ 准确档（强制分身 + 自检），是漏斗不是妥协。
- **全量脱敏**：所有示例换成虚构「松果」App，修复文档漂移（D1-D7 / schema / lark-cli 包名）。

---

## License

MIT
