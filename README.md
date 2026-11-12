<div align="center">

# Obsidian Multi-Agent Knowledge Governance

# 多智能体协作 × Obsidian 知识库治理技能包

**让「一个人 + 多个 AI 智能体」共同维护一套 Markdown 知识库时，产物有归属、索引不断链、经验能共享、交付有证据、错误能收敛。**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Python](https://img.shields.io/badge/Python-3.8%2B-blue.svg)](https://www.python.org/)
[![Bash](https://img.shields.io/badge/Bash-4%2B-green.svg)](https://www.gnu.org/software/bash/)
[![Zero Dependencies](https://img.shields.io/badge/dependencies-none-brightgreen.svg)](.)
[![License](https://img.shields.io/badge/license-MIT-9c36b6.svg)](LICENSE)
[![Agents](https://img.shields.io/badge/agents-Claude%20Code%20%7C%20Codex%20%7C%20Cursor%20%7C%20Hermes%20%7C%20Trae%20%7C%20WorkBuddy-blueviolet.svg)](.)

[English](#english) · [中文](#中文) · [安装](#安装) · [核心机制](#核心机制) · [实战踩坑](#实战踩坑)

</div>

---

## 为什么需要这个

多个 AI 智能体一起干活时，最容易翻车的不是「AI 不会做」，而是**协作层没人管**：

| 痛点 | 症状 | 本仓库的机制 |
|---|---|---|
| 🧠 **经验不互通** | 三个 agent 处理同类问题，重复踩同一个坑 | [经验回流协议](skills/agent-knowledge-governance/references/experience-reflow.md)：沉淀 → 加载 → 双向索引 → 查询作答 |
| 📦 **产物散落** | 生成的文件到处飘，图谱被孤儿节点污染 | [产物三级分类](skills/agent-knowledge-governance/references/artifact-classification.md) + 强制归档 + 孤儿清零闸门 |
| 🔗 **索引脱节** | 索引写了但文件被删；文件加了但索引没更新 | [索引与 wikilink 规范](skills/agent-knowledge-governance/references/indexing-and-links.md) + 断链扫描 |
| ✅ **「说做好了」没证据** | 子代理回报完成，实际根本没做 | [证据先行](skills/agent-knowledge-governance/references/evidence-and-handoff.md)：五状态分离 + 有效证据三条件 |
| 🔄 **一次吐槽改全局规则** | 规则集膨胀成互相矛盾的垃圾 | [反馈闭环](skills/agent-knowledge-governance/references/feedback-loop.md)：聚类 → 版本化 → 批准 → 对照 |

---

## 中文

### 这是什么

一套**可照做的协作与治理方法论**，外加**三个零依赖脚本**。

- **方法论**（Markdown）：五层真相源、产物分级、边界守卫、索引规范、证据先行、反馈闭环
- **脚本**（Bash / Python 标准库）：15 项质量闸门、孤儿扫描、断链扫描
- **模板**（6 份）：知识卡 / 项目日志 / 决策卡 / 反馈卡 / 进化提案 / Agent 边界守卫

**不依赖任何云服务、不上传任何数据、不需要额外安装包。**

### 核心机制

#### 1. 五层真相源

一个能被多智能体共用的库，必须区分**什么可以改、什么不能改**：

| 层 | 职责 | 写入权 | 可变性 |
|:--:|---|---|---|
| **00** | 资源层 · 原始证据 | 🔒 **只读** | 🚫 任何人不得覆盖 |
| **01** | 主题 Wiki · 稳定知识 | 产出该卡的 agent | 🔄 演进不覆盖（version+1） |
| **02** | 项目库 · 正在推进的事 | 项目负责 agent | ✏️ 活跃可变 |
| **03** | 输出库 · 正式成果 | 项目负责 agent | ✏️ 批次化归档 |
| **04** | 系统维护层 · 入口与规则 | 👤 **单一写者** | 🔄 索引者统一聚合 |

> 落地时**不需要照搬目录名** —— 关键是职责与写入权的分离。
> [映射方法 →](skills/agent-knowledge-governance/references/five-layer-truth-source.md)

#### 2. 产物三级分类

判定标准写成**可机械执行的规则**，不是「我觉得重要」：

| 级别 | 定义 | 进库？ |
|---|---|---|
| **L1 最终产物** | 已交付、可复用 | ✅ 必须 |
| **L2 过程产物** | 中间状态、可追溯 | ⚠️ 选择性 |
| **L3 临时产物** | 调试 / 缓存 / 中间计算 | ❌ 绝不打 |

#### 3. 交付五状态分离

把「执行人说好了」和「收的人亲眼核过」分成**两个不可混淆的状态**：

```
待收 → 已接单 → 已收到成果 → 已验收
                    ↓
                  退回
```

**核心三条反模式**（都写死在文档里）：

- **等待结束 ≠ 成果回来** —— 必须去结果该在的地方看
- **执行人自己的报告 ≠ 独立核验** —— 只当线索
- **新预计 ≠ 正式改期** —— 原承诺那一格照旧保留

#### 4. 反馈闭环四步

> **除事实错误和安全问题外，一次反馈不得直接改全局规则。**

```
聚类 → 版本化 → 批准 → 对照
```

单次反馈只记录；同类 ≥2 次或出现结果数据才触发提案；改全局规则必须有**回滚方案**且**经人批准**。

---

### 安装

```bash
git clone https://github.com/zhoudibo/obsidian-multi-agent-knowledge-governance.git

# 方式 A：装成 Claude Code / Codex 等的 skill
cp -R obsidian-multi-agent-knowledge-governance/skills/agent-knowledge-governance \
      ~/.claude/skills/          # 或 ~/.codex/skills/ 等

# 方式 B：只取脚本，做成定时检查
cp obsidian-multi-agent-knowledge-governance/skills/agent-knowledge-governance/scripts/*.sh \
   obsidian-multi-agent-knowledge-governance/skills/agent-knowledge-governance/scripts/*.py \
   ~/.local/bin/
```

### 用法

```bash
# 15 项质量闸门 —— 0 FAIL 才算放行
bash quality_gate.sh /path/to/vault [agent-root]

# 孤儿文件扫描（没有任何入链的 md）
python3 check_orphans.py /path/to/vault

# 断链扫描（指向不存在文件的 wikilink）
python3 check_links.py /path/to/vault
```

**放行阈值：0 FAIL。** 任一 FAIL 立即回滚该批变更。

> ⚠️ **使用纪律**：第一次跑必然 FAIL/WARN，**必须先列出具体缺失文件**，再追求 0 WARN。
> 不要先写「完美脚本」再跑。

---

### 实战踩坑清单

全部来自真实运行 —— **规则告诉你「应该怎么做」，坑告诉你「哪里会出事」**：

| 症状 | 原因 | 对策 |
|---|---|---|
| 文件写进去了，索引却找不到 | vault 里有**两套同名根目录**，agent 按直觉选错分支 | 写入前必查同步协议；`AGENTS.md` 里写死绝对路径 |
| 图谱出现大量孤立圆点 | 新建文件没在已有索引加链接 | 归档时**必须**在**已有的**索引加 wikilink；禁止建独立索引 |
| 索引链接点开是空白页 | 批量 `mv` 后没改 wikilink 前缀 | 脚本批量替换前缀 → 断链扫描 → 孤儿扫描 → 闸门 |
| 报告「已归档」但文件不在 | 依赖 subagent 自报告 | **`ls` 验证落盘位置**，放错立即 `mv` |
| 一次吐槽改了全局规则 | 跳过聚类 | 走「聚类→版本化→批准→对照」四步 |
| 测试挂了 —— 是代码 bug 还是环境问题？ | 混淆二者 | `No such filter` / `command not found` = **环境缺失（可修）**；断言失败 = **真缺陷** |
| 批量改 HTML 改坏了 28 篇文档 | 用正则匹配嵌套结构 | **结构化修改必须用 DOM 解析**，正则只用来定位 |
| 转换后文件数比预期少 | 源目录已有同名产物，新工具又转一遍 | 用**集合差集**量化：`src - out` / `out - src` |
| 下载的二进制跑不起来 | release 只有 arm64，本机是 x86_64 | 下载前查 `uname -m` + 翻历史 release |
| macOS 拦住下载的程序 | quarantine 属性 | `xattr -cr` + `codesign --force --deep --sign -` |
| `./tool --help` 没输出像坏了 | 管道缓冲造成假象 | 直接跑不带管道；看 `file` 和退出码 |

完整版：[`references/pitfalls.md`](skills/agent-knowledge-governance/references/pitfalls.md)

---

### 文件结构

```
obsidian-multi-agent-knowledge-governance/
├── README.md                          ← 本文件（双语）
├── README.en.md                       ← 英文版
├── LICENSE                            ← MIT
├── CHANGELOG.md
├── docs/
│   ├── QUICKSTART.md                  ← 30 分钟最小可用部署
│   └── ARCHITECTURE.md                ← 架构与设计取舍
└── skills/agent-knowledge-governance/
    ├── SKILL.md                       ← 主文档（14 节）
    ├── references/                    ← 6 份深度参考
    │   ├── five-layer-truth-source.md
    │   ├── artifact-classification.md
    │   ├── experience-reflow.md
    │   ├── indexing-and-links.md
    │   ├── evidence-and-handoff.md
    │   ├── feedback-loop.md
    │   └── pitfalls.md
    ├── templates/                     ← 6 份模板
    │   ├── knowledge-card.md
    │   ├── project-log.md
    │   ├── decision-card.md
    │   ├── feedback.md
    │   ├── evolution-proposal.md
    │   └── agent-boundary.md
    └── scripts/                       ← 3 个零依赖脚本
        ├── quality_gate.sh            ← 15 项质量闸门
        ├── check_orphans.py           ← 孤儿扫描
        └── check_links.py             ← 断链扫描
```

---

### 适用边界

**适用**
- 多智能体（Claude Code / Codex / Cursor / Hermes / Trae / WorkBuddy 等）共用一个 Markdown 知识库
- 需要产物可追溯、索引一致、经验共享、交付有证据
- 需要自动化质量闸门而非靠记性

**不适用**
- 单一智能体的普通笔记管理
- 单文件写作 / 润色
- 与协作治理无关的内容创作

---

### 与相关项目的关系

| 项目 | 关系 |
|---|---|
| [obra/superpowers](https://github.com/obra/superpowers) | 验证优先思路的来源（MIT，已保留声明） |
| [obsidian-protege-neo4j](https://github.com/zhoudibo/obsidian-protege-neo4j) | 三层知识库的**本体与查询**侧 |
| [three-tier-kb](https://github.com/zhoudibo/three-tier-kb) | 三层索引的**元索引**侧 |

---

### License

MIT © 周老大 (zhoudibo)

---

## English

### What is this

A **reusable methodology + three zero-dependency scripts** for running multiple AI agents against
one shared Markdown knowledge base (Obsidian or plain files).

- **Methodology**: five-layer truth source, artifact classification, write boundaries,
  index & wikilink conventions, evidence-before-done, feedback-to-rule loop
- **Scripts**: 15-item quality gate, orphan scanner, broken-link scanner
- **Templates**: knowledge card / project log / decision card / feedback card /
  evolution proposal / agent boundary file

**No cloud services. No data upload. No extra packages** — Bash + Python standard library only.

### The five pain points it solves

| Pain | Mechanism |
|---|---|
| Agents don't share experience | Reflow protocol: distill → load → backlink → answer with citation |
| Artifacts scattered everywhere | L1/L2/L3 classification + mandatory archiving + orphan-zero gate |
| Index drifts from reality | Index conventions + broken-link scan + frontmatter contract |
| "It's done" without evidence | Five-state handoff separation + three conditions for valid evidence |
| One complaint rewrites global rules | Four-step loop: cluster → version → approve → compare |

### Install

```bash
git clone https://github.com/zhoudibo/obsidian-multi-agent-knowledge-governance.git

# As a skill
cp -R obsidian-multi-agent-knowledge-governance/skills/agent-knowledge-governance \
      ~/.claude/skills/

# Or just the scripts
cp obsidian-multi-agent-knowledge-governance/skills/agent-knowledge-governance/scripts/* \
   ~/.local/bin/
```

### Usage

```bash
bash quality_gate.sh /path/to/vault [agent-root]   # 15 checks, 0 FAIL to pass
python3 check_orphans.py /path/to/vault             # files nobody links to
python3 check_links.py /path/to/vault               # links pointing nowhere
```

### Design principles

1. **Write boundaries over good intentions** — who may write where is explicit, not implied
2. **Single writer for central indexes** — concurrency on one file guarantees loss
3. **Classify, don't judge** — artifact levels are mechanical rules, not taste
4. **Evidence, not reports** — the executor's own report is a lead, never evidence
5. **One complaint changes nothing** — global rules need clustering, approval, and rollback
6. **Metrics over vibes** — orphan count must be 0, links must resolve, gate must be 0 FAIL

### License

MIT © 周老大 (zhoudibo)

---

<div align="center">
<sub>Built from a real multi-agent Obsidian vault in production · 9,800+ notes · 30+ projects</sub>
</div>
