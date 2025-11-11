# 안드로이드 가상기기에서 구글 OAuth 로그인 실패 해결 가이드

## 문제 증상
- 카카오 로그인은 정상 작동
- 구글 로그인 시 404 에러 또는 로그인 실패

## 중요: Supabase OAuth 설정 방식

**Supabase에서 OAuth를 사용할 때는 웹 애플리케이션(Web application) 타입의 OAuth 클라이언트 ID를 사용해야 합니다.**

Supabase OAuth 흐름:
1. 앱 → Supabase로 OAuth 요청 (`redirectTo: splitbills://auth/google`)
2. Supabase → Google로 리다이렉트 (웹 애플리케이션 클라이언트 ID 사용)
3. Google → Supabase 콜백 URL로 리다이렉트
4. Supabase → 앱으로 딥링크 리다이렉트 (`splitbills://auth/google`)

따라서 **안드로이드 앱의 SHA-1 지문은 필요하지 않습니다**. Supabase가 중간 프록시 역할을 하기 때문입니다.

## 해결 방법

### 1. Google Cloud Console에서 웹 애플리케이션 OAuth 클라이언트 생성

1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. 프로젝트 선택
3. **APIs & Services** → **Credentials** 이동
4. **+ CREATE CREDENTIALS** → **OAuth client ID** 클릭
5. **Application type**: **Web application** 선택 ⚠️ (Android가 아님!)
6. **Name**: 원하는 이름 입력 (예: "SplitBills Web OAuth")
7. **Authorized redirect URIs** 섹션에서 **+ ADD URI** 클릭
8. Supabase 콜백 URL 추가:
   ```
   https://[your-project-ref].supabase.co/auth/v1/callback
   ```
   - `[your-project-ref]`는 Supabase 프로젝트 URL에서 확인 가능
   - 예: `https://abcdefghijklmnop.supabase.co/auth/v1/callback`
9. **CREATE** 클릭
10. 생성된 **Client ID**와 **Client Secret** 복사 (나중에 Supabase에 등록)

### 2. Supabase Dashboard에 클라이언트 정보 등록

1. [Supabase Dashboard](https://app.supabase.com/) 접속
2. 프로젝트 선택
3. **Authentication** → **Providers** → **Google** 이동
4. 다음 항목 설정:
   - ✅ **Enabled** 체크박스 활성화
   - ✅ **Client ID (for OAuth)**: 위에서 생성한 웹 애플리케이션의 Client ID 입력
   - ✅ **Client Secret (for OAuth)**: 위에서 생성한 웹 애플리케이션의 Client Secret 입력
5. **Save** 클릭

### 3. Google Cloud Console에서 Authorized redirect URIs 확인

1. Google Cloud Console → **APIs & Services** → **Credentials** 이동
2. 위에서 생성한 **웹 애플리케이션 OAuth 클라이언트** 선택
3. **Authorized redirect URIs**에 다음이 포함되어 있는지 확인:
   ```
   https://[your-project-ref].supabase.co/auth/v1/callback
   ```
   - 없으면 추가하고 저장

### 4. AndroidManifest.xml 확인

`android/app/src/main/AndroidManifest.xml` 파일에 다음 intent-filter가 있는지 확인:

```xml
<!-- ✅ Google OAuth Redirect -->
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="splitbills" android:host="auth" android:path="/google" />
</intent-filter>
```

### 5. 앱 재빌드 및 테스트

1. 앱 완전 종료
2. 프로젝트 클린:
   ```bash
   flutter clean
   flutter pub get
   ```
3. 앱 재빌드 및 실행:
   ```bash
   flutter run
   ```
4. 구글 로그인 버튼 클릭하여 테스트
5. **5-10분 대기** 후 다시 시도 (Google Cloud Console 변경사항 반영 시간)

## 여전히 문제가 발생하는 경우

1. **캐시 정리**: Google Play Services 캐시 삭제
2. **가상기기 재시작**: 에뮬레이터 완전 재시작
3. **로그 확인**: Flutter 로그에서 구체적인 에러 메시지 확인
   ```bash
   flutter run --verbose
   ```
4. **Supabase 로그 확인**: Supabase Dashboard → Logs → Auth 로그 확인

## 참고 자료

- [Google OAuth Android 설정 가이드](https://developers.google.com/identity/sign-in/android/start-integrating)
- [Supabase Google OAuth 문서](https://supabase.com/docs/guides/auth/social-login/auth-google)

