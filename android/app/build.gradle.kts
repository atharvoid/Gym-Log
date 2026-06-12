import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("io.sentry.android.gradle")
}

// ── Release signing ──────────────────────────────────────────────────────────
// Real keystore credentials live in android/key.properties (gitignored — see
// android/key.properties.example). When the file is absent the release build
// falls back to debug signing so `flutter run --release` keeps working on dev
// machines, but such an APK/AAB must NEVER be uploaded to Play.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.drifs.gymlog"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Must match the OAuth configuration in Google Cloud Console.
        applicationId = "com.drifs.gymlog"

        minSdk = flutter.minSdkVersion
        // Play requires new submissions/updates to target API 35+.
        // Manual QA note: API 35 enforces edge-to-edge — verify system bars
        // over the OLED-black UI on an Android 15 device before release.
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

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
            // R8 code shrinking + resource shrinking for release builds.
            // isMinifyEnabled runs R8 which dead-code-eliminates unused classes
            // from all dependencies (biggest single APK size reduction).
            // isShrinkResources strips unused Android resource entries.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                logger.warn(
                    "WARNING: android/key.properties not found — release build " +
                        "is DEBUG-SIGNED and must not be published."
                )
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

sentry {
    org.set("your-org-slug")
    projectName.set("gymlog")
    authToken.set(System.getenv("SENTRY_AUTH_TOKEN"))
    
    // Only upload on release builds
    autoUploadProguardMapping.set(true)
    uploadNativeSymbols.set(false) // Flutter handles native symbols
}
