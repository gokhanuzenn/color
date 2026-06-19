allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    afterEvaluate {
        val project = this
        if (project.extensions.findByName("android") != null) {
            val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
            if (android.namespace == null) {
                android.namespace = project.group.toString()
            }
            
            // Fix JVM target compatibility issues (e.g. image_gallery_saver reporting 1.8 vs 21)
            // Force both Java and Kotlin to target 17 across all modules and dependencies
            android.compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
            
            if (project.plugins.hasPlugin("org.jetbrains.kotlin.android")) {
                project.extensions.getByType(org.jetbrains.kotlin.gradle.dsl.KotlinJvmOptions::class.java).apply {
                    jvmTarget = "17"
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
