# Google Sign-In Setup Instructions

## 1. Firebase Console Setup
1. Go to https://console.firebase.google.com/
2. Create a new project or select existing project
3. Add Android app with package name: `com.example.street`
4. Download `google-services.json` file
5. Place it in `android/app/` directory

## 2. Android Configuration
Add to `android/app/build.gradle`:

```gradle
dependencies {
    implementation 'com.google.android.gms:play-services-auth:20.7.0'
}
```

Add to `android/build.gradle`:
```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.3.15'
}
```

Add to `android/app/build.gradle` (at the bottom):
```gradle
apply plugin: 'com.google.gms.google-services'
```

## 3. Enable Google Sign-In API
1. Go to Google Cloud Console
2. Enable Google Sign-In API for your project
3. Create OAuth 2.0 credentials for Android

## 4. SHA-1 Fingerprint
Get SHA-1 fingerprint:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Add this SHA-1 to Firebase project settings.

## 5. Backend Endpoint
The app expects a backend endpoint at `/auth/google` that:
- Accepts Google ID token and access token
- Verifies the token with Google
- Returns user data with JWT token

If this endpoint doesn't exist, the app will fallback to local authentication.