import java.util.Properties
import java.io.FileInputStream
import java.util.Base64

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Platform
val platformProperties = Properties()
val platformPropertiesFile = rootProject.file("./platform.properties")
if (platformPropertiesFile.exists()) {
    platformProperties.load(FileInputStream(platformPropertiesFile))
} else {
    throw GradleException("platform.properties file not found in android/ directory")
}

// Keystore
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("./app/key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
} else {
    throw GradleException("key.properties file not found in android/app/ directory")
}

// Environment
val dartDefines = mutableMapOf(
    "DART_ENV" to "qa"
)
// Flutter passes dart-defines through a different property
if (project.hasProperty("dart-defines")) {
    val dartDefinesString = project.property("dart-defines") as String
    val dartDefinesList = dartDefinesString.split(",")
    for (encodedDefine in dartDefinesList) {
        try {
            val decodedDefine = String(Base64.getDecoder().decode(encodedDefine))
            val parts = decodedDefine.split("=", limit = 2)
            if (parts.size >= 2) {
                dartDefines[parts[0]] = parts[1]
            }
        } catch (e: Exception) {
            // Ignore failed decoding
        }
    }
}
val envProperties = Properties()
val envPropertiesFile = rootProject.file("../config/${dartDefines["DART_ENV"]}.config")
if (envPropertiesFile.exists()) {
    envProperties.load(FileInputStream(envPropertiesFile))
} else {
    throw GradleException("${dartDefines["DART_ENV"]}.config file not found in flutter config/ directory")
}

android {
    namespace = "com.codysseylabs.cooloff"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // AGP 9 turns resValue off by default; app_name below needs it.
    buildFeatures {
        resValues = true
    }

    defaultConfig {
        applicationId = "com.codysseylabs.cooloff"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
        resValue("string", "app_name", envProperties.getProperty("APP_NAME"))
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            val storeFilePath = keystoreProperties.getProperty("storeFile")
            storeFile = if (storeFilePath != null) file(storeFilePath) else null
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("release")
        }
        getByName("profile") {
            signingConfig = signingConfigs.getByName("release")
        }
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

// AGP 9 (Flutter 3.47+): the old android { kotlinOptions { } } block is a
// compile error; Kotlin's JVM target is set here instead.
kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
