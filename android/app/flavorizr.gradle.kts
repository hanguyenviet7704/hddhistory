import com.android.build.gradle.AppExtension

val android = project.extensions.getByType(AppExtension::class.java)

android.apply {
    flavorDimensions("flavor-type")

    productFlavors {
        create("dev") {
            dimension = "flavor-type"
            applicationId = "com.eup.meup.dev"
            resValue(type = "string", name = "app_name", value = "Meup Dev")
            resValue(type = "string", name = "environment", value = "development")
            buildConfigField(type = "String", name = "APP_ENVIRONMENT", value = "\"dev\"")
            buildConfigField(type = "String", name = "API_BASE_URL", value = "\"https://dev.api.com\"")
            buildConfigField(type = "boolean", name = "IS_DEBUG", value = "true")
        }
        create("stg") {
            dimension = "flavor-type"
            applicationId = "com.eup.meup.stg"
            resValue(type = "string", name = "app_name", value = "Meup Staging")
            resValue(type = "string", name = "environment", value = "staging")
            buildConfigField(type = "String", name = "APP_ENVIRONMENT", value = "\"stg\"")
            buildConfigField(type = "String", name = "API_BASE_URL", value = "\"https://stg.api.com\"")
            buildConfigField(type = "boolean", name = "IS_DEBUG", value = "true")
        }
        create("prod") {
            dimension = "flavor-type"
            applicationId = "com.eup.meup"
            resValue(type = "string", name = "app_name", value = "Meup")
            resValue(type = "string", name = "environment", value = "production")
            buildConfigField(type = "String", name = "APP_ENVIRONMENT", value = "\"prod\"")
            buildConfigField(type = "String", name = "API_BASE_URL", value = "\"https://prod.api.com\"")
            buildConfigField(type = "boolean", name = "IS_DEBUG", value = "false")
        }
    }

    buildFeatures.buildConfig = true
}