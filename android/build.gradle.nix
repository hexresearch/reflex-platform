{ applicationId
, version
, releaseKey
, additionalDependencies
, googleServicesClasspath
, googleServicesPlugin
, universalApk
}:
''
buildscript {
    repositories {
        mavenLocal()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:3.4.2'
        classpath 'com.android.tools.lint:lint:26.4.2'
        ${googleServicesClasspath}
    }
}

task proguard(type: proguard.gradle.ProGuardTask) {
  configuration 'proguard.txt'

    // injars 'build/libs/proguard-gradle-example.jar'
    // outjars 'build/libs/proguard-gradle-example.out.jar'

}

allprojects {
    repositories {
        mavenLocal()
    }
}

apply plugin: 'com.android.application'

android {
    compileSdkVersion 29
    buildToolsVersion '28.0.3'

    sourceSets {
      main {
        manifest.srcFile 'AndroidManifest.xml'
        java.srcDirs = ['src']
        res.srcDirs = ['res']
        assets.srcDirs = ['assets'];
        jniLibs.srcDir 'lib'
      }
    }
    defaultConfig {
        applicationId "${applicationId}"
        minSdkVersion 21
        targetSdkVersion 29
        versionCode ${version.code}
        versionName "${version.name}"
        multiDexEnabled false
    }

    ${if releaseKey == null then "" else ''
        signingConfigs {
          release {
            storeFile file("${releaseKey.storeFile}")
            storePassword "${releaseKey.storePassword}"
            keyAlias "${releaseKey.keyAlias}"
            keyPassword "${releaseKey.keyPassword}"
          }
        }
      ''
    }

    buildTypes {
        release {
            minifyEnabled false
            useProguard false
            zipAlignEnabled true
            ${if releaseKey == null then "" else ''
            signingConfig signingConfigs.release
            ''}
        }
        debug {
            minifyEnabled false
            useProguard false
            debuggable true
        }
    }

    bundle {
      density {
        // Different APKs are generated for devices with different screen densities; true by default.
        enableSplit true
      }
      abi {
        // Different APKs are generated for devices with different CPU architectures; true by default.
        enableSplit true
      }
      language {
        // This is disabled so that the App Bundle does NOT split the APK for each language.
        // We're gonna use the same APK for all languages.
        enableSplit false
      }
    }

    packagingOptions {
    }

    // see https://developer.android.com/studio/build/configure-apk-splits.html
    // for information about this and the applicationVariants stuff below.
    // See https://developer.android.com/google/play/publishing/multiple-apks.html#SingleAPK
    // for reasons you might not want to do this.
    ${if universalApk then "" else ''
        splits {
            abi {
                enable true
                reset()
                include "armeabi-v7a", "arm64-v8a"
                universalApk false
            }
        }
        ''
    }
}

ext.abiCodes = ['armeabi-v7a': 1, 'arm64-v8a': 2] // This order is important!

import com.android.build.OutputFile

android.applicationVariants.all { variant ->
  variant.outputs.each { output ->
    def baseAbiVersionCode =
      project.ext.abiCodes.get(output.getFilter(OutputFile.ABI))

    if (baseAbiVersionCode != null) { // this will be null if splitting was disabled
      output.versionCodeOverride = baseAbiVersionCode * 1000 + variant.versionCode
    }
  }
}

dependencies {
    implementation fileTree(dir: 'libs', include: ['*.jar'])
    ${additionalDependencies}
}

${googleServicesPlugin}
''
