package com.eup.meup.homewidget

import android.content.Context
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.LocalSize
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.currentState
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.eup.meup.R
import com.eup.meup.MainActivity
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.actionStartActivity

private val CourseMutedText = ColorProvider(androidx.compose.ui.graphics.Color(0xFF8A86A8))

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
            val isMedium = LocalSize.current.width >= 240.dp
            WidgetCard(
                modifier = GlanceModifier.clickable(
                    onClick = actionStartActivity<MainActivity>(context, Uri.parse(payload.deeplink)),
                ),
                backgroundResId = if (payload.isReady) {
                    R.drawable.meup_widget_card_background
                } else {
                    R.drawable.meup_widget_card_fallback_background
                },
                paddingDp = 0,
            ) {
                CourseContent(type, state, payload, isMedium)
            }
        }
    }
}

@Composable
private fun CourseContent(
    type: MeupWidgetType,
    state: HomeWidgetGlanceState,
    payload: MeupHomeWidgetPayload,
    isMedium: Boolean,
) {
    val data = payload.data
    val image = state.preferences.imageProviderFor(type, data)
    val title = data.stringValue("title", type.defaultTitle)
    val mainText = when (type) {
        MeupWidgetType.SuggestCourse -> data.stringValue("description", data.stringValue("subtitle", title))
        else -> title
    }

    if (isMedium) {
        MediumCourseContent(type, payload, image, title, mainText)
    } else {
        SmallCourseContent(type, payload, image, title, mainText)
    }
}

@Composable
private fun MediumCourseContent(
    type: MeupWidgetType,
    payload: MeupHomeWidgetPayload,
    image: androidx.glance.ImageProvider,
    title: String,
    mainText: String,
) {
    val data = payload.data

    Row(
        modifier = GlanceModifier
            .fillMaxSize()
            .padding(start = 24.dp, top = 12.dp, end = 12.dp, bottom = 12.dp),
        verticalAlignment = androidx.glance.layout.Alignment.Vertical.CenterVertically,
    ) {
        WidgetImage(image, sizeDp = if (type == MeupWidgetType.SuggestCourse && !payload.isReady) 104 else 110)
        Spacer(GlanceModifier.width(24.dp))
        Column(modifier = GlanceModifier.fillMaxWidth()) {
            if (type == MeupWidgetType.SuggestCourse) {
                SuggestLabel(data.stringValue("label", "Today's suggestion"))
                Spacer(GlanceModifier.height(4.dp))
                WidgetTitle(if (payload.isReady) mainText else title, maxLines = 3, fontSizeSp = 16)
                if (!payload.isReady) {
                    WidgetCaption(data.stringValue("subtitle", "More coming soon!"), maxLines = 1, fontSizeSp = 12)
                }
            } else {
                WidgetTitle(title, maxLines = 2, fontSizeSp = if (payload.isReady) 20 else 18)
                if (payload.isReady) {
                    Spacer(GlanceModifier.height(12.dp))
                    CourseProgress(payload)
                }
            }
        }
    }
}

@Composable
private fun SmallCourseContent(
    type: MeupWidgetType,
    payload: MeupHomeWidgetPayload,
    image: androidx.glance.ImageProvider,
    title: String,
    mainText: String,
) {
    val data = payload.data

    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .padding(16.dp),
    ) {
        WidgetImage(image, sizeDp = if (type == MeupWidgetType.SuggestCourse && !payload.isReady) 76 else 52)
        if (type == MeupWidgetType.SuggestCourse) {
            Spacer(GlanceModifier.height(8.dp))
            SuggestLabel(data.stringValue("label", "Today's suggestion"))
            Spacer(GlanceModifier.height(4.dp))
            WidgetTitle(if (payload.isReady) mainText else title, maxLines = 3, fontSizeSp = 14)
            if (!payload.isReady) {
                WidgetCaption(data.stringValue("subtitle", "More coming soon!"), maxLines = 1, fontSizeSp = 10)
            }
        } else {
            Spacer(GlanceModifier.height(8.dp))
            if (payload.isReady) {
                CourseProgress(payload)
                Spacer(GlanceModifier.height(8.dp))
            }
            WidgetTitle(title, maxLines = 3, fontSizeSp = 14)
        }
    }
}

@Composable
private fun CourseProgress(payload: MeupHomeWidgetPayload) {
    val data = payload.data
    val completed = data.intValue("completedLessons")
    val total = data.intValue("totalLessons")
    if (total <= 0) return

    ProgressSegments(completed, total)
    Spacer(GlanceModifier.height(6.dp))
    Text(
        text = "$completed/$total lesson",
        style = TextStyle(color = CourseMutedText, fontSize = 12.sp),
    )
}
