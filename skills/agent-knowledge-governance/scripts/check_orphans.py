#!/usr/bin/env python3
"""孤儿文件扫描：找出没有任何入链的 Markdown 文件。

用法：
    python3 check_orphans.py <vault-root> [--json] [--include-hidden]

原理：
    1. 收集所有 .md 文件（排除 .obsidian / .git / node_modules 等）
    2. 扫描所有文件里的 [[wikilink]] 目标，得到「被引用集合」
    3. 被引用集合的补集 = 孤儿

注意：
    - wikilink 目标可能是「文件名」「相对路径」或「路径#锚点」「路径|别名」
    - 这里做的是**宽松匹配**：只要文件名能对上就算有入链
    - 因此结果偏保守（宁可少报），避免误报淹没真问题
"""
import argparse
import json
import os
import re
import sys

SKIP_DIRS = {
    ".obsidian", ".git", ".trash", "node_modules", "__pycache__",
    ".venv", "venv", ".idea", ".vscode", "site-packages", ".pytest_cache",
}
WIKILINK = re.compile(r"\[\[([^\]]+?)(?:[#|][^\]]*)?\]\]")
EXTERNAL = re.compile(r"^(https?|mailto):", re.I)


def collect_md(root):
    """收集所有 md 文件（相对路径）"""
    out = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS and not d.startswith(".")]
        for fn in filenames:
            if fn.lower().endswith(".md"):
                full = os.path.join(dirpath, fn)
                rel = os.path.relpath(full, root)
                out.append(rel)
    return out


def build_link_index(files, root):
    """返回 {被引用的目标名集合, 被引用的相对路径集合}"""
    by_name = set()
    by_path = set()
    for rel in files:
        by_name.add(os.path.splitext(os.path.basename(rel))[0])
        by_path.add(rel[:-3] if rel.endswith(".md") else rel)
        by_path.add(rel)

    referenced_names = set()
    referenced_paths = set()
    for rel in files:
        try:
            with open(os.path.join(root, rel), encoding="utf-8", errors="ignore") as f:
                text = f.read()
        except OSError:
            continue
        for m in WIKILINK.finditer(text):
            target = m.group(1).strip()
            if not target or EXTERNAL.match(target):
                continue
            referenced_names.add(os.path.splitext(os.path.basename(target))[0])
            referenced_paths.add(target)
    return referenced_names, referenced_paths


def is_orphan(rel, ref_names, ref_paths):
    base = os.path.splitext(os.path.basename(rel))[0]
    stem = rel[:-3] if rel.endswith(".md") else rel
    # 文件名被引用 → 有入链
    if base in ref_names:
        return False
    # 相对路径被引用 → 有入链
    if stem in ref_paths or rel in ref_paths:
        return False
    return True


def main():
    ap = argparse.ArgumentParser(description="扫描知识库孤儿文件")
    ap.add_argument("vault", help="vault 根目录")
    ap.add_argument("--json", action="store_true", help="输出 JSON")
    ap.add_argument("--quiet", action="store_true", help="只输出计数")
    args = ap.parse_args()

    root = os.path.abspath(args.vault)
    if not os.path.isdir(root):
        print(f"错误：目录不存在 {root}", file=sys.stderr)
        return 2

    files = collect_md(root)
    ref_names, ref_paths = build_link_index(files, root)
    orphans = [f for f in files if is_orphan(f, ref_names, ref_paths)]

    if args.json:
        print(json.dumps({
            "root": root,
            "total": len(files),
            "orphan_count": len(orphans),
            "orphans": orphans,
        }, ensure_ascii=False, indent=2))
        return 0

    if args.quiet:
        print(len(orphans))
        return 0

    print(f"扫描 {len(files)} 个 md 文件（根目录 {root}）")
    print(f"入链索引：{len(ref_names)} 个唯一目标名 / {len(ref_paths)} 条路径引用")
    print()
    if not orphans:
        print(f"✅ 孤儿文件数 = 0")
        return 0
    print(f"❌ 孤儿文件 ({len(orphans)})：")
    for f in sorted(orphans):
        print(f"  {f}")
    print()
    print("处置方式（只有三种正确做法）：")
    print("  1. 有价值但没挂上 → 在**已有的**项目索引里加 wikilink")
    print("  2. 与某张主卡重复   → 合并进主卡，旧文件进归档区")
    print("  3. 确实是废弃草稿   → 移出 vault（git 里有历史）")
    return 1


if __name__ == "__main__":
    sys.exit(main())
