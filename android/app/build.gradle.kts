import java.util.Properties
import java.util.concurrent.TimeUnit

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.itlg_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.itlg_mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Baca MAPS_API_KEY dari local.properties (tidak ter-commit ke git)
        val localProps = Properties()
        val localPropsFile = rootProject.file("local.properties")
        if (localPropsFile.exists()) {
            localPropsFile.inputStream().use { stream -> localProps.load(stream) }
        }
        val mapsKey = localProps.getProperty("MAPS_API_KEY") ?: "YOUR_GOOGLE_MAPS_API_KEY"
        manifestPlaceholders["MAPS_API_KEY"] = mapsKey
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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

// Sinkronisasi otomatis lokasi nyata laptop Windows ke Android Emulator
// setiap kali `flutter run` (assembleDebug) dijalankan — tanpa script terpisah.
val syncEmulatorGps by tasks.registering {
    outputs.upToDateWhen { false }
    doLast {
        try {
            val isWindows = System.getProperty("os.name").lowercase().contains("win")
            if (!isWindows) return@doLast

            val localProps = Properties()
            val localPropsFile = rootProject.file("local.properties")
            if (localPropsFile.exists()) {
                localPropsFile.inputStream().use { localProps.load(it) }
            }
            val sdkDir = localProps.getProperty("sdk.dir")
                ?: System.getenv("ANDROID_HOME")
                ?: System.getenv("ANDROID_SDK_ROOT")
                ?: "C:\\src\\Android\\Sdk"
            var adbFile = File(sdkDir, "platform-tools\\adb.exe")
            if (!adbFile.exists()) {
                adbFile = File("C:\\src\\Android\\Sdk\\platform-tools\\adb.exe")
            }
            if (!adbFile.exists()) return@doLast

            val devProc = ProcessBuilder(adbFile.absolutePath, "devices")
                .redirectErrorStream(true)
                .start()
            val devOutput = devProc.inputStream.bufferedReader().readText()
            devProc.waitFor(3, TimeUnit.SECONDS)

            val emulators = Regex("(emulator-\\d+)\\s+device")
                .findAll(devOutput)
                .map { it.groupValues[1] }
                .distinct()
                .toList()
            if (emulators.isEmpty()) return@doLast

            val psCmd =
                "Add-Type -AssemblyName System.Device; " +
                "\$w = New-Object System.Device.Location.GeoCoordinateWatcher([System.Device.Location.GeoPositionAccuracy]::High); " +
                "\$w.Start(); " +
                "for (\$i=0; \$i -lt 30; \$i++) { " +
                "  \$l = \$w.Position.Location; " +
                "  if (\$l -ne \$null -and -not \$l.IsUnknown) { " +
                "    Write-Output ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, '{0},{1}', \$l.Latitude, \$l.Longitude)); break " +
                "  } " +
                "  Start-Sleep -Milliseconds 150 " +
                "}; " +
                "\$w.Stop()"

            val psProc = ProcessBuilder("powershell", "-NoProfile", "-Command", psCmd)
                .redirectErrorStream(true)
                .start()
            val locText = psProc.inputStream.bufferedReader().readText().trim()
            psProc.waitFor(6, TimeUnit.SECONDS)

            val parts = locText.lines().lastOrNull()?.split(",") ?: emptyList()
            if (parts.size == 2) {
                val lat = parts[0].trim().toDoubleOrNull()
                val lng = parts[1].trim().toDoubleOrNull()
                if (lat != null && lng != null) {
                    for (emu in emulators) {
                        val fixProc = ProcessBuilder(
                            adbFile.absolutePath, "-s", emu, "emu", "geo", "fix",
                            lng.toString(), lat.toString()
                        ).redirectErrorStream(true).start()
                        fixProc.waitFor(3, TimeUnit.SECONDS)
                        logger.lifecycle("[ITLG GPS] Auto-synced $emu -> lat=$lat, lng=$lng")
                    }
                }
            }
        } catch (_: Throwable) {
            // Jangan gagalkan build jika Windows Location Service nonaktif
        }
    }
}

tasks.matching { it.name == "assembleDebug" }.configureEach {
    dependsOn(syncEmulatorGps)
}
