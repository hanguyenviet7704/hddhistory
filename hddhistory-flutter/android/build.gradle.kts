allprojects {
    repositories {
        google()
        mavenCentral()
        // Add TikTok's Maven repository
        maven { url = uri("https://jitpack.io") }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    project.plugins.withId("com.android.library") {
        if (!project.plugins.hasPlugin("org.jetbrains.kotlin.android")) {
            project.apply(plugin = "org.jetbrains.kotlin.android")
        }
    }

    afterEvaluate {
        if (project.plugins.hasPlugin("com.android.library")) {
            project.extensions.configure<com.android.build.gradle.LibraryExtension> {
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_21
                    targetCompatibility = JavaVersion.VERSION_21
                }
            }
            project.tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
                compilerOptions {
                    jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_21)
                }
            }
        }
        if (hasProperty("android")) {
            val androidExtension = extensions.getByName("android")
            if (androidExtension is com.android.build.api.dsl.CommonExtension) {
                val clazz = androidExtension::class.java
                try {
                    val currentNamespace = clazz.getMethod("getNamespace").invoke(androidExtension) as? String
                    if (currentNamespace == null) {
                        val manifestFile = file("src/main/AndroidManifest.xml")
                        if (manifestFile.exists()) {
                            val factory = javax.xml.parsers.DocumentBuilderFactory.newInstance()
                            val document = factory.newDocumentBuilder().parse(manifestFile)
                            val packageName = document.documentElement.getAttribute("package")
                            if (packageName.isNotEmpty()) {
                                clazz.getMethod("setNamespace", String::class.java).invoke(androidExtension, packageName)
                                println("Setting namespace for ${project.name} to ${packageName}")
                            }
                        }
                    }
                } catch (_: Exception) {}
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
