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
    val fixSubproject = {
        if (plugins.hasPlugin("com.android.application") || plugins.hasPlugin("com.android.library")) {
            val androidExt = extensions.findByName("android")
            if (androidExt != null) {
                try {
                    val getNamespace = androidExt.javaClass.methods.firstOrNull { it.name == "getNamespace" }
                    val currentNamespace = getNamespace?.invoke(androidExt)
                    if (currentNamespace == null) {
                        val setNamespace = androidExt.javaClass.methods.firstOrNull { 
                            it.name == "setNamespace" && it.parameterTypes.size == 1 && it.parameterTypes[0] == String::class.java 
                        }
                        setNamespace?.invoke(androidExt, "com.example.${name.replace('-', '_')}")
                    }
                    val getCompileOptions = androidExt.javaClass.methods.firstOrNull { it.name == "getCompileOptions" }
                    val compileOptions = getCompileOptions?.invoke(androidExt)
                    if (compileOptions != null) {
                        val setSource = compileOptions.javaClass.methods.firstOrNull { it.name == "setSourceCompatibility" }
                        val setTarget = compileOptions.javaClass.methods.firstOrNull { it.name == "setTargetCompatibility" }
                        setSource?.invoke(compileOptions, JavaVersion.VERSION_11)
                        setTarget?.invoke(compileOptions, JavaVersion.VERSION_11)
                    }
                } catch (_: Exception) {
                }
            }
        }

        tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = JavaVersion.VERSION_11.toString()
            targetCompatibility = JavaVersion.VERSION_11.toString()
        }
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            kotlinOptions {
                jvmTarget = "11"
                incremental = false
            }
        }
    }

    if (state.executed) {
        fixSubproject()
    } else {
        afterEvaluate { fixSubproject() }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
