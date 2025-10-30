# Tricount Clone Flutter App 개발 계획

## 1. 프로젝트 방향과 범위
- FlutterFlow 자산은 사용하지 않고, 순수 Flutter 코드베이스로 MVP를 구현한다.
- Supabase를 인증·데이터·실시간 동기화의 단일 백엔드로 삼고, FCM으로 지출/정산 알림을 보낸다.
- Google, Apple, Kakao, Naver OAuth를 지원하며, 다중 통화 정산과 Android/iOS 배포를 목표로 한다.
- 향후 확장 기능으로 정산 비율 랜덤 지정, 게임 기반 정산 보너스 시스템을 고려한다.

## 2. 아키텍처와 코드 조직
- `main.dart`를 진입점으로 유지하고, 각 OAuth 공급자용 인증 함수(google/apple/kakao/naver)를 동일 파일 내에서 정의·관리한다.
- 프레젠테이션 레이어는 `lib/` 하위에 `features/` 모듈 구조로 구성하고, 상태 관리는 Riverpod 기반으로 설계한다.
- 라우팅은 `go_router`를 사용하여 온보딩 → 그룹 → 지출 → 정산 플로우를 정의한다.
- 데이터 액세스 레이어는 Supabase SDK 추상화 서비스(`lib/services/`)와 도메인 모델(`lib/models/`)로 분리한다.
- FCM 및 딥링크 처리는 별도 유틸 모듈(`lib/utils/`)에서 관리하고, 테스트 가능한 순수 함수로 정산 알고리즘을 구현한다.

## 3. 데이터베이스 및 백엔드 연동
- README에 정의된 Supabase 스키마(profiles, groups, memberships, expenses, expense_splits, invites, exchange_rates, settlements)를 준수한다.
- 환율 스냅샷과 정산 결과(jsonb)를 기록하여 다중 통화 및 정산 이력 추적을 지원한다.
- RLS 정책을 통해 그룹/지출 레코드 접근을 제한하고, Edge Functions로 FCM 트리거를 구성한다.

## 4. 단계별 마일스톤
### Milestone 0 – 프로젝트 세팅
1. Flutter 프로젝트 의존성(go_router, flutter_riverpod, supabase_flutter, firebase_messaging 등)을 추가한다.
2. 환경 구성: Firebase/FCM 설정, Supabase 프로젝트 키 및 URL을 로컬 환경변수로 관리한다.
3. 기본 라우팅과 상태관리 스캐폴딩을 작성한다.

### Milestone 1 – 인증 및 온보딩
1. `main.dart`에 Google/Apple/Kakao/Naver OAuth 함수와 Supabase 세션 관리 로직을 구현한다.
2. 온보딩/로그인 UI와 프로필 설정 화면을 제작한다.
3. 로그인 상태에 따른 라우팅 보호(가드)를 설정한다.

### Milestone 2 – 그룹 및 지출 기능
1. 그룹 CRUD, 멤버 초대(딥링크), 역할 관리를 구현한다.
2. 지출 등록/수정/삭제와 참여자 분배 UI를 완성한다.
3. 환율 스냅샷 저장과 최소 송금 정산 알고리즘을 연동한다.

### Milestone 3 – 실시간 동기화와 알림
1. Supabase Realtime으로 그룹/지출 업데이트를 구독한다.
2. Edge Function 또는 Cloud Function을 통해 FCM 지출/정산 알림을 전송한다.
3. 초대 코드 만료 및 딥링크 처리 로직을 보강한다.

### Milestone 4 – QA, 배포, 확장 준비
1. 자동화/수동 QA 시나리오를 마련하고, Android/iOS 빌드 파이프라인을 구성한다.
2. Supabase RLS/보안 점검을 수행하고 로그/모니터링 설정을 완료한다.
3. 향후 기능(랜덤 정산 %, 게임 기반 보너스)을 위한 도메인 모델과 UX 아이디어를 백로그에 정리한다.

## 5. 장기 개선 로드맵
- 정산 결과 시각화, 오프라인 모드, 추가 결제 연동 등 README에 기재된 항목을 지속적으로 개선한다.
- 정산 게임화 기능을 실험하여 사용자 참여도를 높이고, 실시간 이벤트 처리와 연동 방식을 검토한다.

## 6. 참고 문서
- `README.md`: 프로젝트 개요, 기술 스택, 데이터베이스 구조, 배포 전략.
- Supabase 문서: Auth, Database, Realtime, Edge Functions.
- Firebase 문서: FCM, Android/iOS 설정.
