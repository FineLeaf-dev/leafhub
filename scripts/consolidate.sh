#!/usr/bin/env bash
# leafhub 통합 (파괴적 — 호출 전 반드시 사용자 승인)
# usage: consolidate.sh <정본 skills 경로> <프로필 skills 경로...>
#   예) consolidate.sh ~/.claude/skills ~/.claude-personal/skills ~/.claude-company/skills
set -euo pipefail

CANON="${1:?정본 skills 경로 필요}"; shift
CANON="${CANON/#\~/$HOME}"
[ -d "$CANON" ] || { echo "정본 경로 없음: $CANON"; exit 1; }
[ $# -ge 1 ] || { echo "프로필 skills 경로를 1개 이상 지정"; exit 1; }
TS=$(date +%s)

echo "정본: $CANON"
echo "대상 프로필: $*"
echo "--- 1) 백업 ---"
for P in "$@"; do
  P="${P/#\~/$HOME}"
  [ "$P" = "$CANON" ] && { echo "  (정본은 건너뜀: $P)"; continue; }
  if [ -e "$P" ] && [ ! -L "$P" ]; then cp -R "$P" "$P.bak-$TS" && echo "  백업: $P.bak-$TS"; fi
done

echo "--- 2) strays(정본에 없는 실폴더)를 정본으로 이동 ---"
for P in "$@"; do
  P="${P/#\~/$HOME}"; [ "$P" = "$CANON" ] && continue
  [ -e "$P" ] || continue; [ -L "$P" ] && continue   # 이미 심볼릭 dir이면 스킵
  for s in "$P"/*; do
    [ -e "$s" ] || continue
    name=$(basename "$s")
    if [ ! -e "$CANON/$name" ]; then
      if [ -L "$s" ]; then cp -P "$s" "$CANON/$name" && echo "  링크 복제 → $CANON/$name";
      else mv "$s" "$CANON/$name" && echo "  이동 → $CANON/$name"; fi
    else
      echo "  정본에 이미 있음(폐기, 백업됨): $name @ $P"
    fi
  done
done

echo "--- 3) 프로필 skills/ 를 정본 단일 심볼릭으로 교체 ---"
for P in "$@"; do
  P="${P/#\~/$HOME}"; [ "$P" = "$CANON" ] && continue
  rm -rf "$P" && ln -s "$CANON" "$P" && echo "  $P -> $CANON"
done

echo "--- 완료. 검증: diagnose.sh 재실행 권장. 세션 재시작 시 반영. ---"
echo "(백업: *.bak-$TS — 정상 확인 후 삭제)"
