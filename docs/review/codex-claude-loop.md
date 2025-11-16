# codex-claude-loop 리뷰

**작성일**: 2025-11-16
**카테고리**: AI 연동

---

## 목적과 목표

- Dual-AI 엔지니어링 루프: Claude Code(계획/구현) + Codex(검증/리뷰)
- 복잡도 기반 작업 분해 (Phase 0)
- 지속적 교차 검토
- 스마트 Task 분해

## 진행과정

1. 복잡도 평가 (0: Low/Medium/High)
2. 작업 분해 여부 결정 (Medium/High면 분해)
3. Claude가 계획 수립
4. Codex가 계획 검증
5. Claude가 구현
6. Codex가 코드 리뷰
7. 피드백 기반 개선 반복

## 레퍼런스

- Codex CLI 명령어 (`codex exec`, `codex exec resume --last`)
- AskUserQuestion 도구 사용
- TodoWrite로 진행 상황 추적

## 검증 및 진실성 분석

- ⚠️ **허위/오해의 소지**: "gpt-5" 또는 "gpt-5-codex"는 존재하지 않는 모델명
- ⚠️ `codex` CLI가 실제로 설치되어 있고 작동하는지 불확실
- ⚠️ Codex CLI의 `--sandbox read-only`, `resume --last` 등 옵션이 실제로 지원되는지 검증 필요
- ✅ Dual-AI 협업 개념 자체는 흥미롭고 유효
- ✅ 복잡도 기반 작업 분해 전략은 실용적
- ✅ TodoWrite 활용 제안은 적절

## 철학적 평가

**강점**: 두 AI 모델의 협업을 통한 품질 향상 아이디어

**약점**: 존재하지 않는 모델/CLI 기능 참조

**개선 필요**: 실제 사용 가능한 모델명과 CLI 옵션으로 수정

## 최종 등급

❌ **주요 허위** - 존재하지 않는 모델/도구 참조
