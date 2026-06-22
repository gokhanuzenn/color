buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.6.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.22")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// BU KISIM TÜM KÜTÜPHANELERE "BENİM SDK SÜRÜMÜMÜ KULLAN" DER
subprojects {
    afterEvaluate { project ->
        if (project.extensions.findByName("android") != null) {
            configure<com.android.build.gradle.LibraryExtension> {
                compileSdk = 35
                defaultConfig {
                    minSdk = 21
                }
            }
        }
    }
}

// Tüm projeler için Flutter yolunu zorla tanımla
subprojects {
    afterEvaluate { project ->
        if (project.extensions.findByName("android") != null) {
            // Gal'ı gördüğünde Flutter eklentisini inject et
            if (project.name == "gal") {
                project.apply(plugin = "dev.flutter.flutter-gradle-plugin")
            }
            
            // SDK sürümünü garanti altına al
            project.extensions.configure<com.android.build.gradle.LibraryExtension>("android") {
                compileSdk = 35
                defaultConfig {
                    minSdk = 21
                }
            }
        }
    }
}