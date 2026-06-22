---
name: leafhub
description: 여러 Claude Code 프로필(CLAUDE_CONFIG_DIR — 예 ~/.claude, ~/.claude-personal, ~/.claude-company)에 흩어진 사용자 스킬을 진단·통합하고, 프로필 자체를 생성/목록/삭제 관리한다. 어느 스킬이 어디 있고/없는지·중복(드리프트)·고아를 표로 보여주고, 백업 후 모든 프로필을 하나의 정본 라이브러리에 심볼릭으로 묶는다. Use when 사용자가 "/leafhub", "스킬 통합 관리", "프로필 스킬 정리", "스킬이 어디 있고 없고", "프로필마다 스킬이 다르다", "Claude 프로필 추가/관리"라고 할 때.
allowed-tools: Bash, Read, AskUserQuestion
---

# leafhub — Claude 프로필 스킬 통합·관리

`CLAUDE_CONFIG_DIR`마다 `skills/`가 따로라 스킬이 프로필별로 다르게 보인다. 진단 → (승인 후) 정본 1개로 통합 → 프로필 생성/관리까지.

> 🖥️ **지원: macOS / Linux / WSL** (zsh 기준). Windows 네이티브(PowerShell)는 미지원 — WSL 사용 권장.
> 스킬 디렉토리 = 설치 위치(보통 `~/.claude/skills/leafhub`). 아래 명령의 `<DIR>`는 그 경로.

## 🚫 안전 원칙
- **진단은 비파괴** — 먼저 `diagnose.sh`만 돌려 현황 보고.
- **통합·프로필삭제는 파괴적**(`rm -rf`, `.zshrc` 편집) → **반드시 백업 + AskUserQuestion 승인 후** 실행. 자동 실행 금지.
- 정본은 보통 `~/.claude/skills`. **자기경로 하드코딩 스킬**(예: SKILL.md에 절대경로 박은 것) 이동 시 깨질 수 있음 → "그 위치를 정본으로" 권장.

## 워크플로우

### 1) 진단 (항상 먼저, 비파괴)
```bash
bash <DIR>/scripts/diagnose.sh
```
→ 탐지된 CONFIG_DIR·각 skills 항목수·실폴더/심볼릭·**중복(드리프트)**·**고아**를 표로 보고.

### 2) 통합 (승인 후)
```bash
bash <DIR>/scripts/consolidate.sh <정본skills> <프로필skills...>
# 예) consolidate.sh ~/.claude/skills ~/.claude-personal/skills ~/.claude-company/skills
```
→ 각 프로필 skills 백업 → 정본에 없는 실폴더 스킬을 정본으로 이동 → 프로필 skills/를 정본 단일 심볼릭으로 교체. **정본은 안 건드림.**

### 3) 프로필 관리 (macOS/zsh)
```bash
bash <DIR>/scripts/profile.sh list            # 프로필·alias 목록
bash <DIR>/scripts/profile.sh add <name>      # ~/.claude-<name> 생성 + alias + skills 정본 심볼릭
bash <DIR>/scripts/profile.sh remove <name>   # alias 제거(.zshrc 백업), 폴더는 보존
```
- `add`: 새 프로필 skills/를 **정본 심볼릭** → 만들자마자 전 프로필과 공유. `.zshrc` alias는 백업·중복방지 후 추가. **로그인은 수동**.
- `remove`: alias만 제거. **프로필 폴더는 자동 삭제 안 함**(로그인·히스토리 보호).

### 4) 검증
```bash
bash <DIR>/scripts/diagnose.sh   # 통합/추가 후 재진단 — 모든 프로필이 정본 가리키는지 확인
```

## 핵심 개념 (설명용)
- **사용자 스킬 = CONFIG_DIR별로 따로** → 프로필 간 공유 안 됨(혼란의 근원).
- **프로젝트 스킬(`<repo>/.claude/skills`)·플러그인 = 프로필 무관 로드** → 항상 보임.
- 통합 후 **세션 재시작** 시 반영(실행 중 세션엔 즉시 X).
- 정본 1개 + 디렉토리 심볼릭 = 드리프트 0. (개별 스킬 심볼릭·복사는 임시방편)
