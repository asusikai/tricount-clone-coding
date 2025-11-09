# Tricount Clone Flutter App

## 프로젝트 개요
Tricount와 유사한 그룹 비용 정산 앱의 MVP를 Flutter로 구현합니다. FlutterFlow에서 제작한 프로토타입을 기반으로 순수 Flutter 프로젝트로 리팩터링하고, Supabase와 FCM을 활용해 인증과 푸시 알림을 통합적으로 처리합니다.

## 환경 변수 설정
- 루트의 `.env.example`을 참고해 `assets/env/.env` 파일을 생성하고 Supabase URL, anon key, redirect URI를 채워주세요.
- 환경별로 다른 값을 사용하려면 `assets/env/.env.dev`, `assets/env/.env.prod` 파일을 추가하고 필요 시 `flutter run --dart-define=APP_ENV=prod`처럼 `APP_ENV` 값을 지정합니다 (기본값은 `dev`).
- 모든 `.env` 파일은 `.gitignore` 대상이므로 개인 환경에서만 유지되며, CI에서는 빌드 전에 파일을 생성해야 합니다.
- GitHub Actions 예시:
  ```yaml
  - name: Setup environment
    run: |
      mkdir -p assets/env
      cat <<'EOF' > assets/env/.env
      SUPABASE_URL=${{ secrets.SUPABASE_URL }}
      SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}
      SUPABASE_REDIRECT_URI=${{ secrets.SUPABASE_REDIRECT_URI }}
      EOF
  ```

## 목표
- FlutterFlow 프로토타입을 Export 후 리팩터링하여 프로덕션 레벨 Flutter 앱 개발
- Supabase를 이용해 Auth, DB, 실시간 동기화 환경 구성
- FCM으로 지출 및 정산 알림 처리
- 다양한 OAuth 제공자(Google, Apple, Kakao, Naver) 연동
- 환율 스냅샷 기반 다중 통화 정산 지원
- Android / iOS 배포(Play Console, TestFlight)

## 기술 스택
- **Frontend/UI**: Flutter (FlutterFlow 프로토타입 기반)
- **Backend**: Supabase (Auth, Postgres, RLS, Realtime)
- **Push Notification**: Firebase Cloud Messaging (FCM)
- **Auth Providers**: Google, Apple, Kakao, Naver (각 Flutter SDK 직접 연동)
- **환율 API**: Frankfurter 또는 exchangerate.host (일 단위 스냅샷 저장)
- **Deployment**: Android (Play Console), iOS (TestFlight)

## 데이터베이스 구조 (Supabase)
```sql
profiles
- id (uuid) PK
- display_name
- avatar_url

groups
- id PK
- name
- base_currency
- owner_id (FK → profiles)

memberships
- id PK
- group_id FK
- user_id FK
- role (enum: owner/member)

expenses
- id PK
- group_id FK
- payer_id FK
- amount
- currency
- paid_at
- fx_rate_to_base

expense_splits
- id PK
- expense_id FK
- member_id FK
- share_amount_in_base

invites
- id PK
- group_id FK
- code (uuid)
- expires_at

exchange_rates
- rate_date
- base_code
- quote_code
- rate

settlements
- id PK
- group_id FK
- result (jsonb)
```

## 핵심 서비스 흐름
1. 온보딩 및 로그인 (OAuth 지원)
2. 그룹 생성 또는 기존 그룹 선택
3. 멤버 초대 (딥링크 기반)
4. 지출 등록 (제목, 금액, 결제자, 참여자, 분배 방식)
5. 통화 변환 및 환율 스냅샷 저장
6. 최소 송금 알고리즘을 통한 잔액 정산
7. 송금 링크 공유 (Toss, KakaoPay 등)
8. 푸시 알림 또는 실시간 동기화 반영

## FlutterFlow → 순수 Flutter 전환 플랜
1. FlutterFlow에서 UI, CRUD 플로우, Mock 로그인 구성
2. 프로젝트 Export 후 Git 저장소에 반영
3. 패키지 추가
   - `flutter_riverpod`
   - `go_router`
   - `firebase_messaging`
   - `google_sign_in`
   - `sign_in_with_apple`
   - `kakao_flutter_sdk_user`
   - `flutter_naver_login`
   - `intl`
   - `supabase_flutter`
4. 기능 구현 순서
   1. Supabase Auth 연동
   2. Google/Apple/Kakao/Naver OAuth 통합
   3. 그룹 및 지출 CRUD
   4. 정산 알고리즘(Dart 함수) 구현
   5. 환율 API 데이터를 Supabase에 저장
   6. FCM 푸시 알림 (Supabase Edge Function 또는 Cloud Function)
   7. Deep Link 처리 (`uni_links`)

## 배포 및 운영 계획
- Android: Google Play Console을 통한 배포
- iOS: TestFlight을 통한 베타 테스트
- 릴리즈 전 수동 QA 및 자동화 테스트 플랜 마련
- Supabase RLS 정책 검토 및 보안 강화

## 향후 과제
- 정산 결과 시각화 및 공유 기능 강화
- 오프라인 지원 및 데이터 동기화 개선
- 추가 결제 연동(Toss Payments, KakaoPay 등)
- 사용자 피드백 기반 UI/UX 개선
