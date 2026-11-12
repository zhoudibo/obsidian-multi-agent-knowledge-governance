# Quickstart · 30 分钟最小可用部署

> 目标：在一个已有的 Markdown 知识库（或从零开始）里，把多智能体协作的**最小可用治理**跑起来。
> 全程不需要安装任何第三方包。

---

## 0. 前置

- 一个 Markdown 知识库目录（Obsidian vault 或普通文件夹都行）
- `bash` 4+、`python3` 3.8+、`find` / `grep`
- 至少两个 AI 智能体（Claude Code / Codex / Cursor / Hermes / Trae / WorkBuddy…）

**不需要**：Node、pip 包、云服务账号。

---

## 1. 目录骨架（10 分钟）

```
<vault>/
├── 00_索引.md                        ← 根索引（唯一写者维护）
├── <业务域1>/00_索引.md              ← 每个域一个索引
│   └── <细分项目>/00_索引.md
├── <业务域2>/00_索引.md
└── 智能体日志/
    ├── <agent-A>/
    │   ├── AGENTS.md                ← 边界守卫
    │   └── 项目/<项目名>/{00_索引.md,日志.md,经验教训.md,成果/}
    └── <agent-B>/
        └── ...
```

**关键**：**不要为每类资源单独建索引文件**。所有链接汇到已有的 `00_索引.md` 里。

---

## 2. 写下边界守卫（10 分钟）

复制 `skills/agent-knowledge-governance/templates/agent-boundary.md`，为每个 agent 改一份。

必须改的四处：

```markdown
- ✅ 只写：<你的写入根目录的绝对路径>
- ❌ 禁止写：中央总索引（由 <唯一写者> 每日聚合）
- ❌ 禁止写：其他 agent 的目录
- ❌ 禁止写：.env / auth.json / 任何含密钥的文件
```

> ⚠️ **用绝对路径，不要用相对路径。**
> 实战里最大的坑就是 vault 里存在两套同名根目录，agent 按直觉写进了错的那个分支 ——
> 文件明明在，索引里却找不到，图谱上看不出任何异常。

---

## 3. 装上脚本（5 分钟）

```bash
cp skills/agent-knowledge-governance/scripts/{quality_gate.sh,check_orphans.py,check_links.py} \
   ~/.local/bin/
chmod +x ~/.local/bin/quality_gate.sh ~/.local/bin/check_*.py
```

验证：

```bash
bash ~/.local/bin/quality_gate.sh <vault>
python3 ~/.local/bin/check_orphans.py <vault> --quiet   # 应输出 0 或少量
python3 ~/.local/bin/check_links.py <vault> --quiet
```

---

## 4. 跑第一轮闸门（5 分钟）

```bash
bash ~/.local/bin/quality_gate.sh <vault>
```

**预期：第一次跑一定 FAIL/WARN。这是对的。**

**正确做法**：

```
Step 1  把输出里的 FAIL 项列成清单（具体到文件路径）
Step 2  逐项修 —— 不是改脚本让检查通过，是修实际问题
Step 3  重跑，直到 0 FAIL
```

> ⚠️ **不要先写「完美脚本」再跑。** 闸门的价值在于暴露真实缺失，
> 绕过它等于把检查变成摆设。

---

## 5. 第一次会话就按这个流程走（此后每会话重复）

```
① 开工前：读域索引 + 项目经验教训 → 产出「已覆盖/待补充/可复用」三栏
② 干活中：可复用结论随手记（现象 → 原因 → 对策）
③ 收尾：L1 产物归档 → 已有索引加 wikilink → 日志追加行 → ls 验证
④ 回流：通用结论 → 知识卡 → 域索引登记
⑤ 闸门：0 FAIL 才算完
```

---

## 6. 一周后

到这一步你已经跑通了基础循环。接下来按收益排序加：

| 顺序 | 加什么 | 为什么 |
|:--:|---|---|
| 1 | **反馈库 + 进化提案目录** | 让「一次吐槽」不再直接改全局规则 |
| 2 | **孤儿/断链检查接进 cron** | 索引脱节是时间必然，不检查就烂 |
| 3 | **每 agent 目录加 `经验教训.md`** | 坑比结论更容易被复用 |
| 4 | **中央索引单一写者 + 每日聚合** | 消除并发写冲突 |
| 5 | **00 资源层只读标记** | 保护原始证据 |

---

## 7. 常见问题

**Q：闸门一直 FAIL，是不是规则定得太严？**
A：先看 FAIL 具体指向什么。多数是「文件存在但没登记索引」这类真问题。
只有确认是规则本身不适用时，才在脚本里放宽，并写清为什么。

**Q：孤儿扫描报了几百个，怎么处理？**
A：先看是不是**索引文件自己**成了孤儿（独立索引文件是常见来源）。
再按「有价值→加链接 / 重复→合并 / 废弃→移出」三类处理。
不要用「先放着」。

**Q：多个 agent 都在写 vault，会不会打架？**
A：会，但只要**中央索引有且只有一个写者**，其他目录各自隔离，就打不起来。
冲突几乎都发生在「大家都能改的那个文件」上。

**Q：脚本在 Windows 上能用吗？**
A：`check_orphans.py` / `check_links.py` 可以（纯 Python）。
`quality_gate.sh` 是 Bash 脚本，Windows 建议用 Git Bash 或 WSL。

---

## 下一步

- 架构与设计取舍 → [ARCHITECTURE.md](ARCHITECTURE.md)
- 完整方法论 → `skills/agent-knowledge-governance/SKILL.md`
- 实战踩坑 → `skills/agent-knowledge-governance/references/pitfalls.md`
