<div align="center">

# Obsidian Multi-Agent Knowledge Governance

# Multi-Agent Collaboration × Obsidian Knowledge Base Governance Skill Pack

**Run multiple AI agents against one shared Markdown knowledge base without losing artifacts, breaking links, repeating mistakes, or claiming "done" without evidence.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Python](https://img.shields.io/badge/Python-3.8%2B-blue.svg)](https://www.python.org/)
[![Bash](https://img.shields.io/badge/Bash-4%2B-green.svg)](https://www.gnu.org/software/bash/)
[![Zero Dependencies](https://img.shields.io/badge/dependencies-none-brightgreen.svg)](.)
[![Agents](https://img.shields.io/badge/agents-Claude%20Code%20%7C%20Codex%20%7C%20Cursor%20%7C%20Hermes%20%7C%20Trae-blueviolet.svg)](.)

[中文](#中文) · [English](#english) · [Install](#install) · [Core Mechanisms](#core-mechanisms) · [Pitfalls](#real-world-pitfalls)

</div>

---

## English

### What is this

A **reusable methodology + three zero-dependency scripts** for running multiple AI agents against
one shared Markdown knowledge base (Obsidian or plain files).

| | |
|---|---|
| **Methodology** | Five-layer truth source · artifact classification · write boundaries · index conventions · evidence-before-done · feedback-to-rule loop |
| **Scripts** | 15-item quality gate · orphan scanner · broken-link scanner |
| **Templates** | Knowledge card · project log · decision card · feedback card · evolution proposal · agent boundary file |

**No cloud services. No data upload. No extra packages** — Bash + Python standard library only.

---

### The five pain points it solves

When several AI agents work together, the usual failures aren't "the AI can't do it" —
they're **unmanaged collaboration**:

| Pain | Symptom | Mechanism |
|---|---|---|
| 🧠 **Experience doesn't transfer** | Three agents hit the same bug on the same class of task | Reflow protocol: distill → load → backlink → answer with citation |
| 📦 **Artifacts scatter** | Generated files drift everywhere; orphan nodes pollute the graph | L1/L2/L3 classification + mandatory archiving + orphan-zero gate |
| 🔗 **Index drifts from reality** | Index links a deleted file; new file never registered | Index conventions + broken-link scan + frontmatter contract |
| ✅ **"It's done" without evidence** | A subagent reports completion; the work never happened | Five-state handoff separation + three conditions for valid evidence |
| 🔄 **One complaint rewrites global rules** | Rule set bloats into self-contradictory constraints | Four-step loop: cluster → version → approve → compare |

---

### Core mechanisms

#### 1. Five-layer truth source

A library shared by multiple agents must separate **what may change from what may not**:

| Layer | Role | Write authority | Mutability |
|:--:|---|---|---|
| **00** | Resource layer · raw evidence | 🔒 **read-only** | 🚫 nobody overwrites it |
| **01** | Topic wiki · stable knowledge | the agent that produced the card | 🔄 evolves without overwriting (version+1) |
| **02** | Project library · work in progress | project owner | ✏️ actively mutable |
| **03** | Output library · shipped artifacts | project owner | ✏️ archived by batch |
| **04** | System maintenance · indexes & rules | 👤 **single writer** | 🔄 aggregated by the index owner |

> You do **not** need to adopt these directory names — what matters is separating
> responsibility from write authority.
> [Mapping guide →](skills/agent-knowledge-governance/references/five-layer-truth-source.md)

#### 2. Artifact classification (L1 / L2 / L3)

Criteria are written as **mechanically executable rules**, not "I think this matters":

| Tier | Definition | Into the library? |
|---|---|---|
| **L1 final artifact** | Delivered, reusable | ✅ required |
| **L2 process artifact** | Intermediate, traceable | ⚠️ selective |
| **L3 temporary** | Debug output / cache / scratch | ❌ never |

#### 3. Five-state handoff separation

Separates *"the executor said it's done"* from *"the receiver personally verified it"*:

```
pending → accepted → received → verified
              ↓
           returned
```

**Three anti-patterns, written into the spec:**

- **A process ending ≠ the result arriving** — go look where the output belongs
- **The executor's own report ≠ independent verification** — it's a lead, not evidence
- **A new estimate ≠ a rescheduled commitment** — keep the original promise intact

#### 4. Feedback → rule, in four steps

> **Except for factual errors and security issues, a single piece of feedback must never
> change a global rule.** It goes through cluster → version → approve → compare.

One-off feedback is only recorded. Two or more similar reports (or hard result data)
trigger a proposal. Changing a global rule requires **a rollback plan** and **human approval**.

---

### Install

```bash
git clone https://github.com/zhoudibo/obsidian-multi-agent-knowledge-governance.git

# As a skill (Claude Code / Codex / Cursor / Hermes / Trae / WorkBuddy)
cp -R obsidian-multi-agent-knowledge-governance/skills/agent-knowledge-governance \
      ~/.claude/skills/

# Or just the scripts
cp obsidian-multi-agent-knowledge-governance/skills/agent-knowledge-governance/scripts/* \
   ~/.local/bin/
```

### Usage

```bash
# 15-item quality gate — 0 FAIL is the release threshold
bash quality_gate.sh /path/to/vault [agent-root]

# Files nobody links to (graph orphans)
python3 check_orphans.py /path/to/vault

# Links pointing at files that don't exist
python3 check_links.py /path/to/vault
```

> ⚠️ **Discipline**: the first run will always report FAIL/WARN. **List the concrete missing
> files first**, then chase 0 WARN. Don't write a "perfect script" and then run it.

---

### Real-world pitfalls

Every entry below came from an actual failure — rules tell you *what to do*,
pitfalls tell you *where it breaks*:

| Symptom | Cause | Fix |
|---|---|---|
| File archived but absent from the index | **Two same-named root directories** in the vault; the agent picked the wrong branch | Check the sync protocol before writing; pin absolute paths in `AGENTS.md` |
| Graph full of isolated dots | New files never linked from an existing index | Archive **must** add a wikilink to an **existing** index; standalone index files are forbidden |
| Index link opens a blank page | Bulk `mv` without rewriting wikilink prefixes | Script the prefix rewrite → broken-link scan → orphan scan → gate |
| "Archived" but the file isn't there | Trusted a subagent's self-report | **`ls` the expected path**; `mv` immediately if misplaced |
| One complaint rewrote a global rule | Skipped clustering | Run cluster → version → approve → compare |
| Test failed — code bug or missing env? | Conflated the two | `No such filter` / `command not found` = **missing env (fixable)**; assertion failure = **real defect** |
| A bulk regex edit corrupted 28 documents | Regex can't understand nested markup | **Use a DOM parser for structural edits**; regex only to locate |
| Output file count lower than expected | Source dir already had same-named outputs | Quantify with **set difference**: `src - out` / `out - src` |
| Downloaded binary won't run | Release ships arm64 only; this machine is x86_64 | Check `uname -m` first; scroll back through historical releases |
| macOS blocks the downloaded program | quarantine attribute | `xattr -cr` + `codesign --force --deep --sign -` |
| `./tool --help` prints nothing and looks broken | Pipe buffering | Run it without a pipe; trust `file` and the exit code |

Full list: [`references/pitfalls.md`](skills/agent-knowledge-governance/references/pitfalls.md)

---

### Design principles

1. **Write boundaries over good intentions** — who may write where is explicit, never implied
2. **Single writer for central indexes** — concurrency on one file guarantees loss
3. **Classify, don't judge** — artifact levels are mechanical rules, not taste
4. **Evidence, not reports** — the executor's own report is a lead, never evidence
5. **One complaint changes nothing** — global rules need clustering, approval, and rollback
6. **Metrics over vibes** — orphan count 0, links resolve, gate 0 FAIL

---

### Repository layout

```
obsidian-multi-agent-knowledge-governance/
├── README.md                          ← this file
├── README.en.md                       ← English version
├── LICENSE                            ← MIT
├── CHANGELOG.md
├── docs/
│   ├── QUICKSTART.md                  ← 30-minute minimal deployment
│   └── ARCHITECTURE.md                ← design trade-offs
└── skills/agent-knowledge-governance/
    ├── SKILL.md                       ← main document (14 sections)
    ├── references/                    ← 7 deep-dive references
    │   ├── five-layer-truth-source.md
    │   ├── artifact-classification.md
    │   ├── experience-reflow.md
    │   ├── indexing-and-links.md
    │   ├── evidence-and-handoff.md
    │   ├── feedback-loop.md
    │   └── pitfalls.md
    ├── templates/                     ← 6 templates
    │   ├── knowledge-card.md
    │   ├── project-log.md
    │   ├── decision-card.md
    │   ├── feedback.md
    │   ├── evolution-proposal.md
    │   └── agent-boundary.md
    └── scripts/                       ← 3 zero-dependency scripts
        ├── quality_gate.sh            ← 15-item quality gate
        ├── check_orphans.py           ← orphan scanner
        └── check_links.py             ← broken-link scanner
```

---

### Scope

**Applies to**
- Multiple AI agents (Claude Code / Codex / Cursor / Hermes / Trae / WorkBuddy …) sharing one
  Markdown knowledge base
- Where artifacts must be traceable, indexes consistent, experience shared, delivery evidenced
- Where quality gates must be automated rather than remembered

**Does not apply to**
- Single-agent personal note-taking
- Single-document writing / polishing
- Content creation unrelated to collaboration governance

---

### Related projects

| Project | Relation |
|---|---|
| [obra/superpowers](https://github.com/obra/superpowers) | Source of the verification-first mindset (MIT, attribution retained) |
| [obsidian-protege-neo4j](https://github.com/zhoudibo/obsidian-protege-neo4j) | The **ontology & query** side of a three-tier knowledge base |
| [three-tier-kb](https://github.com/zhoudibo/three-tier-kb) | The **meta-index** side of a three-tier knowledge base |

---

### License

MIT © 周老大 (zhoudibo)

---

## 中文

### 这是什么

一套**可照做的协作与治理方法论**，外加**三个零依赖脚本**，用于多个 AI 智能体共同维护一套
Markdown 知识库（Obsidian 或普通文件目录均可）。

- **方法论**：五层真相源、产物分级、边界守卫、索引规范、证据先行、反馈闭环
- **脚本**：15 项质量闸门、孤儿扫描、断链扫描
- **模板**：知识卡 / 项目日志 / 决策卡 / 反馈卡 / 进化提案 / Agent 边界守卫

**不依赖云服务、不上传数据、不需要额外安装包** —— 仅 Bash + Python 标准库。

### 五个核心机制

| 痛点 | 机制 |
|---|---|
| 经验不互通 | 经验回流协议：沉淀 → 加载 → 双向索引 → 查询作答（标注出处） |
| 产物散落 | L1/L2/L3 产物分级 + 强制归档 + 孤儿清零闸门 |
| 索引脱节 | 索引与 wikilink 规范 + 断链扫描 + frontmatter 契约 |
| 「说做好了」没证据 | 交付五状态分离 + 有效证据三条件 |
| 一次吐槽改全局规则 | 反馈闭环四步：聚类 → 版本化 → 批准 → 对照 |

### 安装

```bash
git clone https://github.com/zhoudibo/obsidian-multi-agent-knowledge-governance.git

# 装成 skill
cp -R obsidian-multi-agent-knowledge-governance/skills/agent-knowledge-governance \
      ~/.claude/skills/

# 或只取脚本
cp obsidian-multi-agent-knowledge-governance/skills/agent-knowledge-governance/scripts/* \
   ~/.local/bin/
```

### 用法

```bash
bash quality_gate.sh /path/to/vault [agent-root]   # 15 项检查，0 FAIL 才放行
python3 check_orphans.py /path/to/vault             # 孤儿文件扫描
python3 check_links.py /path/to/vault               # 断链扫描
```

### 设计原则

1. **边界优先于善意** —— 谁写哪里是明确的，不是默契
2. **中央索引单一写者** —— 并发写同一文件必然丢失
3. **分类而非评判** —— 产物分级是机械规则，不是品味
4. **证据而非报告** —— 执行人的自述是线索，不是证据
5. **一次反馈不改全局** —— 改全局规则必须聚类、批准、可回滚
6. **指标优于感觉** —— 孤儿为 0、链接不断、闸门 0 FAIL

### 实战踩坑

包括但不限于：vault 里两套同名根目录导致写入错分支、批量移动后 wikilink 断链、
依赖 subagent 自报告、用正则批量改结构化内容损坏文档、
第三方测试失败时区分「环境缺失」与「代码缺陷」……
完整版见 [`references/pitfalls.md`](skills/agent-knowledge-governance/references/pitfalls.md)

### License

MIT © 周老大 (zhoudibo)

---

<div align="center">
<sub>Built from a real multi-agent Obsidian vault in production · 9,800+ notes · 30+ projects</sub>
</div>
