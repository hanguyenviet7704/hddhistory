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
        defaultTitle = "You crushed every course!",
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
    val localeCode = widgetLocaleCode().ifBlank { "en" }
    val rawPayload = getString(type.payloadKey, null).orEmpty()
    if (rawPayload.isBlank()) return type.fallbackPayload(localeCode)

    return runCatching {
        val root = JSONObject(rawPayload)
        MeupHomeWidgetPayload(
            state = root.optString("state", "empty"),
            deeplink = root.optString("deeplink", type.defaultDeeplink),
            data = root.optJSONObject("data") ?: JSONObject(),
        )
    }.getOrElse { type.fallbackPayload(localeCode) }
}

internal fun MeupWidgetType.fallbackPayload(localeCode: String = "en"): MeupHomeWidgetPayload {
    val defaults = meupWidgetTextDefaults(localeCode)
    val title = when (this) {
        MeupWidgetType.InProgress -> defaults.inProgressEmptyTitle
        MeupWidgetType.Streak -> defaultTitle
        MeupWidgetType.SuggestCourse -> defaults.suggestExhaustedTitle
    }
    val data = JSONObject()
        .put("localeCode", localeCode)
        .put("title", title)
        .put("staticAssetKey", fallbackImageKey)

    if (this == MeupWidgetType.Streak) {
        data.put("currentStreak", 0)
        data.put("countText", defaults.streakCountText(0))
        data.put("subtitle", defaults.streakEmptySubtitle)
        data.put("weekStudy", JSONArray(listOf(false, false, false, false, false, false, false)))
        data.put("weekLabels", JSONArray(defaults.weekLabels))
    }

    if (this == MeupWidgetType.SuggestCourse) {
        data.put("subtitle", defaults.suggestExhaustedSubtitle)
    }

    return MeupHomeWidgetPayload(
        state = if (this == MeupWidgetType.SuggestCourse) "exhausted" else "empty",
        deeplink = defaultDeeplink,
        data = data,
    )
}

internal fun MeupWidgetType.titleFor(data: JSONObject, isReady: Boolean, defaults: MeupWidgetTextDefaults): String {
    if (!isReady) {
        return when (this) {
            MeupWidgetType.InProgress -> defaults.inProgressEmptyTitle
            MeupWidgetType.Streak -> defaultTitle
            MeupWidgetType.SuggestCourse -> defaults.suggestExhaustedTitle
        }
    }

    val value = data.stringValue("title", defaultTitle)
    return if (this == MeupWidgetType.SuggestCourse && value in legacySuggestLabels) {
        defaults.suggestExhaustedTitle
    } else {
        value
    }
}

private val legacySuggestLabels = setOf(
    "Today's suggestion",
    "Gợi ý hôm nay",
    "今日推荐",
    "今日のおすすめ",
    "오늘의 추천",
)

internal fun JSONObject.stringValue(key: String, fallback: String = ""): String {
    return optString(key, fallback).ifBlank { fallback }
}

internal fun JSONObject.localizedString(translationsKey: String, localeCode: String, fallback: String): String {
    val translations = optJSONObject(translationsKey) ?: return fallback
    val keys = listOf(normalizedWidgetLanguageCode(localeCode), "en", "text").distinct()
    for (key in keys) {
        val value = translations.optString(key, "").trim()
        if (value.isNotEmpty()) return value
    }
    return fallback
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

internal fun JSONObject.stringList(key: String, fallback: List<String>, targetSize: Int): List<String> {
    val values = mutableListOf<String>()
    val array = optJSONArray(key)
    if (array != null) {
        for (index in 0 until minOf(array.length(), targetSize)) {
            values.add(array.optString(index, fallback.getOrElse(index) { "" }).ifBlank { fallback.getOrElse(index) { "" } })
        }
    }
    while (values.size < targetSize) values.add(fallback.getOrElse(values.size) { "" })
    return values
}
