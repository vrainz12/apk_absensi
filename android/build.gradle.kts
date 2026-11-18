allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}
subprojects {
    configurations.all {
        resolutionStrategy {
            force("androidx.concurrent:concurrent-futures:1.2.0")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    configurations.all {
        resolutionStrategy {
            force("androidx.concurrent:concurrent-futures:1.2.0")
            // Mengganti listenablefuture:1.0 dengan versi kosong untuk mencegah duplikasi kelas dari Guava
            force("com.google.guava:listenablefuture:9999.0-empty-to-avoid-conflict-with-guava")
        }
    }

    pluginManager.withPlugin("com.android.library") {
        dependencies {
            add("compileOnly", "androidx.concurrent:concurrent-futures:1.2.0")
            add("implementation", "androidx.concurrent:concurrent-futures:1.2.0")
        }
    }
    pluginManager.withPlugin("com.android.application") {
        dependencies {
            add("compileOnly", "androidx.concurrent:concurrent-futures:1.2.0")
            add("implementation", "androidx.concurrent:concurrent-futures:1.2.0")
        }
    }
}