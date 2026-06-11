package com.eup.meup.homewidget

import android.content.SharedPreferences
import com.eup.meup.R
import org.json.JSONArray
import org.json.JSONObject

enum class MeupWidgetType(
    val payloadKey: String,
    val defaultDeeplink: String,
    val defaultTitle: String,
    val fallbackImageKey: String,
    val fallbackImageResId: Int,
) {
    InProgress(
        payloadKey = "meup_home_widget_in_progress_v1",
        defaultDeeplink = "meup://home?source=home_widget&widgetType=in_progress_course",
        defaultTitle = "Pick a course and stay in the loop",
        fallbackImageKey = "meup_home_widget_book_asset",
        fallbackImageResId = R.drawable.meup_widget_book,
    ),
    Streak(
        payloadKey = "meup_home_widget_streak_v1",
        defaultDeeplink = "meup://course-roadmap?source=home_widget&widgetType=weekly_streak",
        defaultTitle = "Start your streak today",
        fallbackImageKey = "meup_home_widget_flame_asset",
        fallbackImageResId = R.drawable.meup_widget_flame_star,
    ),
    SuggestCourse(
        payloadKey = "meup_home_widget_suggest_course_v1",
        defaultDeeplink = "meup://home?source=home_widget&widgetType=suggest_course",
        defaultTitle = "Today's suggestion",
        fallbackImageKey = "meup_home_widget_certificate_asset",
        fallbackImageResId = R.drawable.meup_widget_certificate,
    ),
}

internal data class MeupHomeWidgetPayload(
    val state: String,
    val deeplink: String,
    val data: JSONObject,
) {
    val isReady: Boolean = state == "ready"
}

internal fun SharedPreferences.readMeupPayload(type: MeupWidgetType): MeupHomeWidgetPayload {
    val rawPayload = getString(type.payloadKey, null).orEmpty()
    if (rawPayload.isBlank()) return type.fallbackPayload()

    return runCatching {
        val root = JSONObject(rawPayload)
        MeupHomeWidgetPayload(
            state = root.optString("state", "empty"),
            deeplink = root.optString("deeplink", type.defaultDeeplink),
            data = root.optJSONObject("data") ?: JSONObject(),
        )
    }.getOrElse { type.fallbackPayload() }
}

internal fun MeupWidgetType.fallbackPayload(): MeupHomeWidgetPayload {
    val data = JSONObject()
        .put("title", defaultTitle)
        .put("staticAssetKey", fallbackImageKey)

    if (this == MeupWidgetType.Streak) {
        data.put("currentStreak", 0)
        data.put("subtitle", defaultTitle)
        data.put("weekStudy", JSONArray(listOf(false, false, false, false, false, false, false)))
    }

    if (this == MeupWidgetType.SuggestCourse) {
        data.put("subtitle", "More coming soon!")
    }

    return MeupHomeWidgetPayload(
        state = if (this == MeupWidgetType.SuggestCourse) "exhausted" else "empty",
        deeplink = defaultDeeplink,
        data = data,
    )
}

internal fun JSONObject.stringValue(key: String, fallback: String = ""): String {
    return optString(key, fallback).ifBlank { fallback }
}

internal fun JSONObject.intValue(key: String, fallback: Int = 0): Int {
    return optInt(key, fallback)
}

internal fun JSONObject.doubleValue(key: String, fallback: Double = 0.0): Double {
    return optDouble(key, fallback)
}

internal fun JSONObject.boolList(key: String, targetSize: Int): List<Boolean> {
    val values = mutableListOf<Boolean>()
    val array = optJSONArray(key)
    if (array != null) {
        for (index in 0 until minOf(array.length(), targetSize)) {
            values.add(array.optBoolean(index, false))
        }
    }
    while (values.size < targetSize) values.add(false)
    return values
}
