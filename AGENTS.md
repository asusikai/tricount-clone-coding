# 프로젝트 개요

**프로젝트명:** splitBills (가제)

**목표:** 사용자가 손쉽게 그룹 내 지출을 기록하고 최소 송금 방식으로 정산할 수 있는 모바일 애플리케이션.

**핵심 가치:**

- 다중 통화 기반의 정확한 정산
- 간편한 로그인 및 그룹 초대
- 자동 송금 및 실시간 정산 상태 추적

---

# 기술 스택

| 구분 | 내용 |
| --- | --- |
| 프레임워크 | Flutter |
| 백엔드 | Supabase (PostgreSQL + Auth + Realtime) |
| 형상관리 | GitHub |
| 배포 | GitHub Actions → TestFlight / Google Play Internal Test |
| 인증 | Google / Apple / Kakao OAuth |
| 결제 연동 | 카카오페이 / 토스페이 / 은행 API (차후) |

---

# MVP 범위

1. **OAuth 로그인:** Google, Apple, Kakao 계정으로 인증.
2. **그룹 관리:** 이름 및 기본 통화 지정, 초대 링크 자동 생성.
3. **초대 기능:** 링크 클릭 → 앱 실행 및 자동 가입 (미설치 시 설치 유도).
4. **지출 등록:** 날짜, 금액, 통화, 부담자 및 분담 비율 입력.
5. **정산 계산:** N분의 1 자동 분배 및 최소 송금 방식 계산.
6. **정산 처리:** 송금 완료 버튼으로 상태 변경 및 롤백 가능.
7. **송금 기능:** 카카오페이/토스페이/은행 연동 자동 송금.

---

# 페이지 구조

| 페이지명 | 주요 기능 |
| --- | --- |
| **SplashPage** | 로그인 상태 확인 후 AuthPage 또는 HomePage로 라우팅 |
| **AuthPage** | 튜토리얼 카드 및 OAuth 로그인 버튼 제공 |
| **HomePage** | 가입 그룹 리스트, 정산 상태별 섹션, 그룹 추가 및 하단 네비게이션 |
| **GroupPage** | 지출/잔액 섹션, 날짜별·사용자별 지출 내역, 그룹 설정 |
| **ExpensePage** | 지출 등록 및 수정, 분담 비율 계산, 환율 변환 |
| **RequestRegisterPage** | 자동 계산된 송금 요청 생성 및 상태 변경 |
| **RequestListPage** | 요청 내역 목록화, 송금 상태별 필터링 |
| **RequestPage** | 송금 완료/거절/롤백 처리, 계좌 복사 기능 |
| **ProfilePage** | 실명, 닉네임, 은행 계좌 관리 |

---

# 데이터 구조

| 테이블 | 필드 | 설명 |
| --- | --- | --- |
| `users` | `id`, `email`, `name`, `provider` | 사용자 정보 |
| `groups` | `id`, `name`, `invite_code`, `created_at` | 그룹 정보 및 초대 코드 |
| `members` | `id`, `user_id`, `group_id`, `joined_at` | 그룹-사용자 매핑 |
| `expenses` | `id`, `group_id`, `payer_id`, `amount`, `description`, `date`, `participants[]` | 지출 내역 |
| `settlements` | `id`, `group_id`, `from_user`, `to_user`, `amount` | 정산 결과 |
| `exchange_rates` | `currency`, `rate`, `updated_at` | 환율 정보 (ECB 기준) |

### 관계 정의

- users 1 : N members
- groups 1 : N members
- groups 1 : N expenses
- expenses N : N users (participants)
- settlements N : 1 groups
- exchange_rates 1 : N expenses

---

# Codex 운영 규칙

## 실행 우선순위

- Codex는 `plan.md` 내 정의된 우선순위를 기반으로 태스크를 실행.
- 태스크 상태는 `todo → in-progress → done`만 사용.
- 에이전트는 `AGENTS.md` 내 역할 정의에 따라 자동 선택.

## 브랜치 및 PR

- 모든 변경은 **별도 브랜치**에서 수행.
- **main 직접 커밋 금지**, 필요 시 `dev`까지 허용.
- PR 단위 변경 원칙:
    - 단일 목적
    - 종속성 최소화
    - 한글 작성
- PR 제출 시 **변경 목적 / 변경 내용 / 영향 범위 / 테스트 여부** 명시.

### PR 네이밍 규칙

형식: `type(scope): description`

- type:
    - feat — 기능 추가
    - fix — 버그 수정
    - chore — 설정/빌드 관련
    - refactor — 구조 개선 (기능 변경 없음)
    - docs — 문서 수정
    - test — 테스트 코드
    - style — 코드 포맷

예시:

`feat(auth): 카카오 로그인 기능 추가`

### PR 본문

```markdown
### Title
feat(expense): 지출 등록 기능 구현

### Description
- Supabase expenses 테이블에 insert 기능 추가
- 금액/통화 변환 로직 작성
- 등록 후 GroupPage balances 자동 업데이트

### Impact
- ExpensePage, GroupPage

### Test
- Flutter run 및 Supabase insert 테스트 완료

### Checklist
- [ ] 빌드 확인
- [ ] 린트 통과
- [ ] 문서 업데이트
- [ ] 리뷰어 지정
```

### 리뷰 및 병합
모든 PR은 review-agent 승인 후 병합.

리뷰 결과는 plan.md 태스크 상태에 반영.

승인된 PR만 dev → main 병합 허용.

### 오류 처리
오류 발생 시 Codex가 로그 기록 및 원인 요약.

해결 불가능 시 blocked 상태 전환.

### 보안 규칙
API 키, 토큰, 환경 변수는 절대 커밋 금지.

.env, supabase/config 등은 .gitignore에 포함.

## AGENT 역할 정의
### 에이전트	역할	주요 책임
| 에이전트             | 역할                    | 주요 책임                             |
| ---------------- | --------------------- | --------------------------------- |
| **dev-agent**    | Flutter 및 Supabase 개발 | 코드 작성, 테스트, 릴리즈 준비                |
| **review-agent** | 코드 품질 및 규칙 검증         | PR 리뷰, 포맷 검사, 병합 승인               |
| **infra-agent**  | Supabase 및 Auth 설정 관리 | DB 스키마, RLS 정책, OAuth 연동          |
| **design-agent** | UI/UX 구조 관리           | 페이지 구성, 컴포넌트 일관성 유지               |
| **doc-agent**    | 문서 유지                 | `AGENTS.md`, `plan.md`, API 문서 갱신 |


## 버전 관리 규칙
| 브랜치         | 용도       |
| ----------- | -------- |
| `main`      | 안정 배포 버전 |
| `dev`       | 통합 테스트용  |
| `feature/*` | 기능별 개발   |
| `fix/*`     | 버그 수정    |
| `docs/*`    | 문서 갱신    |


## 환경 관리
| 항목                   | 내용                                         |
| -------------------- | ------------------------------------------ |
| `.env`               | Supabase URL, anon key, OAuth redirect URL |
| `lib/config/`        | 환경별 설정 분리 (`dev`, `prod`)                  |
| Firebase Crashlytics | 런타임 오류 수집 (선택사항)                           |


## 결론
Codex는 plan.md를 기준으로 실행 순서를 자동 관리하고,
AGENTS.md를 기반으로 역할별 책임을 분리한다.
모든 작업은 PR 단위로 검증되며,
승인 후 dev → main 단계로 병합되어야 한다.
---
