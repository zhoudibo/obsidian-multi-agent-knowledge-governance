#!/usr/bin/env python3
"""断链扫描：找出指向不存在文件的 wikilink。

用法：
    python3 check_links.py <vault-root> [--json]

与 check_orphans.py 的区别：
    孤儿 = 文件存在但没人引用它
    断链 = 引用指向的文件不存在

典型成因：批量移动文件时只改了路径前缀，没改 wikilink 内容。
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
    out = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS and not d.startswith(".")]
        for fn in filenames:
            if fn.lower().endswith(".md"):
                out.append(os.path.relpath(os.path.join(dirpath, fn), root))
    return out


def resolve(target, root, by_name, by_path):
    """尝试解析一个 wikilink 目标；返回 (是否可解析, 解析方式)"""
    t = target.strip()
    if not t:
        return True, "empty"

    # 1) 完整相对路径
    cand = os.path.join(root, t)
    if os.path.isfile(cand):
        return True, "path"
    if os.path.isfile(cand + ".md"):
        return True, "path+md"

    # 2) 相对路径（相对 vault 根）
    rel = t if t.endswith(".md") else t + ".md"
    if rel in by_path:
        return True, "relpath"

    # 3) 纯文件名（宽松：只要库里有同名文件就算可解析）
    base = os.path.splitext(os.path.basename(t))[0]
    if base in by_name:
        return True, "basename"

    return False, "unresolved"


def main():
    ap = argparse.ArgumentParser(description="扫描知识库断链")
    ap.add_argument("vault", help="vault 根目录")
    ap.add_argument("--json", action="store_true", help="输出 JSON")
    ap.add_argument("--quiet", action="store_true", help="只输出计数")
    args = ap.parse_args()

    root = os.path.abspath(args.vault)
    if not os.path.isdir(root):
        print(f"错误：目录不存在 {root}", file=sys.stderr)
        return 2

    files = collect_md(root)
    by_name = {os.path.splitext(os.path.basename(f))[0] for f in files}
    by_path = set(files) | {f[:-3] for f in files}

    broken = []
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
            ok, how = resolve(target, root, by_name, by_path)
            if not ok:
                broken.append({"file": rel, "target": target})

    if args.json:
        print(json.dumps({
            "root": root,
            "total_files": len(files),
            "broken_count": len(broken),
            "broken": broken,
        }, ensure_ascii=False, indent=2))
        return 0

    if args.quiet:
        print(len(broken))
        return 0

    print(f"扫描 {len(files)} 个 md 文件（根目录 {root}）")
    print()
    if not broken:
        print("✅ 断链数 = 0")
        return 0
    print(f"❌ 断链 ({len(broken)})：")
    for b in broken:
        print(f"  {b['file']}")
        print(f"    → [[{b['target']}]]")
    print()
    print("修复：批量移动文件后，用脚本替换 wikilink 前缀，再重跑本脚本。")
    print("参考 references/indexing-and-links.md §3。")
    return 1


if __name__ == "__main__":
    sys.exit(main())
