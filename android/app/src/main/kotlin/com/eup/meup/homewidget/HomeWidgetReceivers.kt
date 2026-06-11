package com.eup.meup.homewidget

import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

class InProgressHomeWidgetReceiver : HomeWidgetGlanceWidgetReceiver<InProgressHomeWidget>() {
    override val glanceAppWidget = InProgressHomeWidget()
}

class StreakHomeWidgetReceiver : HomeWidgetGlanceWidgetReceiver<StreakHomeWidget>() {
    override val glanceAppWidget = StreakHomeWidget()
}

class SuggestCourseHomeWidgetReceiver : HomeWidgetGlanceWidgetReceiver<SuggestCourseHomeWidget>() {
    override val glanceAppWidget = SuggestCourseHomeWidget()
}
