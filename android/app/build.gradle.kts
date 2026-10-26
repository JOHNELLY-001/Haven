import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(FileInputStream(localPropertiesFile))
}

// Release signing is read from android/key.properties (gitignored). Until it
// exists we keep falling back to the debug key so `flutter build` still runs,
// but such an AAB is NOT accepted by Google Play.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
} else {
    logger.warn(
        "No android/key.properties found - release builds will use the DEBUG key " +
        "and cannot be uploaded to Google Play. See RELEASE_CHECKLIST.md."
    )
}

android {
    namespace = "com.example.e_venues"
    compileSdk = flutter.compileSdkVersion

    // Was hardcoded to "27.0.12077973", which drifted behind the NDK that the
    // installed Flutter toolchain expects (28.2.13676358). Pinning a literal
    // version means plugins prebuilt against a different NDK get rebuilt from
    // stale .cxx caches. Resolving it from the Flutter plugin keeps it in sync.
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "tz.haven.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["googleMapsApiKey"] = localProperties.getProperty("MAPS_API_KEY", "")
        // Build only arm64-v8a (physical devices) and x86_64 (emulator).
        // Building all four ABIs forks extra CMake/ninja processes that this
        // 4-core / 3.88 GB machine cannot afford.
        ndk {
            abiFilters += listOf("arm64-v8a", "x86_64")
        }
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
            // Signed with the upload keystore when key.properties exists;
            // otherwise debug-signed (local testing only, not Play-uploadable).
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
