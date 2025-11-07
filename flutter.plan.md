# Flutter 프로젝트 리팩토링 계획

## 1. 전체적인 구조 개선

### 1.1 레이어 구조 재구성
- **현재 문제**: 모든 코드가 `lib/features`와 `lib/common`에 혼재되어 있음
- **개선 방향**: Clean Architecture 기반 레이어 분리
  - `lib/core/` - 핵심 인프라 (에러 처리, 유틸리티, 상수)
  - `lib/data/` - 데이터 레이어 (Repository, 데이터 소스)
  - `lib/domain/` - 도메인 레이어 (비즈니스 로직, 엔티티)
  - `lib/presentation/` - 프레젠테이션 레이어 (페이지, 위젯, Provider)

### 1.2 main.dart 리팩토링
- **파일**: `lib/main.dart`
- **문제**: 딥링크 처리, 인증 콜백 등 비즈니스 로직이 700+ 라인에 집중
- **개선**:
  - 딥링크 처리를 `lib/core/deep_link/deep_link_handler.dart`로 분리
  - 인증 콜백 처리를 `lib/core/auth/auth_callback_handler.dart`로 분리
  - 초대 코드 처리를 `lib/core/invite/invite_handler.dart`로 분리
  - `main.dart`는 앱 초기화와 라우팅만 담당

### 1.3 Provider 정의 분리
- **현재 문제**: Provider가 서비스 파일에 섞여 있음
- **개선**: `lib/presentation/providers/` 디렉토리 생성
  - `auth_providers.dart`
  - `group_providers.dart`
  - `request_providers.dart`
  - `profile_providers.dart`
  - `bank_account_providers.dart`

## 2. 서비스 레이어 비즈니스 로직 분리

### 2.1 Repository 패턴 도입
- **현재 문제**: 서비스가 SupabaseClient에 직접 의존하고 데이터 접근과 비즈니스 로직이 혼재
- **개선**:
  - `lib/data/repositories/` 디렉토리 생성
  - 각 도메인별 Repository 인터페이스 정의 (`lib/domain/repositories/`)
  - Repository 구현체에서 Supabase 접근 로직만 담당
  - 서비스는 Repository를 통해 데이터 접근

### 2.2 에러 처리 통일
- **현재 문제**: 각 서비스마다 에러 처리 방식이 다름
- **개선**:
  - `lib/core/errors/` 디렉토리 생성
  - 커스텀 Exception 클래스 정의 (`AppException`, `NetworkException`, `AuthException` 등)
  - `lib/core/errors/error_handler.dart`에서 통일된 에러 처리 로직
  - 서비스에서 `Error.throwWithStackTrace` 대신 커스텀 Exception 사용

### 2.3 비즈니스 로직 분리
- **현재 문제**: 비즈니스 로직이 서비스와 위젯에 분산
- **개선**:
  - `lib/domain/usecases/` 디렉토리 생성
  - UseCase 클래스로 비즈니스 로직 캡슐화
  - 예: `CreateGroupUseCase`, `JoinGroupUseCase`, `CreateRequestUseCase`

### 2.4 서비스 레이어 정리
- **파일들**: `lib/common/services/*.dart`
- **개선**:
  - 서비스는 UseCase와 Repository를 조합하여 사용
  - 서비스는 프레젠테이션 레이어에서 직접 사용하지 않고, UseCase를 통해 접근
  - 또는 서비스를 UseCase로 대체

## 3. 공통 컴포넌트/유틸리티 구축

### 3.1 공통 위젯 생성
- **디렉토리**: `lib/presentation/widgets/common/`
- **컴포넌트**:
  - `ErrorView` - 에러 표시 위젯 (현재 `_GroupErrorView` 등 중복 제거)
  - `LoadingView` - 로딩 표시 위젯
  - `EmptyStateView` - 빈 상태 표시 위젯
  - `InfoRow` - 정보 행 표시 위젯 (현재 `_InfoRow` 중복 제거)
  - `RetryButton` - 재시도 버튼 위젯

### 3.2 유틸리티 함수
- **디렉토리**: `lib/core/utils/`
- **유틸리티**:
  - `date_formatter.dart` - 날짜 포맷팅 (현재 여러 곳에 중복)
  - `snackbar_helper.dart` - SnackBar 표시 헬퍼
  - `clipboard_helper.dart` - 클립보드 복사 헬퍼
  - `share_helper.dart` - 공유 기능 헬퍼
  - `currency_formatter.dart` - 통화 포맷팅

### 3.3 상수 정의
- **파일**: `lib/core/constants/`
- **상수**:
  - `app_constants.dart` - 앱 전역 상수
  - `route_constants.dart` - 라우트 경로 상수
  - `currency_constants.dart` - 통화 목록 상수 (현재 `GroupCreatePage`에 하드코딩)

## 4. 파일 구조 재구성

### 4.1 새로운 디렉토리 구조
```
lib/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── utils/
│   ├── deep_link/
│   └── auth/
├── data/
│   ├── repositories/
│   └── models/ (기존 common/models 이동)
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── features/ (기존 features 이동)
    ├── providers/
    └── widgets/
        └── common/
```

### 4.2 마이그레이션 순서
1. 공통 컴포넌트/유틸리티 생성 (기존 코드에 영향 없음)
2. Provider 분리
3. Repository 패턴 도입
4. UseCase 도입
5. main.dart 리팩토링
6. 기존 코드를 새 구조로 마이그레이션

## 5. 주요 변경 파일

### 5.1 새로 생성할 파일
- `lib/core/errors/app_exception.dart`
- `lib/core/errors/error_handler.dart`
- `lib/core/utils/date_formatter.dart`
- `lib/core/utils/snackbar_helper.dart`
- `lib/core/utils/clipboard_helper.dart`
- `lib/core/utils/share_helper.dart`
- `lib/core/constants/app_constants.dart`
- `lib/core/constants/route_constants.dart`
- `lib/core/constants/currency_constants.dart`
- `lib/presentation/widgets/common/error_view.dart`
- `lib/presentation/widgets/common/loading_view.dart`
- `lib/presentation/widgets/common/empty_state_view.dart`
- `lib/presentation/widgets/common/info_row.dart`
- `lib/core/deep_link/deep_link_handler.dart`
- `lib/core/auth/auth_callback_handler.dart`
- `lib/core/invite/invite_handler.dart`
- `lib/presentation/providers/auth_providers.dart`
- `lib/presentation/providers/group_providers.dart`
- `lib/presentation/providers/request_providers.dart`
- `lib/presentation/providers/profile_providers.dart`
- `lib/presentation/providers/bank_account_providers.dart`

### 5.2 리팩토링할 주요 파일
- `lib/main.dart` - 딥링크/인증 로직 분리
- `lib/common/services/*.dart` - Repository 패턴 적용
- `lib/features/group/group_page.dart` - 공통 컴포넌트 사용
- `lib/features/home/groups_tab.dart` - 공통 컴포넌트 사용
- `lib/features/group/group_create_page.dart` - 상수 사용

## 6. 우선순위

1. **1단계**: 공통 컴포넌트/유틸리티 구축 (기존 코드 영향 최소화)
2. **2단계**: Provider 분리 및 에러 처리 통일
3. **3단계**: Repository 패턴 도입
4. **4단계**: UseCase 도입 및 서비스 레이어 정리
5. **5단계**: main.dart 리팩토링 및 전체 구조 정리

