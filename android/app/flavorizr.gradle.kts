import com.android.build.api.dsl.ApplicationExtension

val android = project.extensions.getByType(ApplicationExtension::class.java)

android.apply {
    flavorDimensions += listOf("flavor-type")

    productFlavors {
        create("dev") {
            dimension = "flavor-type"
            applicationId = "com.hddhistory.app.dev"
            resValue(type = "string", name = "app_name", value = "HDDhistory")
            resValue(type = "string", name = "environment", value = "development")
            buildConfigField(type = "String", name = "APP_ENVIRONMENT", value = "\"dev\"")
            buildConfigField(type = "String", name = "API_BASE_URL", value = "\"https://dev.api.com\"")
            buildConfigField(type = "boolean", name = "IS_DEBUG", value = "true")
        }
        create("stg") {
            dimension = "flavor-type"
            applicationId = "com.hddhistory.app.stg"
            resValue(type = "string", name = "app_name", value = "HDDhistory Staging")
            resValue(type = "string", name = "environment", value = "staging")
            buildConfigField(type = "String", name = "APP_ENVIRONMENT", value = "\"stg\"")
            buildConfigField(type = "String", name = "API_BASE_URL", value = "\"https://stg.api.com\"")
            buildConfigField(type = "boolean", name = "IS_DEBUG", value = "true")
        }
        create("prod") {
            dimension = "flavor-type"
            applicationId = "com.hddhistory.app"
            resValue(type = "string", name = "app_name", value = "HDDhistory")
            resValue(type = "string", name = "environment", value = "production")
            buildConfigField(type = "String", name = "APP_ENVIRONMENT", value = "\"prod\"")
            buildConfigField(type = "String", name = "API_BASE_URL", value = "\"https://prod.api.com\"")
            buildConfigField(type = "boolean", name = "IS_DEBUG", value = "false")
        }
    }

    buildFeatures.buildConfig = true
    buildFeatures.resValues = true
}