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

// Several plugins (e.g. file_picker's flutter_plugin_android_lifecycle
// dependency) now require compileSdk 36+, but Flutter's shared default can
// lag behind that. Force every Android library subproject (plugin) to
// compile against at least 36 so plugin builds stay in sync with the app.
subprojects {
    fun forceCompileSdk36() {
        plugins.withId("com.android.library") {
            extensions.configure<com.android.build.gradle.LibraryExtension> {
                if ((compileSdk ?: 0) < 36) {
                    compileSdk = 36
                }
            }
        }
    }
    // This needs to run after each plugin's own build.gradle has already
    // set (and would otherwise win over) compileSdk. evaluationDependsOn
    // above can force :app to evaluate eagerly, so afterEvaluate is illegal
    // on it by the time this runs - fall back to configuring immediately.
    if (project.state.executed) forceCompileSdk36() else afterEvaluate { forceCompileSdk36() }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
