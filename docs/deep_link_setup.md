# 딥링크 설정 가이드

앱 링크(App Links)와 유니버설 링크(Universal Links)를 통한 딥링크 설정 가이드입니다.

## 개요

이 앱은 다음 두 가지 방식의 딥링크를 지원합니다:

1. **커스텀 스킴**: `splitbills://invite?code=ABC123`
2. **앱 링크/유니버설 링크**: `https://yourdomain.com/invite?code=ABC123`

## 설정 단계

### 1. 도메인 설정

`AndroidManifest.xml`과 `Info.plist`에서 `yourdomain.com`을 실제 도메인으로 변경하세요.

### 2. Android App Links 설정

#### 2.1 AndroidManifest.xml 확인

`android/app/src/main/AndroidManifest.xml`에 다음이 설정되어 있는지 확인:

```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="https"
        android:host="yourdomain.com"
        android:pathPrefix="/invite" />
</intent-filter>
```

#### 2.2 Digital Asset Links 파일 배포

웹 서버의 `https://yourdomain.com/.well-known/assetlinks.json` 경로에 다음 파일을 배포하세요:

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "io.splitbills.app",
      "sha256_cert_fingerprints": [
        "YOUR_SHA256_FINGERPRINT_HERE"
      ]
    }
  }
]
```

**SHA256 지문 확인 방법:**

```bash
# 디버그 키스토어
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# 릴리즈 키스토어
keytool -list -v -keystore your-release-key.keystore -alias your-key-alias
```

**중요:**
- Content-Type은 `application/json`이어야 합니다.
- HTTPS로만 제공되어야 합니다.
- HTTP 리다이렉트는 지원되지 않습니다.

### 3. iOS Universal Links 설정

#### 3.1 Info.plist 확인

`ios/Runner/Info.plist`에 다음이 설정되어 있는지 확인:

```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:yourdomain.com</string>
</array>
```

#### 3.2 Apple App Site Association 파일 배포

웹 서버의 `https://yourdomain.com/.well-known/apple-app-site-association` 경로에 다음 파일을 배포하세요:

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAM_ID.io.splitbills.app",
        "paths": [
          "/invite/*",
          "/group/join/*"
        ]
      }
    ]
  }
}
```

**중요:**
- Content-Type은 `application/json`이어야 합니다.
- 파일 확장자 없이 배포해야 합니다 (`.json` 없이).
- HTTPS로만 제공되어야 합니다.

**TEAM_ID 확인 방법:**
- Apple Developer 계정에서 확인
- 또는 Xcode에서 프로젝트 설정 확인

### 4. 웹 서버 설정

#### 4.1 웹 페이지 리다이렉트

앱이 설치되어 있지 않을 때 Play Store/App Store로 리다이렉트하는 웹 페이지를 배포하세요.

예제: `web/app_install_redirect.html`

#### 4.2 Nginx 설정 예제

```nginx
location /.well-known/apple-app-site-association {
    default_type application/json;
    add_header Content-Type application/json;
}

location /.well-known/assetlinks.json {
    default_type application/json;
    add_header Content-Type application/json;
}
```

#### 4.3 Apache 설정 예제

`.htaccess` 파일에 추가:

```apache
<Files "apple-app-site-association">
    Header set Content-Type "application/json"
</Files>

<Files "assetlinks.json">
    Header set Content-Type "application/json"
</Files>
```

## 지원하는 링크 형식

### 그룹 초대 링크

1. `splitbills://invite?code=ABC123`
2. `splitbills://invite/ABC123`
3. `https://yourdomain.com/invite?code=ABC123`
4. `https://yourdomain.com/invite/ABC123`
5. `https://yourdomain.com/group/join/ABC123`

### 홈 탭 링크

1. `splitbills://home?tab=groups`
2. `splitbills://home?tab=requests`
3. `https://yourdomain.com/home?tab=groups`

## 테스트

### Android 테스트

```bash
# ADB를 사용한 테스트
adb shell am start -W -a android.intent.action.VIEW -d "https://yourdomain.com/invite?code=TEST123" io.splitbills.app
```

### iOS 테스트

1. Safari에서 `https://yourdomain.com/invite?code=TEST123` 열기
2. 앱이 설치되어 있으면 자동으로 앱이 열립니다
3. 앱이 설치되어 있지 않으면 웹 페이지가 표시됩니다

## 문제 해결

### Android App Links가 작동하지 않는 경우

1. `adb shell pm get-app-links io.splitbills.app` 명령으로 확인
2. `adb shell pm set-app-links --package io.splitbills.app 0 all` 명령으로 재설정
3. `assetlinks.json` 파일이 올바르게 배포되었는지 확인
4. HTTPS로 제공되는지 확인

### iOS Universal Links가 작동하지 않는 경우

1. `apple-app-site-association` 파일이 올바르게 배포되었는지 확인
2. 파일 확장자가 없는지 확인
3. Content-Type이 `application/json`인지 확인
4. Associated Domains가 올바르게 설정되었는지 확인

## 참고 자료

- [Android App Links](https://developer.android.com/training/app-links)
- [iOS Universal Links](https://developer.apple.com/documentation/xcode/supporting-universal-links-in-your-app)
- [Digital Asset Links](https://developers.google.com/digital-asset-links/v1/getting-started)
- [Apple App Site Association](https://developer.apple.com/documentation/xcode/supporting-universal-links-in-your-app)

