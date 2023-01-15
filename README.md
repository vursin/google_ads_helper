# google_ads_helper

A new Flutter plugin project.

## Getting Started

Update your gradle settings (Android only)
Add the following lines to your settings.gradle file, so you can use the plugin's Android APIs:

``` gradle
def flutterProjectRoot = rootProject.projectDir.parentFile.toPath()
def plugins = new Properties()
def pluginsFile = new File(flutterProjectRoot.toFile(), '.flutter-plugins')
if (pluginsFile.exists()) {
    pluginsFile.withInputStream { stream -> plugins.load(stream) }
}

plugins.each { name, path ->
    def pluginDirectory = flutterProjectRoot.resolve(path).resolve('android').toFile()
    include ":$name"
    project(":$name").projectDir = pluginDirectory
}
```