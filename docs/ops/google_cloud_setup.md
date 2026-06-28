# Google Cloud OAuth Setup for Release Builds

## The Problem
Google Sign-In works in debug but fails in release with API Exception 10.
This is because the release APK is signed with a different key, producing a different SHA-1 fingerprint.

---

## Step 1: Create the Release Keystore & Configure Gradle

An upload keystore has been created at `android/app/upload-keystore.jks` using the following command:

```powershell
keytool -genkeypair -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storepass gymlog123 -keypass gymlog123 -dname "CN=Atharva Patil, O=GymLog, C=US"
```

The signing configuration has been created at `android/key.properties`:

```properties
storePassword=gymlog123
keyPassword=gymlog123
keyAlias=upload
storeFile=upload-keystore.jks
```

### Gradle Configuration
The `android/app/build.gradle.kts` file has been configured to read from `android/key.properties` and apply the release signing configuration automatically:

```kotlin
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ...
    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}
```

---

## Step 2: Get Your SHA-1 Fingerprints (Debug and Release)

To configure Google Sign-In, both your local debug signature and your production/release signatures must be added to the Google Cloud Console.

### A. Local Debug SHA-1 (For Development/Debug Builds)
To view the debug fingerprint for your machine's default debug keystore, run:
```powershell
keytool -list -v -keystore "C:\Users\Atharva Patil\.android\debug.keystore" -alias androiddebugkey -storepass android
```
On this machine, the debug fingerprints are:
* **SHA-1**: `2E:EB:A5:F1:20:98:20:76:EB:1B:3E:55:B3:96:28:CC:CD:2C:27:47`
* **SHA-256**: `58:59:C3:67:F3:43:5C:13:44:AA:CD:E6:CF:DD:6D:19:B1:FF:ED:8F:89:4D:85:F6:38:31:C0:02:3E:61:27:46`

### B. Release SHA-1 (For Release Builds)
To view the fingerprints for the generated upload keystore, run:
```powershell
keytool -list -v -keystore android/app/upload-keystore.jks -alias upload -storepass gymlog123
```
The release fingerprints are:
* **SHA-1**: `81:CA:EB:86:B8:07:3A:D4:17:BE:2E:29:9F:8C:E1:5B:BA:E8:8B:91`
* **SHA-256**: `48:D5:1B:46:BD:6A:D3:96:E8:59:78:6E:1F:7F:93:5B:0B:36:A2:B2:35:FD:88:2A:99:31:5E:77:2A:A5:07:84`

*(If using Google Play App Signing in production, you must also copy the SHA-1 from the **Google Play Console** -> **Release** -> **Setup** -> **App Integrity** -> **App signing key certificate**).*

---

## Step 3: Add to Google Cloud Console

1. Go to [Google Cloud Console Credentials](https://console.cloud.google.com/apis/credentials)
2. Find the **OAuth 2.0 Client ID** for Android (package name `com.gym_log`)
3. Click **Edit** (pencil icon)
4. Under **Restrictions** → **Android apps**, click **Add fingerprint** for each of:
   - **Local Debug SHA-1** (needed for development builds):
     `2E:EB:A5:F1:20:98:20:76:EB:1B:3E:55:B3:96:28:CC:CD:2C:27:47`
   - **Release SHA-1** (needed for local release APK builds):
     `81:CA:EB:86:B8:07:3A:D4:17:BE:2E:29:9F:8C:E1:5B:BA:E8:8B:91`
   - **Play App Signing SHA-1** (if deploying to Google Play):
     (Copy from Google Play Console)
5. Save and wait 5–10 minutes for Google's servers to propagate the change.

---

## Step 4: Build and Test

Clean the build, compile the release APK, and install it on your physical device for testing:

```bash
flutter clean
flutter build apk --release
flutter install --release
```

Expected result: Tap "Continue with Google", sign-in succeeds, onboarding/home screen appears.
