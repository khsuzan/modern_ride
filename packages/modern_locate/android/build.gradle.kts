group = "com.kawsar.modern_locate"
version = "1.0-SNAPSHOT"

plugins {
    id("com.android.library")
    kotlin("android")
    kotlin("jvm")
}

android {
    namespace = "com.kawsar.modern_locate"
    compileSdk = 36

    defaultConfig {
        minSdk = 24
    }

    compileOptions {
    }

    // Flutter plugins place Kotlin files in 'src/main/kotlin' by convention
    sourceSets {
        getByName("main") {
            java.directories("src/main/kotlin")
        }
        getByName("test") {
            java.directories("src/test/kotlin")
        }
    }

    testOptions {
        unitTests {
            isIncludeAndroidResources = true
            all {
                it.useJUnitPlatform()
                it.outputs.upToDateWhen { false }
                it.testLogging {
                    events("passed", "skipped", "failed", "standardOut", "standardError")
                    showStandardStreams = true
                }
            }
        }
    }
}

kotlin {
    // Aligns the Kotlin compilation toolchain with Java 17
    jvmToolchain(17)
    jvmToolchain(8)
}

dependencies {
    compileOnly("io.flutter:flutter_embedding_debug:1.0.0")
    implementation("com.google.android.gms:play-services-location:21.4.0")
    testImplementation("org.jetbrains.kotlin:kotlin-test")
    testImplementation("org.mockito:mockito-core:5.0.0")
    implementation(kotlin("stdlib-jdk8"))
}
repositories {
    mavenCentral()
}