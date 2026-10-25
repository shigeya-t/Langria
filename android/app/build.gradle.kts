import java.util.Properties

plugins {
  id("com.android.application")
  id("org.jetbrains.kotlin.plugin.compose")
}

// Machine-local settings (see local.properties.example): the release AdMob IDs and signing.
val local = Properties().apply {
  rootProject.file("local.properties").takeIf { it.exists() }?.inputStream()?.use { load(it) }
}

// Google's test IDs, so development builds never show live ads.
val testAdMobAppId = "ca-app-pub-3940256099942544~3347511713"
val testBannerUnitId = "ca-app-pub-3940256099942544/9214589741"

android {
  namespace = "net.langria.app"
  compileSdk = 37

  defaultConfig {
    applicationId = local.getProperty("applicationId") ?: "net.langria.app"
    minSdk = 30
    targetSdk = 37
    versionCode = 1
    versionName = "1.0"
    manifestPlaceholders["admobAppId"] = testAdMobAppId
    buildConfigField("String", "BANNER_UNIT_ID", "\"$testBannerUnitId\"")
  }

  signingConfigs {
    local.getProperty("signing.storeFile")?.let { path ->
      create("release") {
        storeFile = file(path)
        storePassword = local.getProperty("signing.storePassword")
        keyAlias = local.getProperty("signing.keyAlias")
        keyPassword = local.getProperty("signing.keyPassword")
      }
    }
  }

  buildTypes {
    release {
      isMinifyEnabled = true
      isShrinkResources = true
      proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"))
      signingConfig = signingConfigs.findByName("release")
      local.getProperty("admob.appId")?.let { manifestPlaceholders["admobAppId"] = it }
      local.getProperty("admob.bannerUnitId")?.let { buildConfigField("String", "BANNER_UNIT_ID", "\"$it\"") }
    }
  }

  compileOptions {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
  }

  buildFeatures {
    compose = true
    buildConfig = true
  }

  testOptions {
    unitTests.isReturnDefaultValues = true
  }
}

// The UI text, the target languages and the commit hash are shared with the
// web app, the extension and the iOS app; they go into the app's assets.
abstract class CopySharedScripts : DefaultTask() {
  @get:InputFiles abstract val scripts: ConfigurableFileCollection
  @get:OutputDirectory abstract val outputDir: DirectoryProperty

  @TaskAction fun copy() {
    val dir = outputDir.get().asFile
    dir.deleteRecursively()
    dir.mkdirs()
    // version.js is written by .githooks/write-version and absent right after a clone.
    scripts.files.filter { it.exists() }.forEach { it.copyTo(dir.resolve(it.name)) }
  }
}

val copySharedScripts = tasks.register<CopySharedScripts>("copySharedScripts") {
  scripts.from(listOf("i18n.js", "languages.js", "version.js").map { rootProject.file("../extension/lib/$it") })
}

androidComponents {
  onVariants { variant ->
    variant.sources.assets?.addGeneratedSourceDirectory(copySharedScripts, CopySharedScripts::outputDir)
  }
}

dependencies {
  val composeBom = platform("androidx.compose:compose-bom:2026.09.00")
  implementation(composeBom)
  implementation("androidx.compose.material3:material3")
  implementation("androidx.compose.material:material-icons-extended")
  implementation("androidx.compose.ui:ui-tooling-preview")
  debugImplementation("androidx.compose.ui:ui-tooling")
  implementation("androidx.activity:activity-compose:1.13.0")
  implementation("androidx.lifecycle:lifecycle-runtime-compose:2.11.0")
  implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.11.0")
  implementation("androidx.lifecycle:lifecycle-process:2.11.0")
  implementation("androidx.core:core-ktx:1.19.1")
  implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0")
  implementation("org.jetbrains.kotlinx:kotlinx-coroutines-play-services:1.11.0")
  // The two exceptions to "no external libraries", as Android has no
  // equivalent of their own: the ads (with UMP for consent) and ML Kit for
  // reading text in photos on the device (its models come with Google Play
  // services, so they do not add to the app's size).
  implementation("com.google.android.gms:play-services-ads:25.5.0")
  implementation("com.google.android.ump:user-messaging-platform:3.2.0")
  // The ads SDK brings WorkManager 2.7, whose database R8 strips from a release build.
  implementation("androidx.work:work-runtime:2.11.2")
  implementation("com.google.android.gms:play-services-mlkit-text-recognition:19.0.1")
  implementation("com.google.android.gms:play-services-mlkit-text-recognition-japanese:16.0.1")
  implementation("com.google.android.gms:play-services-mlkit-text-recognition-chinese:16.0.1")
  implementation("com.google.android.gms:play-services-mlkit-text-recognition-korean:16.0.1")

  testImplementation("junit:junit:4.13.2")
  // android.jar's org.json only has stubs on the JVM.
  testImplementation("org.json:json:20250517")
  testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.11.0")
}
