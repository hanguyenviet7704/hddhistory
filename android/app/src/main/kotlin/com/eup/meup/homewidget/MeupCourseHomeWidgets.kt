package com.eup.meup.homewidget

import android.content.Context
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.LocalSize
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
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
    override val sizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val state = currentState<HomeWidgetGlanceState>()
            val payload = state.preferences.readMeupPayload(type)
            val widgetSize = LocalSize.current
            val isMedium = widgetSize.width >= 190.dp
            val isCompact = widgetSize.width < 170.dp || widgetSize.height < 145.dp
            WidgetCard(
                modifier = GlanceModifier.clickable(
                    onClick = actionStartActivity<MainActivity>(context, Uri.parse(payload.deeplink)),
                ),
                backgroundResId = if (payload.isReady) {
                    R.drawable.meup_widget_card_shape
                } else {
                    R.drawable.meup_widget_card_fallback_shape
                },
                paddingDp = 0,
            ) {
                CourseContent(type, state, payload, isMedium, isCompact)
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
    isCompact: Boolean,
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
        SmallCourseContent(type, payload, image, title, mainText, isCompact)
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
                SuggestLabel(data.stringValue("label", "Today's suggestion"), fontSizeSp = 12)
                Spacer(GlanceModifier.height(4.dp))
                WidgetTitle(if (payload.isReady) mainText else title, maxLines = 3, fontSizeSp = 16)
                if (!payload.isReady) {
                    WidgetCaption(data.stringValue("subtitle", "More coming soon!"), maxLines = 1, fontSizeSp = 12)
                }
            } else {
                if (payload.isReady) {
                    CourseProgress(payload, rowWidthDp = 168, trackWidthDp = 76)
                    Spacer(GlanceModifier.height(4.dp))
                }
                WidgetTitle(title, maxLines = 2, fontSizeSp = if (payload.isReady) 20 else 18)
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
    isCompact: Boolean,
) {
    val data = payload.data
    val imageSize = if (isCompact) 44 else if (type == MeupWidgetType.SuggestCourse && !payload.isReady) 76 else 52

    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .padding(16.dp),
    ) {
        WidgetImage(image, sizeDp = imageSize)
        if (type == MeupWidgetType.SuggestCourse) {
            Spacer(GlanceModifier.height(8.dp))
            SuggestLabel(data.stringValue("label", "Today's suggestion"), fontSizeSp = 9)
            Spacer(GlanceModifier.height(4.dp))
            WidgetTitle(if (payload.isReady) mainText else title, maxLines = if (isCompact) 2 else 4, fontSizeSp = 12)
            if (!payload.isReady) {
                WidgetCaption(data.stringValue("subtitle", "More coming soon!"), maxLines = 1, fontSizeSp = 10)
            }
        } else {
            Spacer(GlanceModifier.height(8.dp))
            if (payload.isReady) {
                CourseProgress(
                    payload,
                    rowWidthDp = if (isCompact) 116 else 126,
                    trackWidthDp = if (isCompact) 42 else 52,
                    fontSizeSp = if (isCompact) 11 else 12,
                )
                Spacer(GlanceModifier.height(8.dp))
            }
            WidgetTitle(title, maxLines = if (isCompact) 2 else 3, fontSizeSp = if (isCompact) 13 else 14)
        }
    }
}

@Composable
private fun CourseProgress(
    payload: MeupHomeWidgetPayload,
    rowWidthDp: Int,
    trackWidthDp: Int,
    fontSizeSp: Int = 12,
) {
    val data = payload.data
    val completed = data.intValue("completedLessons")
    val total = data.intValue("totalLessons")
    if (total <= 0) return

    Row(
        modifier = GlanceModifier.width(rowWidthDp.dp),
        verticalAlignment = androidx.glance.layout.Alignment.Vertical.CenterVertically,
    ) {
        ProgressSegments(completed, total, widthDp = trackWidthDp)
        Spacer(GlanceModifier.width(8.dp))
        Text(
            text = "$completed/$total lesson",
            maxLines = 1,
            style = TextStyle(color = CourseMutedText, fontSize = fontSizeSp.sp),
        )
    }
}
