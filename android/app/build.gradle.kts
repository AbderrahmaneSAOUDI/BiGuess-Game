plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.flutter.gdg_guess_game"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    // Disable native symbol tables extraction
    packagingOptions {
        jniLibs {
            useLegacyPackaging = true
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
 
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.flutter.gdg_guess_game"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    // Force Kotlin version alignment
    constraints {
        implementation("org.jetbrains.kotlin:kotlin-stdlib") {
            version {
                strictly("1.9.0")
            }
        }
        implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7") {
            version {
                strictly("1.9.0")
            }
        }
        implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8") {
            version {
                strictly("1.9.0")
            }
        }
    }
}

flutter {
    source = "../.."
}
