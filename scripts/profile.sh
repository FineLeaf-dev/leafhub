#!/usr/bin/env bash
# leafhub 프로필 관리 (macOS/zsh) — list | add <name> | remove <name>
# 새 프로필은 정본 skills를 자동 심볼릭. .zshrc alias는 백업 후 편집. 인증(로그인)은 수동.
set -uo pipefail

CANON="${SKILLSYNC_CANON:-$HOME/.claude/skills}"; CANON="${CANON/#\~/$HOME}"
ZRC="$HOME/.zshrc"
cmd="${1:-list}"; name="${2:-}"

list_profiles() {
  echo "[프로필 목록]"
  for d in "$HOME"/.claude "$HOME"/.claude-*; do
    [ -d "$d" ] || continue; case "$d" in *.bak-*) continue;; esac
    rel="${d#$HOME/}"; rel_esc=$(printf '%s' "$rel" | sed 's/\./\\./g')
    # 경로 정확 일치: CLAUDE_CONFIG_DIR=<path> 뒤에 공백(=다음 토큰 claude)이 와야 함 → .claude 가 .claude-personal 과 안 섞임
    al=$(grep -oE "alias [A-Za-z0-9_-]+='CLAUDE_CONFIG_DIR=(~|$HOME)/${rel_esc} claude'" "$ZRC" 2>/dev/null \
         | sed -E "s/alias ([^=]+)=.*/\1/" | head -1)
    if [ -L "$d/skills" ]; then sk="→정본"; else sk="$(ls "$d/skills" 2>/dev/null | wc -l | tr -d ' ')개"; fi
    [ "$d" = "$HOME/.claude" ] && al="${al:-(기본: 그냥 claude)}"
    printf "  %-22s skills:%-7s alias:%s\n" "${d/#$HOME/~}" "$sk" "${al:-(없음)}"
  done
}

add_profile() {
  [ -n "$name" ] || { echo "사용법: profile.sh add <name>"; exit 1; }
  local dir="$HOME/.claude-$name"
  [ -e "$dir" ] && { echo "이미 존재: ${dir/#$HOME/~}"; exit 1; }
  [ -d "$CANON" ] || { echo "정본 skills 없음: $CANON (먼저 consolidate)"; exit 1; }
  mkdir -p "$dir"
  ln -s "$CANON" "$dir/skills"
  echo "✅ 생성: ${dir/#$HOME/~}  (skills → ${CANON/#$HOME/~})"
  local alias_line="alias claude-$name='CLAUDE_CONFIG_DIR=~/.claude-$name claude'"
  if grep -qF "$alias_line" "$ZRC" 2>/dev/null; then
    echo "   alias 이미 있음: claude-$name"
  else
    [ -f "$ZRC" ] && cp "$ZRC" "$ZRC.bak-$(date +%s)"
    printf '\n# leafhub: %s 프로필\n%s\n' "$name" "$alias_line" >> "$ZRC"
    echo "   alias 추가: claude-$name  (.zshrc 백업됨)"
  fi
  echo "→ 적용: 새 터미널 또는  source ~/.zshrc"
  echo "→ 로그인: 'claude-$name' 실행 후 Claude에서 직접 로그인 (계정 인증은 수동)"
}

remove_profile() {
  [ -n "$name" ] || { echo "사용법: profile.sh remove <name>"; exit 1; }
  local dir="$HOME/.claude-$name"
  if grep -q "claude-$name" "$ZRC" 2>/dev/null; then
    cp "$ZRC" "$ZRC.bak-$(date +%s)"
    sed -i '' "/# leafhub: $name 프로필/d; /alias claude-$name=/d" "$ZRC"   # macOS BSD sed
    echo "✅ alias 제거: claude-$name  (.zshrc 백업됨)"
  else
    echo "alias 없음: claude-$name"
  fi
  if [ -d "$dir" ]; then
    echo "⚠️ 프로필 폴더는 보존(데이터 보호): ${dir/#$HOME/~}"
    echo "   완전 삭제 원하면 수동:  rm -rf '$dir'   (로그인·설정·히스토리 사라짐)"
  fi
}

case "$cmd" in
  list)   list_profiles ;;
  add)    add_profile ;;
  remove) remove_profile ;;
  *) echo "usage: profile.sh list | add <name> | remove <name>" ;;
esac
