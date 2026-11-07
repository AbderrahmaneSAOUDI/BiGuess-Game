import java.io.File
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android plugin.
    id("dev.flutter.flutter-gradle-plugin")
}

// -----------------------------------------------------------------------------
// Secure Release Signing Resolution
// Credentials must be provided externally via android/key.properties or environment variables.
// Release builds will NEVER silently fall back to debug signing.
// -----------------------------------------------------------------------------
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { load(it) }
    }
}

val releaseStoreFile: String? = keystoreProperties.getProperty("storeFile")
    ?: System.getenv("ANDROID_KEYSTORE_PATH")
    ?: System.getenv("KEYSTORE_PATH")
val releaseStorePassword: String? = keystoreProperties.getProperty("storePassword")
    ?: System.getenv("ANDROID_KEYSTORE_PASSWORD")
    ?: System.getenv("KEYSTORE_PASSWORD")
val releaseKeyAlias: String? = keystoreProperties.getProperty("keyAlias")
    ?: System.getenv("ANDROID_KEY_ALIAS")
    ?: System.getenv("KEY_ALIAS")
val releaseKeyPassword: String? = keystoreProperties.getProperty("keyPassword")
    ?: System.getenv("ANDROID_KEY_PASSWORD")
    ?: System.getenv("KEY_PASSWORD")

val isReleaseSigningConfigured = !releaseStoreFile.isNullOrBlank() &&
    !releaseStorePassword.isNullOrBlank() &&
    !releaseKeyAlias.isNullOrBlank() &&
    !releaseKeyPassword.isNullOrBlank()

android {
    namespace = "com.flutter.biguess"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.flutter.biguess"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (isReleaseSigningConfigured) {
            create("release") {
                val storePath = releaseStoreFile!!
                val resolvedStore = if (File(storePath).isAbsolute) {
                    File(storePath)
                } else {
                    rootProject.file(storePath)
                }
                storeFile = resolvedStore
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            if (isReleaseSigningConfigured) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                signingConfig = null
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    lint {
        // Enforce static analysis during release builds (removes unsafe bypasses)
        checkReleaseBuilds = true
        // Abort the build if any fatal errors are detected in application code
        abortOnError = true
        // Documented mitigation: Do not fail app release builds on third-party plugin lints
        checkDependencies = false
        // Warnings are reported but do not halt builds
        warningsAsErrors = false
        // Documented mitigations: Portrait game lock and Android 16 orientation guidance
        disable += setOf("LockedOrientationActivity", "DiscouragedApi")
    }
}

// -----------------------------------------------------------------------------
// Safeguard: Block Release Artifact Assembly without Release Signing
// Prevents silent shipping of unsigned or debug-signed release APKs.
// -----------------------------------------------------------------------------
gradle.taskGraph.whenReady {
    if (!isReleaseSigningConfigured) {
        val releaseAssemblyTask = allTasks.find { task ->
            task.project == project &&
            task.name.contains("Release", ignoreCase = true) &&
            (task.name.startsWith("assemble") || task.name.startsWith("bundle") || task.name.startsWith("package"))
        }
        if (releaseAssemblyTask != null) {
            throw GradleException(
                "Release build failed: Release signing configuration is missing!\n" +
                "A release APK cannot silently ship signed with the debug key or unsigned.\n" +
                "Provide 'android/key.properties' or set ANDROID_KEYSTORE_PATH, " +
                "ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS, ANDROID_KEY_PASSWORD environment variables.\n" +
                "See 'android/key.properties.example' and docs/migration/RELEASE_SAFETY_AND_DISTRIBUTION.md."
            )
        }
    }
}

// Verification task for local and CI validation
tasks.register("validateReleaseSigning") {
    group = "verification"
    description = "Validates the Android release signing configuration without compiling artifacts."
    doLast {
        val requireConfigured = project.hasProperty("requireReleaseSigning") ||
            "true".equals(System.getenv("REQUIRE_RELEASE_SIGNING"), ignoreCase = true)

        if (isReleaseSigningConfigured) {
            val storePath = releaseStoreFile!!
            val resolvedStore = if (File(storePath).isAbsolute) {
                File(storePath)
            } else {
                rootProject.file(storePath)
            }
            if (!resolvedStore.exists()) {
                throw GradleException("Release signing is configured, but keystore file does not exist: ${resolvedStore.absolutePath}")
            }
            println("✅ Release signing configuration is VALID.")
            println("   Keystore: ${resolvedStore.absolutePath}")
            println("   Key Alias: $releaseKeyAlias")
        } else {
            val message = "Release signing is NOT configured (safe developer mode: debug key is NEVER used for release)."
            if (requireConfigured) {
                throw GradleException("Validation failed: $message Release credentials are required.")
            } else {
                println("ℹ️  $message")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}
