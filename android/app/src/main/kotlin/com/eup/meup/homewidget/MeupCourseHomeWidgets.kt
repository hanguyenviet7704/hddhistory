package com.eup.meup.homewidget

import android.content.Context
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.eup.meup.MainActivity
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.actionStartActivity

private val CourseMutedText = ColorProvider(Color(0xFF667085))
private val CourseAccentText = ColorProvider(Color(0xFF1BAA76))

class InProgressHomeWidget : CourseHomeWidget(MeupWidgetType.InProgress)

class SuggestCourseHomeWidget : CourseHomeWidget(MeupWidgetType.SuggestCourse)

abstract class CourseHomeWidget(
    private val type: MeupWidgetType,
) : GlanceAppWidget() {
    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val state = currentState<HomeWidgetGlanceState>()
            val payload = state.preferences.readMeupPayload(type)
            WidgetCard(
                modifier = GlanceModifier.clickable(
                    onClick = actionStartActivity<MainActivity>(context, Uri.parse(payload.deeplink)),
                ),
            ) {
                CourseContent(type, state, payload)
            }
        }
    }
}

@Composable
private fun CourseContent(
    type: MeupWidgetType,
    state: HomeWidgetGlanceState,
    payload: MeupHomeWidgetPayload,
) {
    val data = payload.data
    val image = state.preferences.imageProviderFor(type, data)
    val title = data.stringValue("title", type.defaultTitle)

    Column {
        Row(modifier = GlanceModifier.fillMaxWidth()) {
            WidgetImage(image)
            Spacer(GlanceModifier.width(10.dp))
            Column {
                if (type == MeupWidgetType.SuggestCourse) {
                    SuggestLabel(data.stringValue("label", "Today's suggestion"))
                    Spacer(GlanceModifier.height(6.dp))
                }
                WidgetTitle(title)
                if (type == MeupWidgetType.SuggestCourse) {
                    WidgetCaption(data.stringValue("description", data.stringValue("subtitle", "")), maxLines = 2)
                }
            }
        }

        Spacer(GlanceModifier.height(12.dp))

        if (type == MeupWidgetType.InProgress && payload.isReady) {
            ProgressSegments(data.doubleValue("progress").coerceIn(0.0, 1.0))
            Spacer(GlanceModifier.height(6.dp))
            Text(
                text = "${data.intValue("completedLessons")}/${data.intValue("totalLessons")} lessons",
                style = TextStyle(color = CourseMutedText, fontSize = 11.sp),
            )
        } else if (!payload.isReady) {
            BoxedFallback(payload.state)
        }
    }
}

@Composable
private fun BoxedFallback(state: String) {
    Text(
        text = if (state == "exhausted") "All caught up" else "Open Meup to continue",
        modifier = GlanceModifier
            .background(Color(0xFFE7F6EF))
            .padding(horizontal = 8.dp, vertical = 5.dp),
        style = TextStyle(color = CourseAccentText, fontSize = 11.sp),
    )
}
