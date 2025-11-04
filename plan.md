# plan.md

# 프로젝트: splitBill (가제)
버전: 0.1.0  
작성일: 2025-11-04  
기준 문서: `AGENTS.md`

---

# 1. 목표

- MVP 수준의 Flutter 기반 그룹 정산 앱 완성
- Supabase 연동 및 실사용 가능한 정산 로직 구축
- Codex 자동화 운영 규칙 기반 개발 워크플로우 정착

---

# 2. 개발 단계

| 단계 | 기간 | 목표 | 상태 |
|------|------|------|------|
| **1단계. 인증 시스템 구축** | 2025-11-04 ~ 2025-11-10 | Google / Apple / Kakao OAuth 구현 | done |
| **2단계. 그룹 생성 및 초대 링크** | 2025-11-11 ~ 2025-11-15 | 그룹 생성, 초대 코드/딥링크 기능 구현 | done |
| **3단계. 지출 기록 기능** | 2025-11-16 ~ 2025-11-20 | Expense CRUD, 환율 변환 포함 | todo |
| **4단계. 정산 로직 구현** | 2025-11-21 ~ 2025-11-25 | 최소 송금 방식 계산 및 balances 표시 | todo |
| **5단계. 송금 요청 및 확인 시스템** | 2025-11-26 ~ 2025-11-30 | Request 등록, 송금 완료/거절/롤백 | todo |
| **6단계. UI/UX 완성 및 테스트** | 2025-12-01 ~ 2025-12-10 | 주요 화면 구성 및 e2e 테스트 | todo |
| **7단계. 배포 및 리뷰 자동화** | 2025-12-11 ~ 2025-12-15 | Codex 자동 PR/리뷰 파이프라인 구축 | todo |

---

# 3. 주요 태스크

## [Auth]
- [x] Google OAuth 연동
- [x] Apple OAuth 연동
- [x] Kakao OAuth 연동
- [x] 로그인 상태 감지 후 SplashPage → HomePage 라우팅  
  **담당:** `infra-agent`, `dev-agent`  
  **출력물:** 로그인 완료 후 Supabase `users` 테이블 등록

---

## [Group]
- [x] 그룹 생성 (이름, 기본 통화)
- [x] 초대 코드 자동 생성 (`UUID`)
- [x] 딥링크 → 앱 실행 후 자동 가입  
  **담당:** `dev-agent`  
  **테이블:** `groups`, `members`

---

## [Expense]
- [ ] ExpensePage UI 생성
- [ ] 지출자, 참여자, 금액, 날짜 입력 폼 구성
- [ ] 환율 변환 로직 (`exchange_rates`)
- [ ] Supabase insert / update / delete 연동  
  **담당:** `dev-agent`, `infra-agent`

---

## [Balance & Settlement]
- [ ] balances 계산 알고리즘 작성
    - 입력: `expenses`
    - 출력: `settlements`
- [ ] 최소 송금 방식 구현
- [ ] balances UI 갱신 (GroupPage 내)  
  **담당:** `dev-agent`  
  **검증:** `review-agent`

---

## [Request]
- [ ] RequestRegisterPage: 송금 요청 등록
- [ ] RequestListPage: 요청 목록 표시
- [ ] RequestPage: 송금 완료, 거절, 롤백
- [ ] 그룹 내 알림 처리 (Supabase Realtime)  
  **담당:** `dev-agent`, `infra-agent`

---

## [Profile]
- [ ] 프로필 조회/수정
- [ ] 은행 계좌 등록 (복수 가능)
- [ ] 계좌 복사 버튼 기능  
  **담당:** `dev-agent`

---

# 4. 인프라 및 보안

| 항목 | 설명 | 담당 | 상태 |
|------|------|------|------|
| Supabase Auth | OAuth redirect 및 세션 관리 | infra-agent | todo |
| Database Schema | users / groups / expenses / settlements 설계 | infra-agent | todo |
| Exchange API | ECB 환율 업데이트 스케줄러 | infra-agent | todo |
| 환경변수 관리 | `.env` 분리, gitignore 확인 | review-agent | todo |

---

# 5. 문서 관리

| 문서 | 역할 | 담당 |
|------|------|------|
| `AGENTS.md` | 프로젝트 구조, 역할 정의 | doc-agent |
| `plan.md` | 개발 일정 및 태스크 관리 | doc-agent |
| `README.md` | 사용자용 문서 | doc-agent |
| `PR 템플릿` | `.github/pull_request_template.md` 유지 | review-agent |

---

# 6. 워크플로우 규칙

- 모든 태스크는 **단일 목적**으로 PR 생성.
- PR 병합 후 `plan.md` 상태(`todo → in-progress → done`) 즉시 갱신.
- 리뷰 통과 전에는 main 병합 불가.
- Codex 자동화 태스크 수행 순서:
    1. `Auth`
    2. `Group`
    3. `Expense`
    4. `Balance & Settlement`
    5. `Request`
    6. `Profile`
    7. `Infra/Docs`

---

# 7. 품질 검증

| 항목 | 기준 |
|------|------|
| 빌드 | Flutter build 성공 |
| 코드 포맷 | `flutter format` 통과 |
| 테스트 | Unit + Widget Test 필수 |
| 리뷰 | `review-agent` 승인 후 병합 |
| 배포 | dev → main 수동 merge 후 TestFlight 배포 |

---

# 8. 최종 산출물

- Flutter 앱 (Android / iOS)
- Supabase DB Schema
- Codex 자동화 파이프라인 (PR, 리뷰, 배포)
- 문서 3종 (`AGENTS.md`, `plan.md`, `README.md`)

---

# 9. 상태 트래킹

| 태스크 | 담당 | 상태 |
|---------|--------|--------|
| Auth 구현 | infra-agent | done |
| 그룹 생성/초대 | dev-agent | done |
| Expense CRUD | dev-agent | todo |
| 정산 로직 | dev-agent | todo |
| 송금 요청/처리 | dev-agent | todo |
| 프로필 관리 | dev-agent | todo |
| 환율 API 연동 | infra-agent | todo |
| 문서 갱신 | doc-agent | todo |

---

# 10. 자동화 체크리스트

- [ ] PR 작성 시 `plan.md` 갱신 자동화
- [ ] PR 승인 시 `in-progress → done` 자동 전환
- [ ] 오류 발생 시 로그 자동 첨부
- [ ] dev 브랜치 기준 주기적 빌드 테스트

---

# 결론

이 `plan.md`는 Codex의 실행 우선순위 및 각 agent의 담당 영역을 명확히 정의한다.  
Codex는 이 문서를 기준으로 태스크를 실행하며, `AGENTS.md`의 역할 규칙을 따른다.
