import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Clé de publication : android/key.properties, ignoré par Git (docs/manual-tasks.md).
// Sans ce fichier, la version de publication est signée avec la clé de debug :
// installable pour un essai, refusée par Google Play.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) FileInputStream(file).use { load(it) }
}

// Identifiant d'app AdMob : celui de démonstration de Google en debug, le vrai obligatoire
// pour une version de publication (-PADMOB_APP_ID=..., docs/manual-tasks.md).
val admobAppId = project.findProperty("ADMOB_APP_ID") as String?
if (admobAppId == null && gradle.startParameter.taskNames.any { it.contains("Release") }) {
    throw GradleException(
        "ADMOB_APP_ID manquant : flutter build appbundle -PADMOB_APP_ID=ca-app-pub-...~...",
    )
}

android {
    namespace = "com.journaldelangue.journal_de_langue"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Définitif à la première mise en ligne (ADR-010).
        applicationId = "com.journaldelangue.journal_de_langue"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["admobAppId"] =
            admobAppId ?: "ca-app-pub-3940256099942544~3347511713"
    }

    signingConfigs {
        if (!keystoreProperties.isEmpty) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig =
                signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
