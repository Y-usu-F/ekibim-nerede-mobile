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
    val configureProject = {
        if (hasProperty("android")) {
            val android = property("android")
            if (android != null) {
                val clazz = android.javaClass
                try {
                    // Use reflection to set compileSdkVersion to 36 for all subprojects (plugins)
                    val method = clazz.getMethod("compileSdkVersion", Int::class.java)
                    method.invoke(android, 36)
                } catch (e: Exception) {
                    // Fallback for newer AGP versions using compileSdk property
                    try {
                        val method = clazz.getMethod("setCompileSdk", java.lang.Integer::class.java)
                        method.invoke(android, 36)
                    } catch (e2: Exception) {}
                }
            }
        }
    }
    if (state.executed) {
        configureProject()
    } else {
        afterEvaluate {
            configureProject()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
