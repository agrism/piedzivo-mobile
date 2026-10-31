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

fun configureProject(project: Project) {
    val android = project.extensions.findByName("android")
    if (android != null) {
        try {
            val setCompileSdkVersion = android.javaClass.getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
            setCompileSdkVersion.invoke(android, 36)
        } catch (_: Throwable) {
            try {
                val setCompileSdk = android.javaClass.getMethod("setCompileSdk", java.lang.Integer::class.java)
                setCompileSdk.invoke(android, 36)
            } catch (_: Throwable) {}
        }
    }
}

subprojects {
    if (state.executed) {
        configureProject(this)
    } else {
        afterEvaluate {
            configureProject(this)
        }
    }
}

subprojects {
    tasks.matching { it.name.startsWith("compile") && it.name.endsWith("Kotlin") }.configureEach {
        try {
            val getCompilerOptions = this.javaClass.getMethod("getCompilerOptions")
            val compilerOptions = getCompilerOptions.invoke(this)
            val getLanguageVersion = compilerOptions.javaClass.getMethod("getLanguageVersion")
            val langProp = getLanguageVersion.invoke(compilerOptions)
            val kotlinVersionClass = Class.forName("org.jetbrains.kotlin.gradle.dsl.KotlinVersion")
            val kotlin20 = kotlinVersionClass.getField("KOTLIN_2_0").get(null)
            val setMethod = langProp.javaClass.getMethod("set", Any::class.java)
            setMethod.invoke(langProp, kotlin20)
        } catch (_: Throwable) {}

        try {
            val getKotlinOptions = this.javaClass.getMethod("getKotlinOptions")
            val kotlinOptions = getKotlinOptions.invoke(this)
            val setLanguageVersion = kotlinOptions.javaClass.getMethod("setLanguageVersion", String::class.java)
            setLanguageVersion.invoke(kotlinOptions, "2.0")
        } catch (_: Throwable) {}
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
