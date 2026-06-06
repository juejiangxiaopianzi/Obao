#!/usr/bin/env python3
"""
obao-review · 飞书 OKR 进展报告 块解析助手

用途：把一份「OKR 进展报告」docx（含原生 OKR 块）解析成
      O → KR → 进展槽 的结构，供 skill 把周报进展填进对应 KR 的进展槽、
      并把追问评论锚到槽块上。

依赖：本机已装并登录 lark-cli（user 身份）。

用法：
  python3 okr_blocks.py <doc_token>
输出（JSON 到 stdout）：
  {
    "okr_id": "...",
    "objectives": [
      {
        "objective_id": "...",
        "title": "目标文字",
        "key_results": [
          {
            "kr_block_id": "...",          # KR 块 id（评论可锚这里）
            "title": "KR 文字（用于和周报匹配）",
            "owners": ["花名/被@的人"],     # KR 文字里 @ 到的人
            "progress_block_id": "...",     # 该 KR 下的进展块
            "slot_ids": ["...", "..."]      # 进展块里的空文本槽（按顺序，填第一个空的）
          }
        ]
      }
    ]
  }

block_type 约定：1=page 36=okr根 37=objective 38=key_result 39=okr_progress 2=text
"""
import json
import subprocess
import sys


def fetch_blocks(doc_token):
    items = []
    page_token = None
    while True:
        path = f"/open-apis/docx/v1/documents/{doc_token}/blocks?page_size=500"
        if page_token:
            path += f"&page_token={page_token}"
        out = subprocess.run(
            ["lark-cli", "api", "GET", path, "--as", "user"],
            capture_output=True, text=True,
        )
        d = json.loads(out.stdout)
        if not d.get("ok", d.get("code") == 0):
            sys.stderr.write("fetch blocks failed: " + out.stdout[:500] + "\n")
            sys.exit(1)
        data = d.get("data", {})
        items.extend(data.get("items", []))
        if data.get("has_more") and data.get("page_token"):
            page_token = data["page_token"]
        else:
            break
    return items


def text_of(block, key):
    """提取 okr_objective / okr_key_result 的纯文字 + @到的人名"""
    content = block.get(key, {}).get("content", {})
    els = content.get("elements", [])
    txt = ""
    owners = []
    for e in els:
        if "text_run" in e:
            txt += e["text_run"].get("content", "")
        if "mention_user" in e:
            # mention_user 通常只带 user_id，名字未必在；这里记 user_id 兜底
            uid = e["mention_user"].get("user_id", "")
            if uid:
                owners.append(uid)
    return txt.strip(), owners


def main():
    if len(sys.argv) < 2:
        sys.stderr.write("usage: okr_blocks.py <doc_token>\n")
        sys.exit(1)
    doc = sys.argv[1]
    items = fetch_blocks(doc)
    byid = {b["block_id"]: b for b in items}

    result = {"okr_id": None, "objectives": []}

    def children(bid):
        return byid.get(bid, {}).get("children", []) or []

    # 找 okr 根（bt36）
    okr_root = next((b for b in items if b.get("block_type") == 36), None)
    if not okr_root:
        sys.stderr.write("no okr block (bt36) found — 这份文档不含原生 OKR 块\n")
        print(json.dumps(result, ensure_ascii=False))
        sys.exit(2)
    result["okr_id"] = okr_root.get("okr", {}).get("okr_id")

    def first_progress_and_slots(parent_bid):
        """在 parent 的直接子里找 okr_progress(bt39)，返回 (progress_id, [空文本槽ids])"""
        for cid in children(parent_bid):
            cb = byid.get(cid, {})
            if cb.get("block_type") == 39:
                slots = []
                for sid in children(cid):
                    sb = byid.get(sid, {})
                    if sb.get("block_type") == 2:
                        slots.append(sid)
                return cid, slots
        return None, []

    for oid in children(okr_root["block_id"]):
        ob = byid.get(oid, {})
        if ob.get("block_type") != 37:
            continue
        otitle, _ = text_of(ob, "okr_objective")
        obj = {"objective_id": ob.get("okr_objective", {}).get("objective_id"),
               "title": otitle, "key_results": []}
        for kid in children(oid):
            kb = byid.get(kid, {})
            if kb.get("block_type") != 38:
                continue
            ktitle, owners = text_of(kb, "okr_key_result")
            pid, slots = first_progress_and_slots(kid)
            obj["key_results"].append({
                "kr_block_id": kid,
                "title": ktitle,
                "owners": owners,
                "progress_block_id": pid,
                "slot_ids": slots,
            })
        result["objectives"].append(obj)

    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
