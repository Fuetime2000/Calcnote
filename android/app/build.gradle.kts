plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.calcnote.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.calcnote.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            
            // Enable R8 with proper rules - use less aggressive optimization
            isMinifyEnabled = true
            isShrinkResources = false
            isCrunchPngs = false
            
            // Configure ProGuard rules with less aggressive optimization
            proguardFiles(
                getDefaultProguardFile("proguard-android.txt"), // Changed from optimize to standard
                "proguard-rules.pro",
                "proguard-rules-flutter.pro"
            )
        }
        
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    
    // Use only the core Play Core library with a specific version
    implementation("com.google.android.play:core:1.10.3")
    
    // Add the core-ktx library with the same version as core
    implementation("com.google.android.play:core-ktx:1.8.1") {
        // Exclude the core module to avoid conflicts
        exclude(group = "com.google.android.play", module = "core")
    }
    
    // Force specific versions of transitive dependencies
    configurations.all {
        resolutionStrategy {
            // Force specific versions of Play Core libraries
            force(
                "com.google.android.play:core:1.10.3",
                "com.google.android.play:core-common:2.0.1",
                "com.google.android.play:core-ktx:1.8.1"
            )
        }
    }
}
