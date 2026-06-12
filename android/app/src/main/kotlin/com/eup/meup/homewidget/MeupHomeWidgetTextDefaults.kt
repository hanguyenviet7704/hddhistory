package com.eup.meup.homewidget

import android.content.SharedPreferences

private const val WidgetLocaleCodeKey = "meup_home_widget_locale_code"

internal data class MeupWidgetTextDefaults(
    val inProgressEmptyTitle: String = "Pick a course and stay in the loop",
    val streakActiveSubtitle: String = "Keep going!",
    val streakEmptySubtitle: String = "Start your streak today",
    val suggestLabel: String = "Today's suggestion",
    val suggestExhaustedTitle: String = "You crushed every course!",
    val suggestExhaustedSubtitle: String = "More coming soon!",
    val weekLabels: List<String> = listOf("M", "T", "W", "T", "F", "S", "S"),
    val streakCountSingularTemplate: String = "{count} day",
    val streakCountPluralTemplate: String = "{count} days",
) {
    fun streakCountText(count: Int): String {
        val template = if (count == 1) streakCountSingularTemplate else streakCountPluralTemplate
        return template.replace("{count}", count.toString())
    }
}

internal fun SharedPreferences.widgetLocaleCode(): String {
    return getString(WidgetLocaleCodeKey, null).orEmpty().trim()
}

internal fun meupWidgetTextDefaults(localeCode: String): MeupWidgetTextDefaults {
    return when (normalizedWidgetLanguageCode(localeCode)) {
        "vi" -> MeupWidgetTextDefaults(
            inProgressEmptyTitle = "Chọn khóa học để bắt đầu",
            streakActiveSubtitle = "Tiếp tục nhé!",
            streakEmptySubtitle = "Bắt đầu chuỗi hôm nay",
            suggestLabel = "Gợi ý hôm nay",
            suggestExhaustedTitle = "Bạn đã hoàn thành mọi khóa học!",
            suggestExhaustedSubtitle = "Sắp có thêm!",
            weekLabels = listOf("T2", "T3", "T4", "T5", "T6", "T7", "CN"),
            streakCountSingularTemplate = "{count} ngày",
            streakCountPluralTemplate = "{count} ngày",
        )
        "zh" -> MeupWidgetTextDefaults(
            inProgressEmptyTitle = "选择课程，继续学习",
            streakActiveSubtitle = "继续加油！",
            streakEmptySubtitle = "今天开始连续学习",
            suggestLabel = "今日推荐",
            suggestExhaustedTitle = "你已完成所有课程！",
            suggestExhaustedSubtitle = "更多内容即将推出！",
            weekLabels = listOf("周一", "周二", "周三", "周四", "周五", "周六", "周日"),
            streakCountSingularTemplate = "{count} 天",
            streakCountPluralTemplate = "{count} 天",
        )
        "ja" -> MeupWidgetTextDefaults(
            inProgressEmptyTitle = "コースを選んで学習を続けよう",
            streakActiveSubtitle = "その調子！",
            streakEmptySubtitle = "今日から連続記録を始めよう",
            suggestLabel = "今日のおすすめ",
            suggestExhaustedTitle = "すべてのコースを完了しました！",
            suggestExhaustedSubtitle = "近日追加予定！",
            weekLabels = listOf("月", "火", "水", "木", "金", "土", "日"),
            streakCountSingularTemplate = "{count} 日",
            streakCountPluralTemplate = "{count} 日",
        )
        "ko" -> MeupWidgetTextDefaults(
            inProgressEmptyTitle = "코스를 골라 학습을 이어가세요",
            streakActiveSubtitle = "잘하고 있어요!",
            streakEmptySubtitle = "오늘 연속 학습을 시작하세요",
            suggestLabel = "오늘의 추천",
            suggestExhaustedTitle = "모든 코스를 완료했어요!",
            suggestExhaustedSubtitle = "곧 더 추가돼요!",
            weekLabels = listOf("월", "화", "수", "목", "금", "토", "일"),
            streakCountSingularTemplate = "{count}일",
            streakCountPluralTemplate = "{count}일",
        )
        else -> MeupWidgetTextDefaults()
    }
}

internal fun normalizedWidgetLanguageCode(localeCode: String): String {
    return localeCode
        .trim()
        .split('-', '_')
        .firstOrNull()
        ?.lowercase()
        .orEmpty()
        .ifBlank { "en" }
}
