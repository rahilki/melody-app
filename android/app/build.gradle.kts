plugins {
    id("com.android.application")
    id("kotlin-android")                     // لازم عشان كوتلن
    id("dev.flutter.flutter-gradle-plugin")  // هذا يجي مع Flutter
    id("com.google.gms.google-services")     // مهم عشان Firebase
}

android {
    namespace = "com.example.melody" 
    compileSdk = 34

    defaultConfig {
        applicationId = "com.melode.app" // غيري حسب مشروعك
        minSdk = 23
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.9.22")

    // Firebase BoM (يدير نسخ المكتبات تلقائيًا)
    implementation(platform("com.google.firebase:firebase-bom:32.8.0"))

    // Firebase Authentication
    implementation("com.google.firebase:firebase-auth")

    // Firebase Firestore (إذا تحتاج قاعدة بيانات)
    implementation("com.google.firebase:firebase-firestore")

    // Firebase Analytics (اختياري)
    implementation("com.google.firebase:firebase-analytics")
}
