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

    afterEvaluate {
        val androidExt = project.extensions.findByName("android")
        if (androidExt != null) {
            val clazz = androidExt.javaClass
            try {
                clazz.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType).invoke(androidExt, 36)
            } catch (e: Exception) {}
            try {
                val namespaceStr = clazz.getMethod("getNamespace").invoke(androidExt) as? String
                if (namespaceStr == null) {
                    clazz.getMethod("setNamespace", String::class.java).invoke(androidExt, project.group.toString())
                }
            } catch (e: Exception) {}
        }
    }

}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

