# Obao · 周报深度审阅 Skill

> 让 LLM 把每周报追问到底，把可以丢给团队的飞书评论先帮你草拟好。

**Obao** 是一个 Claude Code Skill。装上以后，你把一份周报 + 一段自我介绍丢给 Claude，它会输出一份**本地能直接打开的 HTML 文件** —— 像一个高级助理看完周报、写好了所有要追问的问题、把可以贴评论的话先草拟好。

中文叫 **O包**。

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
│  业务线 │ KR    │ 事项     │ owner │ 💬  │
│  增长   │ DAU+8%│ 5月复盘  │ 张三   │ 💬  │
│  ...                                      │
└──────────────────────────────────────────┘
       ↓ 点 💬
┌────────── 抽屉 ──────────────────────────┐
│  原文片段 → AI 分析 → 评论草稿           │
│                                          │
│  @张三 5月增长 5.2% vs 目标 8%           │
│  ① 缺口主要在哪个渠道？                  │
│  ② 6 月有没有补救动作？                  │
│  ③ ROI 拐点是否还在？                    │
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

- 不要把真实公司数据 PR 进示例
- 改 prompt 时保留 D1-D6 硬纪律的精神（具体话术可以改）
- 新增 skill 走 `skills/your-skill-name/` 子目录

---

## License

MIT
