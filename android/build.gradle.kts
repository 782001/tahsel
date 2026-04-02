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
    if (project.name != "app") {
        project.evaluationDependsOn(":app")

        afterEvaluate {
            val androidExt = project.extensions.findByName("android")
            if (androidExt != null) {
                try {
                    val getNamespace = androidExt.javaClass.getMethod("getNamespace")
                    val currentNamespace = getNamespace.invoke(androidExt)
                    if (currentNamespace == null) {
                        val manifestFile = project.file("src/main/AndroidManifest.xml")
                        if (manifestFile.exists()) {
                            val content = manifestFile.readText()
                            val matcher = java.util.regex.Pattern.compile("""package="([^"]+)"""").matcher(content)
                            if (matcher.find()) {
                                val packageName = matcher.group(1)
                                val setNamespace = androidExt.javaClass.getMethod("setNamespace", String::class.java)
                                setNamespace.invoke(androidExt, packageName)
                            }
                        } else if (project.name == "flutter_jailbreak_detection") {
                            val setNamespace = androidExt.javaClass.getMethod("setNamespace", String::class.java)
                            setNamespace.invoke(androidExt, "com.rioapp.demo.flutter_jailbreak_detection")
                        }
                    }
                } catch (e: Exception) {
                    // Ignore reflection exceptions if methods don't exist
                }
            }
        }
    }
}


tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
