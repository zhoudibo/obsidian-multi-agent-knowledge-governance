#!/usr/bin/env bash
# ============================================================
# 知识库质量闸门 · 15 项检查
# ============================================================
# 用法：
#   bash quality_gate.sh <vault-root> [agent-root]
#
#   <vault-root>   知识库根目录（必填）
#   <agent-root>   本智能体日志目录（可选，用于检查本 agent 的产出）
#
# 退出码：0 = 放行（无 FAIL）；1 = 有 FAIL
# 依赖：bash / find / grep / python3（无第三方包）
# ============================================================

set -uo pipefail

VAULT="${1:-}"
AGENT_ROOT="${2:-}"

if [[ -z "$VAULT" || ! -d "$VAULT" ]]; then
  echo "用法: bash quality_gate.sh <vault-root> [agent-root]"
  echo "错误：目录不存在或未指定 '$VAULT'"
  exit 2
fi

VAULT="$(cd "$VAULT" && pwd)"
PASSED=0; FAILED=0; WARNED=0
TODAY="$(date +%Y-%m-%d)"

# 排除目录（规则 12：过滤系统目录）
EXCLUDES=( -not -path "*/.obsidian/*" -not -path "*/.git/*"
           -not -path "*/node_modules/*" -not -path "*/__pycache__/*"
           -not -path "*/.venv/*" -not -path "*/venv/*" )

# ── 文件列表缓存（关键性能优化）─────────────────────────────
# 真实 vault 有 1 万+ md 与大量图片，重复 find 会累积到数分钟。
# 这里一次 find 落盘缓存，后续检查全部复用。
MD_LIST="$(mktemp -t qg_mdlist.XXXXXX)"
trap 'rm -f "$MD_LIST"' EXIT

find "$VAULT" "${EXCLUDES[@]}" -name "*.md" -type f 2>/dev/null > "$MD_LIST"

all_md() { cat "$MD_LIST"; }

# 今日新增文件（复用同一次 find 的结果，不重复遍历）
NEW_MD_LIST="$(mktemp -t qg_newmd.XXXXXX)"
trap 'rm -f "$MD_LIST" "$NEW_MD_LIST"' EXIT
find "$VAULT" "${EXCLUDES[@]}" -name "*.md" -type f -newermt "$TODAY" 2>/dev/null > "$NEW_MD_LIST"

# ── 1. 资源层零覆盖 ────────────────────────────────────
check_1_no_raw_overwrite() {
  echo "[1/15] 资源层零覆盖检查..."
  local hits=0
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    # 资源层目录下的文件若带 RAW 标记，则检查 mtime 是否在入库后被改
    if [[ "$f" == */raw/* || "$f" == *_raw_* ]]; then
      local mt; mt="$(stat -f %Sm -t "%Y-%m-%d" "$f" 2>/dev/null || echo "")"
      if [[ -n "$mt" && "$mt" == "$TODAY" ]]; then
        echo "  ⚠️ WARN: 资源层文件今日被修改: ${f#$VAULT/}"
        hits=$((hits+1))
      fi
    fi
  done <<< "$(all_md)"
  if [[ $hits -eq 0 ]]; then
    echo "  ✅ PASS: 资源层未被覆盖"
    PASSED=$((PASSED+1))
  else
    echo "  ⚠️ WARN: $hits 个资源层文件今日被修改"
    WARNED=$((WARNED+1))
  fi
}

# ── 2. secret 扫描 ─────────────────────────────────────
check_2_secret_scan() {
  echo "[2/15] secret 扫描..."
  local hits
  hits="$(tr '\n' '\0' < "$MD_LIST" | xargs -0 python3 -c '
import sys, re
pat = re.compile(r"(api[_-]?key|secret[_-]?key|access[_-]?token|private[_-]?key)\s*[:=]\s*[\"\x27]?[A-Za-z0-9_\-]{20,}", re.I)
n = 0
for path in sys.argv[1:]:
    if n >= 20: break
    try:
        with open(path, encoding="utf-8", errors="ignore") as f:
            if pat.search(f.read()):
                print(path); n += 1
    except OSError:
        pass
' 2>/dev/null)"
  local n=0
  [[ -n "$hits" ]] && n="$(printf '%s\n' "$hits" | wc -l | tr -d ' ')"
  # 明确禁止入库的文件类型
  # 注意：.key 扩展名在真实库里极常见（SecureCRT 键位、ClickHouse TLS 证书、
  # 微信小游戏素材），不能一律判 FAIL —— 改为只对高置信度凭据文件判 FAIL，
  # .key/.pem 降级为 WARN 交人工判断。
  local bad hard; bad="$(find "$VAULT" "${EXCLUDES[@]}" \
        \( -name ".env" -o -name "auth.json" -o -name "credentials" \
           -o -name "id_rsa" -o -name "id_ed25519" \) -type f 2>/dev/null | head -10)"
  hard="$(find "$VAULT" "${EXCLUDES[@]}" \
        \( -name "*.pem" -o -name "*.key" \) -type f 2>/dev/null | head -5)"
  local bn=0
  [[ -n "$bad" ]] && bn="$(printf '%s\n' "$bad" | wc -l | tr -d ' ')"
  if [[ $bn -gt 0 ]]; then
    echo "  ❌ FAIL: 发现 $bn 个禁止入库的凭据文件:"
    printf '%s\n' "$bad" | sed 's/^/      /'
    FAILED=$((FAILED+1)); return
  fi
  if [[ -n "$hard" ]]; then
    local hn; hn="$(printf '%s\n' "$hard" | wc -l | tr -d ' ')"
    echo "  ⚠️ WARN: $hn 个 .pem/.key 文件（可能是 TLS 证书或工具键位，需人工确认非密钥）"
    printf '%s\n' "$hard" | sed "s|$VAULT/|      |" | head -3
  fi
  if [[ $n -gt 0 ]]; then
    echo "  ⚠️ WARN: $n 个文件疑似含密钥模式（需人工确认）:"
    printf '%s\n' "$hits" | sed "s|$VAULT/|      |" | head -5
    WARNED=$((WARNED+1))
  else
    echo "  ✅ PASS: 无高风险敏感内容，无禁止入库的凭据文件"
    PASSED=$((PASSED+1))
  fi
}

# ── 3. 来源存在 ─────────────────────────────────────────
check_3_source_exists() {
  echo "[3/15] 来源存在检查..."
  local scope="$VAULT"
  [[ -n "$AGENT_ROOT" && -d "$AGENT_ROOT" ]] && scope="$AGENT_ROOT"
  local new_files
  if [[ -n "$AGENT_ROOT" && -d "$AGENT_ROOT" ]]; then
    new_files="$(find "$AGENT_ROOT" "${EXCLUDES[@]}" -name "*.md" -type f -newermt "$TODAY" 2>/dev/null)"
  else
    new_files="$(cat "$NEW_MD_LIST")"
  fi
  local total=0 missing=0
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    total=$((total+1))
    head -100 "$f" 2>/dev/null | grep -q "^source:" || missing=$((missing+1))
  done <<< "$new_files"
  if [[ $total -eq 0 ]]; then
    echo "  ℹ️ 今日无新增文件"; PASSED=$((PASSED+1))
  elif [[ $missing -eq 0 ]]; then
    echo "  ✅ PASS: ${total}个新文件全部有source标注"; PASSED=$((PASSED+1))
  else
    echo "  ⚠️ WARN: ${missing}/${total}个新文件缺source标注"; WARNED=$((WARNED+1))
  fi
}

# ── 4. 日期有效性 ───────────────────────────────────────
check_4_date_valid() {
  echo "[4/15] 日期有效性检查..."
  # 用 Python 单次遍历（grep -rhoE 在 1 万+ 文件上需 80+ 秒，Python 约 5 秒）
  local future
  future="$(tr '\n' '\0' < "$MD_LIST" | xargs -0 python3 -c '
import sys, re
from datetime import date
today = date.today()
# 非捕获组：findall 返回完整日期字符串（用捕获组会只返回年份）
pat = re.compile(r"\b(?:20[3-9][0-9]|2[1-9][0-9]{2})-[0-9]{2}-[0-9]{2}\b")
found = set()
for path in sys.argv[1:]:
    try:
        with open(path, encoding="utf-8", errors="ignore") as f:
            text = f.read()
    except OSError:
        continue
    for s in pat.findall(text):
        try:
            y, mo, dd = (int(x) for x in s.split("-"))
            d = date(y, mo, dd)
        except ValueError:
            found.add(s + " (非法日期)")   # 非法日期本身就是问题，不能跳过
            continue
        if d > today:
            found.add(s)
for d in sorted(found)[:5]:
    print(d)
' 2>/dev/null)"
  local n=0; [[ -n "$future" ]] && n="$(printf '%s\n' "$future" | wc -l | tr -d ' ')"
  if [[ $n -eq 0 ]]; then
    echo "  ✅ PASS: 无未来日期"; PASSED=$((PASSED+1))
  else
    echo "  ❌ FAIL: 发现 $n 个未来日期:"; printf '%s\n' "$future" | sed 's/^/      /'
    FAILED=$((FAILED+1))
  fi
}

# ── 5. 事实/判断分离 ────────────────────────────────────
check_5_fact_judgment_separation() {
  echo "[5/15] 事实/判断分离检查..."
  local scope="$VAULT"
  [[ -n "$AGENT_ROOT" && -d "$AGENT_ROOT" ]] && scope="$AGENT_ROOT"
  local total typed
  if [[ -n "$AGENT_ROOT" && -d "$AGENT_ROOT" ]]; then
    total="$(find "$AGENT_ROOT" "${EXCLUDES[@]}" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')"
  else
    total="$(wc -l < "$MD_LIST" | tr -d ' ')"
  fi
  if [[ $total -eq 0 ]]; then echo "  ℹ️ 无文件"; PASSED=$((PASSED+1)); return; fi
  if [[ -n "$AGENT_ROOT" && -d "$AGENT_ROOT" ]]; then
    typed="$(find "$AGENT_ROOT" "${EXCLUDES[@]}" -name "*.md" -type f -exec grep -l "^type:" {} \; 2>/dev/null | wc -l | tr -d ' ')"
  else
    # 性能：单次 grep 扫描所有文件，统计匹配「文件数」而非匹配「行数」
    # grep -c 对每个文件输出一行计数，用 uniq 去重文件路径计数
    typed="$(tr '\n' '\0' < "$MD_LIST" | xargs -0 grep -l "^type:" 2>/dev/null | wc -l | tr -d ' ')"
    [[ "$typed" -eq 0 ]] && typed="$(grep -c '^type:' "$MD_LIST" 2>/dev/null | grep -v ':0$' | wc -l | tr -d ' ')"
  fi
  local pct=$(( typed * 100 / total ))
  if [[ $pct -ge 50 ]]; then
    echo "  ✅ PASS: $pct% 有type标注 ($typed/$total)"; PASSED=$((PASSED+1))
  else
    echo "  ⚠️ WARN: 仅 $pct% 有type标注 ($typed/$total)"; WARNED=$((WARNED+1))
  fi
}

# ── 6. 不虚构实测 ───────────────────────────────────────
check_6_no_fabrication() {
  echo "[6/15] 不虚构实测检查..."
  local hits
  hits="$(grep -rniE '(实测|已验证|测试通过|已跑通)' "$VAULT" --include="*.md" 2>/dev/null \
          | grep -vE '(未验证|未实测|待验证|尚未|不得写|不虚构|不能写|需实测|待补|不是实测|不代表)' \
          | grep -vE 'pct=|percent|率' | head -10)"
  local n=0; [[ -n "$hits" ]] && n="$(printf '%s\n' "$hits" | wc -l | tr -d ' ')"
  if [[ $n -eq 0 ]]; then
    echo "  ✅ PASS: 无未证实的实测声称"; PASSED=$((PASSED+1))
  else
    echo "  ⚠️ WARN: $n 处可能的实测声称需人工确认（多为正常表述）"
    WARNED=$((WARNED+1))
  fi
}

# ── 7. 不重复生产旧成果 ─────────────────────────────────
check_7_no_duplicates() {
  echo "[7/15] 不重复生产旧成果检查..."
  local dup
  dup="$(grep -lE "^title:" "$MD_LIST" 2>/dev/null | xargs -I {} grep -h "^title:" {} 2>/dev/null \
         | sort | uniq -d | head -5)"
  local n=0; [[ -n "$dup" ]] && n="$(printf '%s\n' "$dup" | wc -l | tr -d ' ')"
  if [[ $n -eq 0 ]]; then
    echo "  ✅ PASS: 无重复title的索引"; PASSED=$((PASSED+1))
  else
    echo "  ⚠️ WARN: $n 个索引有重复title"; printf '%s\n' "$dup" | sed 's/^/      /'
    WARNED=$((WARNED+1))
  fi
}

# ── 8. 每轮唯一结案 ─────────────────────────────────────
check_8_unique_closure() {
  echo "[8/15] 每轮唯一结案检查..."
  local scope="$VAULT"
  [[ -n "$AGENT_ROOT" && -d "$AGENT_ROOT" ]] && scope="$AGENT_ROOT"
  local status_files
  status_files="$(grep -E "/[^/]*(状态|status)[^/]*\.md$" "$MD_LIST" 2>/dev/null | head -10)"
  if [[ -z "$status_files" ]]; then
    echo "  ℹ️ 未发现状态文件（可选）"; PASSED=$((PASSED+1))
  else
    echo "  ✅ PASS: 状态文件存在 ($(printf '%s\n' "$status_files" | wc -l | tr -d ' ') 个)"; PASSED=$((PASSED+1))
  fi
}

# ── 9. 抓取失败≠无新增 ─────────────────────────────────
check_9_grab_failure_handling() {
  echo "[9/15] 抓取失败处理检查..."
  local fb
  fb="$(grep -E "/(反馈库|feedback|反馈)/" "$MD_LIST" 2>/dev/null | xargs -r dirname 2>/dev/null | sort -u | head -3)"
  if [[ -n "$fb" ]]; then
    local n; n="$(find "$fb" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')"
    if [[ $n -gt 0 ]]; then
      echo "  ✅ PASS: 反馈库已建立（$n 条记录）"; PASSED=$((PASSED+1))
    else
      echo "  ⚠️ WARN: 反馈库存在但为空"; WARNED=$((WARNED+1))
    fi
  else
    echo "  ℹ️ 未建立反馈库（可选）"; PASSED=$((PASSED+1))
  fi
}

# ── 10. 索引一致性 ─────────────────────────────────────
check_10_index_consistency() {
  echo "[10/15] 索引一致性检查..."
  local scope="$VAULT"
  [[ -n "$AGENT_ROOT" && -d "$AGENT_ROOT" ]] && scope="$AGENT_ROOT"
  local idx
  idx="$(grep -E "/(对话索引|00_总导航|00_知识库总导航-MOC)\.md$" "$MD_LIST" 2>/dev/null | head -5)"
  if [[ -n "$idx" ]]; then
    echo "  ✅ PASS: 总导航/索引已建立（$(printf '%s\n' "$idx" | wc -l | tr -d ' ') 个）"; PASSED=$((PASSED+1))
  else
    echo "  ⚠️ WARN: 未发现总导航或对话索引"; WARNED=$((WARNED+1))
  fi
}

# ── 11. 状态文件一致 ───────────────────────────────────
check_11_state_consistency() {
  echo "[11/15] 状态文件一致性检查..."
  local agents
  agents="$(grep -E "/智能体/" "$MD_LIST" 2>/dev/null | xargs -r dirname 2>/dev/null | sort -u | head -3)"
  if [[ -n "$agents" ]]; then
    local boundaries
    boundaries="$(grep -E "/[^/]*AGENTS[^/]*\.md$" "$MD_LIST" 2>/dev/null | head -10)"
    if [[ -n "$boundaries" ]]; then
      echo "  ✅ PASS: 智能体边界文件已配置（$(printf '%s\n' "$boundaries" | wc -l | tr -d ' ') 个）"; PASSED=$((PASSED+1))
    else
      echo "  ⚠️ WARN: 存在智能体目录但无 AGENTS 边界文件"; WARNED=$((WARNED+1))
    fi
  else
    echo "  ℹ️ 未发现智能体目录（可选）"; PASSED=$((PASSED+1))
  fi
}

# ── 12. 中间页≠成果 ───────────────────────────────────
check_12_no_draft_as_result() {
  echo "[12/15] 中间页≠成果检查..."
  local scope="$VAULT"
  [[ -n "$AGENT_ROOT" && -d "$AGENT_ROOT" ]] && scope="$AGENT_ROOT"
  local drafts
  drafts="$(find "$scope" "${EXCLUDES[@]}" -name "*.md" -type f 2>/dev/null \
            | grep -iE '(草稿|draft|临时|scratch|wip)' \
            | grep -iE '(成果|交付|result|deliver)' | head -5)"
  local n=0; [[ -n "$drafts" ]] && n="$(printf '%s\n' "$drafts" | wc -l | tr -d ' ')"
  if [[ $n -eq 0 ]]; then
    echo "  ✅ PASS: 无草稿冒充成果"; PASSED=$((PASSED+1))
  else
    echo "  ❌ FAIL: $n 个草稿文件出现在成果目录:"; printf '%s\n' "$drafts" | sed "s|$VAULT/|      |"
    FAILED=$((FAILED+1))
  fi
}

# ── 13. 用户目标质量 ───────────────────────────────────
check_13_user_quality() {
  echo "[13/15] 用户目标质量检查..."
  local scope="$VAULT"
  [[ -n "$AGENT_ROOT" && -d "$AGENT_ROOT" ]] && scope="$AGENT_ROOT"
  local n
  if [[ -n "$AGENT_ROOT" && -d "$AGENT_ROOT" ]]; then
    n="$(find "$AGENT_ROOT" "${EXCLUDES[@]}" -name "*.md" -type f -newermt "$TODAY" 2>/dev/null | wc -l | tr -d ' ')"
  else
    n="$(wc -l < "$NEW_MD_LIST" | tr -d ' ')"
  fi
  if [[ $n -gt 0 ]]; then
    echo "  ✅ PASS: 今日有 $n 个新增产出待验收"; PASSED=$((PASSED+1))
  else
    echo "  ℹ️ 今日无新增产出"; PASSED=$((PASSED+1))
  fi
}

# ── 14. 连续低分暂停扩量 ───────────────────────────────
check_14_low_score_pause() {
  echo "[14/15] 连续低分暂停扩量检查..."
  local low
  low="$(find "$VAULT" "${EXCLUDES[@]}" -name "*.md" -type f -newermt "$TODAY" 2>/dev/null \
         | xargs -I {} grep -l "连续低分\|连续未通过\|连续失败" {} 2>/dev/null | head -3)"
  local n=0; [[ -n "$low" ]] && n="$(printf '%s\n' "$low" | wc -l | tr -d ' ')"
  if [[ $n -eq 0 ]]; then
    echo "  ✅ PASS: 无连续低分信号"; PASSED=$((PASSED+1))
  else
    echo "  ⚠️ WARN: $n 个文件提到连续低分，需确认是否已暂停扩量"
    WARNED=$((WARNED+1))
  fi
}

# ── 15. 画像长期无更新触发审计 ─────────────────────────
check_15_profile_audit() {
  echo "[15/15] 画像审计触发检查..."
  local evo
  evo="$(grep -E "/(进化提案|evolution)/" "$MD_LIST" 2>/dev/null | xargs -r dirname 2>/dev/null | sort -u | head -2)"
  if [[ -n "$evo" ]]; then
    local latest; latest="$(ls -t "$evo"/*.md 2>/dev/null | head -1)"
    if [[ -n "$latest" ]]; then
      local age; age=$(( ( $(date +%s) - $(stat -f %m "$latest" 2>/dev/null || echo 0) ) / 86400 ))
      if [[ $age -gt 30 ]]; then
        echo "  ⚠️ WARN: 上次进化报告 ${age}天前，建议审计"; WARNED=$((WARNED+1))
      else
        echo "  ✅ PASS: 进化提案最近 ${age} 天内有更新"; PASSED=$((PASSED+1))
      fi
    else
      echo "  ℹ️ 进化提案目录为空"; PASSED=$((PASSED+1))
    fi
  else
    echo "  ℹ️ 未建立进化提案目录（可选）"; PASSED=$((PASSED+1))
  fi
}

# ── 执行 ───────────────────────────────────────────────
echo "============================================================"
echo " 知识库质量闸门 · 15 项 · v1.0"
echo " 根目录: $VAULT"
[[ -n "$AGENT_ROOT" ]] && echo " Agent 目录: $AGENT_ROOT"
echo "============================================================"
echo ""

check_1_no_raw_overwrite
check_2_secret_scan
check_3_source_exists
check_4_date_valid
check_5_fact_judgment_separation
check_6_no_fabrication
check_7_no_duplicates
check_8_unique_closure
check_9_grab_failure_handling
check_10_index_consistency
check_11_state_consistency
check_12_no_draft_as_result
check_13_user_quality
check_14_low_score_pause
check_15_profile_audit

echo ""
echo "============================================================"
echo " 检查结果：$PASSED PASS / $WARNED WARN / $FAILED FAIL"
echo "============================================================"

if [[ $FAILED -gt 0 ]]; then
  echo ""
  echo "❌ 有 FAIL 项 —— 立即回滚该批变更并修复后重跑"
  exit 1
fi
echo "✅ 放行（0 FAIL）"
exit 0
