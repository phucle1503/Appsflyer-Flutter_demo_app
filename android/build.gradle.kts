allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = java.net.URI("https://storage.googleapis.com/download.flutter.io") }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    // =====================================================================
    // 🔥 SỬA ĐỔI QUAN TRỌNG: Bọc trong afterEvaluate để bắt trọn các plugin ngầm
    // =====================================================================
    afterEvaluate {
        plugins.withType<com.android.build.gradle.BasePlugin> {
            val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
            // Ép toàn bộ lên SDK 36 sau khi plugin đã evaluate xong để sửa lỗi lStar
            android.compileSdkVersion(36)
            android.buildToolsVersion("36.0.0")

            android.lintOptions {
                isCheckReleaseBuilds = false
                isAbortOnError = false
            }
        }
    }

    project.configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "androidx.core") {
                useVersion("1.13.1")
            }
            if (requested.group == "androidx.appcompat") {
                useVersion("1.6.1")
            }
            if (requested.group == "androidx.lifecycle") {
                useVersion("2.8.7")
            }
            if (requested.group == "androidx.savedstate") {
                useVersion("1.2.1")
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
