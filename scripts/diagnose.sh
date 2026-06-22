#!/usr/bin/env bash
# leafhub 진단 (비파괴) — 프로필별 스킬 현황·중복·고아 보고
set -uo pipefail

echo "═══════════════════════════════════════════"
echo " leafhub 진단  ($(date '+%Y-%m-%d %H:%M'))"
echo "═══════════════════════════════════════════"

# 1) 현재 세션 CONFIG_DIR
echo
echo "[현재 세션] CLAUDE_CONFIG_DIR=${CLAUDE_CONFIG_DIR:-(unset → ~/.claude 기본)}"

# 2) CONFIG_DIR 후보 탐지 (존재하는 ~/.claude* + .zshrc alias의 CLAUDE_CONFIG_DIR)
declare -a DIRS=()
for d in "$HOME"/.claude "$HOME"/.claude-*; do
  [ -d "$d" ] && case "$d" in *.bak-*) ;; *) DIRS+=("$d") ;; esac
done
# .zshrc 등에서 alias로 지정된 CONFIG_DIR도 수집
for rc in "$HOME"/.zshrc "$HOME"/.zprofile "$HOME"/.bashrc "$HOME"/.profile; do
  [ -f "$rc" ] || continue
  while IFS= read -r p; do
    p="${p/#\~/$HOME}"; [ -d "$p" ] && { found=0; for x in "${DIRS[@]}"; do [ "$x" = "$p" ] && found=1; done; [ $found -eq 0 ] && DIRS+=("$p"); }
  done < <(grep -oE 'CLAUDE_CONFIG_DIR=[^ ]+' "$rc" 2>/dev/null | sed 's/CLAUDE_CONFIG_DIR=//')
done

# 정본 판정: 어떤 프로필의 skills/ 가 심볼릭으로 가리키는 대상 = 정본(공유됨, 고아 아님)
declare -a CANON_TARGETS=()
for d in "${DIRS[@]}"; do
  if [ -L "$d/skills" ]; then t=$(readlink "$d/skills"); t="${t/#\~/$HOME}"; CANON_TARGETS+=("$t"); fi
done
is_canonical() { local p="$1" t; for t in "${CANON_TARGETS[@]:-}"; do [ "$t" = "$p" ] && return 0; done; return 1; }
has_alias() { local rel="${1#$HOME/}"; rel="${rel//./\\.}"; grep -qsE "CLAUDE_CONFIG_DIR=(~|$HOME)/${rel} " "$HOME"/.zshrc "$HOME"/.zprofile "$HOME"/.bashrc 2>/dev/null; }

echo
echo "[탐지된 설정 디렉토리]"
for d in "${DIRS[@]}"; do
  if [ -L "$d/skills" ]; then
    n="→ 정본: $(readlink "$d/skills")"; used="(정본 링크)"
  else
    n="$(ls "$d/skills" 2>/dev/null | wc -l | tr -d ' ')개 (실폴더)"
    if is_canonical "$d/skills"; then
      [ "$d" = "$HOME/.claude" ] && used="(정본·기본 — 모든 프로필 공유)" || used="(정본 — 프로필 공유)"
    elif [ "$d" = "$HOME/.claude" ]; then used="(기본 claude 사용)"
    elif has_alias "$d"; then used="(alias 사용)"
    else used="⚠️ 고아(아무 프로필·기본도 안 씀 → 정본으로 통합 권장)"
    fi
  fi
  printf "  %-28s skills: %s  %s\n" "${d/#$HOME/~}" "$n" "$used"
done

# 3) 스킬 × 위치 (실폴더만), 중복 탐지
echo
echo "[중복 스킬 — 같은 이름이 2곳 이상 '실폴더' = 드리프트 위험]"
tmp=$(mktemp)
for d in "${DIRS[@]}"; do
  sk="$d/skills"; [ -L "$sk" ] && continue   # 심볼릭 dir은 정본을 가리키므로 스킵
  for s in "$sk"/*; do
    [ -e "$s" ] || continue
    name=$(basename "$s"); type="real"; [ -L "$s" ] && type="link"
    echo "$name|${d/#$HOME/~}|$type" >> "$tmp"
  done
done
dup=$(awk -F'|' '$3=="real"{c[$1]++} END{for(k in c) if(c[k]>1) print k}' "$tmp")
if [ -n "$dup" ]; then
  for k in $dup; do
    echo "  ⚠️  $k :"; grep "^$k|" "$tmp" | awk -F'|' '{printf "       - %s (%s)\n",$2,$3}'
  done
else
  echo "  (없음 — 중복 실폴더 없음)"
fi

# 4) 요약 권고
echo
echo "[권고]"
echo "  · 사용자 스킬은 CONFIG_DIR마다 따로다. 프로필 간 공유하려면 정본 1개 + 디렉토리 심볼릭."
echo "  · 중복(⚠️)이 있으면 통합 권장: consolidate.sh <정본> <프로필skills...>"
echo "  · '고아 주의' = 라이브러리가 alias 안 쓰는 dir에 있음 → 그 dir을 정본으로 삼고 프로필을 링크."
rm -f "$tmp"
echo "═══════════════════════════════════════════"
