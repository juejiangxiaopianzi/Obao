# 飞书原生 OKR 承载页配方（lark-cli / api · 实测可跑）

> 这是【飞书承载页闭环】里"建承载页"的**首选实现**：承载页 = 复制用户的「OKR 进展报告」模板（含飞书原生 OKR 块）+ 把周报进展填进每条 KR 的进展槽 + 追问评论锚到槽块。
> 全程只用 `docs:document:copy` + `docx:document` + 评论三个 scope，**不需要 OKR API / okr scope**。

## 为什么必须复制、不能手写

飞书 docx 的 **markdown/content 创建接口无法生成 OKR 块**——`<okr id="...">`、裸 `<okr></okr>`、`<okr><objective><kr/></objective></okr>` 全部静默丢弃或明报 `UNSUPPORTED_HTML_TAG removed: okr`。原因：飞书导出格式里 OKR 块就是裸 `<okr></okr>` **不带任何 id**，关联存在块的服务端数据里，写属性飞书根本不读。

OKR 块**只能**靠：① 用户在飞书 UI 里 `+` → OKR 手动插；② **复制一份已含 OKR 块的文档**。本配方走 ②。

## 前置：用户得有一份「OKR 进展报告」模板文档

飞书 OKR 产品可一键导出「OKR 进展报告」docx（标题形如「OKR 进展报告 (姓名 0606)」），顶部就是原生 OKR 块（O/KR + 每条 KR 下一个"进展"区）。onboarding 时让用户给这份文档的链接/token，按业务线存进 `profile.md`（字段 `okr_report_token`）。
> 用户没有这份模板 → 退回 SKILL.md 里的【markdown OKR 骨架】写法（KR 标题 + 引用周报进展），不强求原生块。

## docx OKR 块树结构（fetch raw blocks 可见）

```
bt36 okr 根 (okr.okr_id)
  └ bt37 objective (okr_objective.objective_id + content 文字)
      └ bt38 key_result (okr_key_result.content 文字 = 和周报匹配的依据)
          └ bt39 okr_progress
              └ bt2 text × 8   ← 空文本槽，填进展就写这里（填第一个空的）
```

## 步骤

### 1. 复制模板成承载页
```bash
# 拿个目标文件夹（个人云空间根目录）
FOLDER=$(lark-cli api GET "/open-apis/drive/explorer/v2/root_folder/meta" --as user | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")

# 复制（type 固定 docx）
lark-cli api POST "/open-apis/drive/v1/files/<模板token>/copy" --as user \
  --data "{\"name\":\"<业务线> 本周审阅承载页 · <日期>\",\"type\":\"docx\",\"folder_token\":\"$FOLDER\"}"
# → 返回 data.file.token = 承载页 doc token（下称 $CARRIER）
```
复制会把 OKR 块树原样带过来、依旧连用户真实 OKR。

### 2. 解析 KR → 进展槽映射
```bash
python3 assets/okr_blocks.py $CARRIER
# → JSON：每条 KR 的 {kr_block_id, title, owners, progress_block_id, slot_ids[8]}
```

### 3. 把周报进展填进对应 KR 的进展槽
- 用 KR 的 `title`（+ owner）和周报每段语义匹配，决定这段进展属于哪条 KR。
- 取该 KR 第一个空 `slot_ids[0]`，写入：
```bash
lark-cli api PATCH "/open-apis/docx/v1/documents/$CARRIER/blocks/<slot_id>" --as user \
  --data '{"update_text_elements":{"elements":[{"text_run":{"content":"本周进展（摘自周报）：……"}}]}}'
```
- **三种情况都要落**：
  - ① KR 有进展 → 写进展原文摘要（记住它来自原周报哪句 = 源锚句，Stage B 锚回要用）。
  - ② **KR 周报没提 → 不要直接写"无进展"**，先判三态（SKILL.md【KR 周报没提 ≠ 无进展】）：槽里写「✅ 已完成（依据）/ ⏸ 暂停（原因）/ ⚠️ 疑似真停滞」+ 依据；判不出写「周报没提，无法判断完成还是停滞」。**所有 KR 都要落槽，一条不省**（这是核心价值）。
  - ③ 周报有、对不上任何 KR 的游离项 → **每条先过【游离项逐项审】思考链**（自身管理价值 + 与目标关系），按结论放（挤压目标=球、目标外重要=单列追问、暴露遗漏=提示补 KR），再在文档末尾分组列出。⛔ 不无脑堆、不跳过判断。

### 4. 追问评论锚到槽块（块级锚点 · @ 用纯文字 = 不通知 = 草稿态）

> ⚠️ **这是块级锚点评论，不是真划词高亮**（见下方【能力边界 + 验收】）。评论文必须自带原文定位，别指望"划词指出来了"。

```bash
lark-cli drive +add-comment --as user --doc $CARRIER --type docx \
  --block-id <slot_id 或 kr_block_id> \
  --content '[{"type":"text","text":"花名 「定位短语/那个数」 追问1？追问2？"}]'
# 注意：--block-id 与 --selection-with-ellipsis 互斥；锚整块用 --block-id。
# --selection-with-ellipsis 不是真划词：飞书先把文字解析成所在块的 id，仍按 anchor.block_id 建评论。
# 记下 comment_id → 对应哪条 KR + 源锚句 + 评论文（Stage B 读回要用）。
```
- 有进展的 KR → 评论锚到该进展槽 slot_id。
- 周报没提的 KR → 评论锚到 `kr_block_id`，追问按三态（✅完成确认 / ⏸暂停问复工 / ⚠️真停滞问卡哪）。
- 幂等：已评过的块跳过；逐条串行别并发。
- ⛔ **降级阶梯**：`--block-id`（首选·挂到 KR/进展槽块）→ `--selection-with-ellipsis`（仍块级）→ `--full-comment` 全文评论（最糙·全局堆叠·**只在前两档都报错时**用，少量+带定位+告知用户"这是全局评论"）。⛔ 一遇定位接口报错（locate-doc EOF 等）就直接全文评论 = 踩坑。
- ⛔ **拿到 comment_id ≠ 成功**：是否真落上、定位对不对，以用户前端为验收（见下方）。

### 5. 把球交给用户
给 $CARRIER 链接 + 审法：「不动=我直接发 / 删=不发 / 改或回复=你在纠正我」。**说明这是块级锚点评论，请点开承载页确认评论卡都在、定位对**（用户前端确认 = 真正的验收）。

## 能力边界 + 验收（诚实 · 实测确认 · 别越界声称）

实测（lark-cli 1.0.47 `--dry-run`）：创建评论只有一条开放接口 `POST /open-apis/drive/v1/files/{token}/new_comments`，body 里只有 **`anchor.block_id`（块级）**，**没有任何字符范围 / 起止偏移参数**。`--block-id` 直接给块 id；`--selection-with-ellipsis` 先调飞书 `locate-doc` 把文字解析成所在**块**的 id，再照样按 `anchor.block_id` 建。

所以：

- ✅ 能做到：在某个**块**上挂一条评论（飞书前端会在该块位置显示评论卡）。
- ❌ 做不到：把评论高亮钉在**某一句话 / 某个数字**的字符范围上（真划词高亮）。一个块里多句话时，评论指向不到具体那句。
- **结论**：① 评论文**必须自带原文定位**（独特短片段 / 那个数）；② **comment_id 返回 ≠ 成功 ≠ 前端可见**，真正验收是**用户前端**（评论卡片可见 + 能定位到目标文字）；③ 做不到真划词就**老实说**，不伪造成功；④ **绝不擅自把大量评论当正文 PATCH 进承载页**（除非用户明确接受这种交互）。

## Stage B（读回 → 发原周报 → 自学 → 删承载页）
读回承载页评论（`lark-cli drive file.comments` 列），按 comment_id/锚块匹配：还在=认可、被删=跳过、被改/有回复=按纠正重写。认可的发回**原周报**（真 @ 通知，挂回源锚句）。被纠正的沉淀 bad→good 案例。最后删承载页（缺 `space:document:delete` 时改为：留着但标题加「已推送·可删」让用户手删）。

## 验证方式
拿一份你自己飞书 OKR 产品导出的「OKR 进展报告」当模板，按上面 5 步跑一遍：复制 → `okr_blocks.py` 解析 → 往某条 KR 进展槽 PATCH 一句进展 → `+add-comment` 锚到槽块。**验收以你的飞书前端为准**：复制出的文档顶部是活的原生 OKR 控件、进展槽被填上、**评论卡在前端可见且定位到目标块** —— 看到这些才算闭环跑通。⛔ 只拿到 comment_id、没在前端确认评论可见，不算成功。
