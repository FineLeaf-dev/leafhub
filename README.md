# 🍃 leafhub

> **Claude Code 프로필을 한곳에서 관리하는 허브.** 여러 프로필에 흩어진 스킬을 진단·통합하고, 프로필 생성·관리까지.

Claude Code를 여러 계정(개인/회사)으로 쓰면, 계정마다 스킬·설정이 **따로 논다.** 한쪽에 깐 스킬이 다른 쪽엔 안 보이는 "어디 있고 없고" 문제. `leafhub`는 이걸 **진단 → 통합(정본 1개 + 심볼릭) → 프로필 관리**로 해결한다.

---

## 🧠 먼저: "프로필"이 뭔가?

Claude Code는 **`CLAUDE_CONFIG_DIR` 환경변수**가 가리키는 폴더에서 *로그인(계정)·설정·스킬·히스토리*를 읽는다. **이 폴더를 바꾸면 완전히 다른 Claude 환경** = 프로필이 된다.

| 환경변수 값 | = 프로필 |
|---|---|
| `~/.claude` (기본) | 그냥 `claude` 실행 시 |
| `~/.claude-personal` | 개인 계정 |
| `~/.claude-company` | 회사 계정 |

각 폴더 안에 `skills/`가 따로 있어서, **스킬도 프로필마다 분리**된다. ← 이게 leafhub가 푸는 문제.

---

## 🎬 따라하기 — 개인 계정 + 회사 계정으로 나눠 쓰기

### Step 1. 두 계정을 프로필로 정의

**방법 A — leafhub로 자동 (권장):**
```bash
bash scripts/profile.sh add personal   # ~/.claude-personal 생성 + alias + skills 연결
bash scripts/profile.sh add company     # ~/.claude-company  생성 + alias + skills 연결
source ~/.zshrc                          # alias 적용
```

**방법 B — 직접 `~/.zshrc`에:**
```bash
alias claude-personal='CLAUDE_CONFIG_DIR=~/.claude-personal claude'
alias claude-company='CLAUDE_CONFIG_DIR=~/.claude-company claude'
```
> `CLAUDE_CONFIG_DIR=~/.claude-personal claude` = "이번 실행만 개인 폴더로 Claude 켜기". 그래서 `claude-personal`은 개인 계정, `claude-company`는 회사 계정으로 열린다.

이제 터미널에서:
```bash
claude-personal    # 개인 계정으로 Claude Code
claude-company     # 회사 계정으로 Claude Code
```
각 계정은 **처음 한 번 로그인**하면 그 폴더에 인증이 저장된다. (로그인은 수동 — 자동화 불가)

### Step 2. 문제 확인 — 스킬이 따로 논다

개인 계정에서 스킬 `foo`를 깔았는데, 회사 계정엔 안 보인다. 왜냐면 `~/.claude-personal/skills/`와 `~/.claude-company/skills/`가 **별개 폴더**라서. 현황을 보자:
```bash
bash scripts/diagnose.sh
```
```
[탐지된 설정 디렉토리]
  ~/.claude            12개 (실폴더)   (정본·기본 — 모든 프로필 공유)
  ~/.claude-personal   5개 (실폴더)    (alias 사용)     ← 여기만 foo 있음
  ~/.claude-company    3개 (실폴더)    (alias 사용)     ← foo 없음

[중복 스킬 — 같은 이름이 2곳 이상 '실폴더' = 드리프트 위험]
  ⚠️  storm :
       - ~/.claude-personal (real)
       - ~/.claude-company (real)
```

### Step 3. 통합 — 한 번 깔면 모든 계정에서 보이게

```bash
bash scripts/consolidate.sh ~/.claude/skills ~/.claude-personal/skills ~/.claude-company/skills
```
- 각 프로필 `skills/`를 **자동 백업**
- 흩어진 스킬을 **정본 한곳(`~/.claude/skills`)으로 모음** (중복은 정본 우선)
- 두 프로필의 `skills/`를 **정본을 가리키는 심볼릭**으로 교체

재진단하면:
```
  ~/.claude            17개 (실폴더)   (정본·기본 — 모든 프로필 공유)
  ~/.claude-personal   → 정본: ~/.claude/skills   (정본 링크)
  ~/.claude-company    → 정본: ~/.claude/skills   (정본 링크)
```
**이제 어느 계정에서 스킬을 깔든 `~/.claude/skills`에 들어가고, 세 곳 모두에서 보인다.** (새 세션부터 반영)

### Step 4. 계정 추가는 한 줄

회사2 계정이 생겼다면:
```bash
bash scripts/profile.sh add company2     # 폴더+alias+skills연결 자동
source ~/.zshrc
claude-company2                          # 켜서 로그인만 하면 끝 (스킬은 이미 공유됨)
```

---

## 🎬 시나리오 2 — 한 레포, 여러 터미널, 각각 다른 계정

같은 프로젝트에서 터미널을 여러 개 띄우고, 터미널마다 다른 계정으로 Claude를 돌리는 경우:

```
~/work/myrepo 에서:
  터미널 A>  claude-personal     # 개인 계정
  터미널 B>  claude-company      # 회사 계정  (동시에)
```

- alias는 **그 실행에만** `CLAUDE_CONFIG_DIR`를 설정 → 터미널마다 **독립적으로** 계정이 정해진다(서로 안 샘).
- leafhub로 통합해두면 **A·B가 똑같은 스킬**을 본다(둘 다 `skills/` → 정본). 계정만 다르고 도구는 일관.
- 인증·히스토리는 각자 자기 CONFIG_DIR에 저장 → **계정 정보는 안 섞임.**
- 프로젝트 스킬(`myrepo/.claude/skills`)도 프로필 무관이라 양쪽 다 보인다.

> **"계정은 분리, 스킬은 통일."** 정확히 이 상황에서 leafhub가 빛난다.
> ⚠️ A·B가 *같은 파일을 동시에 편집*하면 충돌할 수 있다 — 이건 계정이 아니라 동시작업 문제. 필요하면 터미널별로 `git worktree`/브랜치를 쓴다. (스킬 일관성 = leafhub, 동시편집 = git)

## 왜 통합이 "정본 + 심볼릭"인가

| 종류 | 공유 방식 |
|------|-----------|
| 사용자 스킬 (`CONFIG_DIR/skills`) | **프로필별 분리** ← leafhub가 푸는 문제 |
| 프로젝트 스킬 (`<repo>/.claude/skills`) | 프로필 무관, 그 repo에서만 |
| 플러그인 | 별도 |

정본 1곳에 실파일을 두고 각 프로필을 심볼릭으로 연결 → **실파일 1벌, 모든 프로필 자동 공유, 드리프트 0.**
> 개별 스킬 심볼릭·복사는 임시방편(드리프트·관리지옥). **정본 1개 + 디렉토리 심볼릭**이 정석.

## 명령 레퍼런스

| 명령 | 하는 일 | 파괴적? |
|------|---------|:---:|
| `bash scripts/diagnose.sh` | CONFIG_DIR·스킬 위치·**중복·고아** 진단 | 비파괴 |
| `bash scripts/consolidate.sh <정본> <프로필...>` | 백업 → 정본 모음 → 프로필 심볼릭 | ⚠️ 예 (백업) |
| `bash scripts/profile.sh list` | 프로필·alias 목록 | 비파괴 |
| `bash scripts/profile.sh add <name>` | `~/.claude-<name>` 생성 + alias + skills 연결 | 안전 |
| `bash scripts/profile.sh remove <name>` | alias 제거(폴더는 보존) | alias만 |

Claude에게 자연어로도 가능: `/leafhub`, "스킬 통합 관리", "프로필마다 스킬이 다르다", "Claude 프로필 추가".

## 설치

```bash
skills add FineLeaf-dev/leafhub          # Claude Code에서
```
또는 clone 후 심볼릭:
```bash
git clone https://github.com/FineLeaf-dev/leafhub.git
ln -s "$(pwd)/leafhub" ~/.claude/skills/leafhub
```

## ⚠️ 주의

- **지원: macOS / Linux / WSL** (zsh 기준). **Windows 네이티브(PowerShell) 미지원** — WSL 권장.
- `consolidate`·`profile remove`는 **`rm -rf`·`.zshrc` 편집** 수행. 스크립트가 **자동 백업**(`*.bak-<timestamp>`)하지만 실행 전 내용 확인.
- 프로필 폴더(`~/.claude-<name>`)는 `remove` 시에도 **자동 삭제 안 함**(로그인·히스토리 보호).
- 통합/추가 후 스킬 목록은 **새 세션부터** 반영.

## 누구에게 유용한가

- 🟢 **Claude 계정을 여러 개 쓰는 사람**(개인/회사 분리 등) — 정확히 이 페인 해결
- 🟡 단일 계정 사용자 — `diagnose`로 "내 스킬 어디 있나" 확인 정도

## 로드맵

- [ ] Windows 네이티브(PowerShell + junction) 지원
- [ ] 멀티 도구 어댑터 — Codex CLI(`~/.codex`) 등 다른 AI CLI 프로필도 같은 "정본 허브"로
- [ ] 프로필 전환 헬퍼 통합

> "여러 프로필 = 정본 1개 + 심볼릭" 아이디어는 도구 불문 통하지만, 도구마다 설정 레이아웃이 달라 전용 어댑터가 필요. 현재는 Claude Code 전용.

## License

[MIT](./LICENSE)
