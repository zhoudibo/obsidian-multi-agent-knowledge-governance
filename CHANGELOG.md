# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] — 2026-11-06

Initial public release.

### Added

#### Skill
- `skills/agent-knowledge-governance/SKILL.md` — main document (14 sections):
  five-layer truth source, artifact classification, write boundaries, index conventions,
  evidence-before-done, feedback loop, 15-item quality gate, pitfalls, rollout checklist

#### References (7)
- `five-layer-truth-source.md` — five-layer model, per-layer write authority,
  migration path that doesn't break an existing vault, cross-layer reference direction
- `artifact-classification.md` — L1/L2/L3 decision tree, boundary-case handling table
- `experience-reflow.md` — four-step reflow loop, load chain, card-cleaning rules
- `indexing-and-links.md` — no-standalone-index rule, orphan remediation,
  safe bulk-move procedure, frontmatter contract, version semantics
- `evidence-and-handoff.md` — executor report vs independent verification,
  five-step pre-claim checklist, evidence-by-deliverable table, five-state handoff
- `feedback-loop.md` — four-step rule evolution, clustering granularity, proposal requirements
- `pitfalls.md` — 20+ real failures, each as symptom → cause → fix

#### Templates (6)
- `knowledge-card.md` — stable reusable conclusions
- `project-log.md` — process record with mandatory three-column status alignment
- `decision-card.md` — traceable decisions with rollback plan
- `feedback.md` — feedback cards preserving verbatim user quotes
- `evolution-proposal.md` — proposals required before changing a global rule
- `agent-boundary.md` — per-agent AGENTS.md fragment (write boundaries + guardrails)

#### Scripts (3, zero dependencies)
- `scripts/quality_gate.sh` — 15-check quality gate; 0 FAIL is the release threshold
- `scripts/check_orphans.py` — finds Markdown files with no inbound wikilink
- `scripts/check_links.py` — finds wikilinks pointing at non-existent files

#### Docs
- `docs/QUICKSTART.md` — 30-minute minimal deployment
- `docs/ARCHITECTURE.md` — design trade-offs and rationale

### Notes
- Extracted from a production multi-agent Obsidian vault (9,800+ notes, 30+ projects)
- All paths are configurable; nothing is hard-coded to one machine's layout
- Scripts use only Bash + Python standard library
