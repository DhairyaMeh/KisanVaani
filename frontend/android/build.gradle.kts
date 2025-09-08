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

// Force all Android modules (apps and libraries) to use compileSdk 34
// Note: Do not force compileSdk here during task execution; it must be set
// within each module's android block during evaluation time.

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
