package com.hddhistory.app.homewidget

import android.content.Context
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.LocalSize
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.provideContent
import androidx.glance.currentState
import androidx.glance.layout.Column
import androidx.glance.layout.ContentScale
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import com.hddhistory.app.MainActivity
import com.hddhistory.app.R
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.actionStartActivity

class InProgressHomeWidget : CourseHomeWidget(HDDhistoryWidgetType.InProgress)

class SuggestCourseHomeWidget : CourseHomeWidget(HDDhistoryWidgetType.SuggestCourse)

abstract class CourseHomeWidget(
    private val type: HDDhistoryWidgetType,
) : GlanceAppWidget() {
    override val stateDefinition = HomeWidgetGlanceStateDefinition()
    override val sizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val state = currentState<HomeWidgetGlanceState>()
            val payload = state.preferences.readHDDhistoryPayload(type)
            val widgetSize = LocalSize.current
            val isMedium = widgetSize.width >= 190.dp
            val isCompact = widgetSize.width < 170.dp || widgetSize.height < 145.dp
            WidgetCard(
                modifier = GlanceModifier.clickable(
                    onClick = actionStartActivity<MainActivity>(context, Uri.parse(payload.deeplink)),
                ),
                backgroundResId = if (payload.isReady) {
                    R.drawable.hddhistory_widget_card_shape
                } else {
                    R.drawable.hddhistory_widget_card_fallback_shape
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
    type: HDDhistoryWidgetType,
    state: HomeWidgetGlanceState,
    payload: HDDhistoryHomeWidgetPayload,
    isMedium: Boolean,
    isCompact: Boolean,
) {
    val data = payload.data
    val image = state.preferences.imageProviderFor(type, data)
    val title = type.titleFor(data, payload.isReady)
    val mainText = when (type) {
        HDDhistoryWidgetType.SuggestCourse -> data.stringValue("description", data.stringValue("subtitle", title))
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
    type: HDDhistoryWidgetType,
    payload: HDDhistoryHomeWidgetPayload,
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
        WidgetImage(
            provider = image,
            widthDp = 110,
            heightDp = if (type == HDDhistoryWidgetType.SuggestCourse && !payload.isReady) 75 else 110,
            contentScale = if (payload.isReady) ContentScale.Crop else ContentScale.Fit,
        )
        Spacer(GlanceModifier.width(24.dp))
        Column(modifier = GlanceModifier.fillMaxWidth()) {
            if (type == HDDhistoryWidgetType.SuggestCourse) {
                if (payload.isReady) {
                    SuggestLabel(data.stringValue("label", "Today's suggestion"), fontSizeSp = 12)
                    Spacer(GlanceModifier.height(4.dp))
                }
                WidgetTitle(if (payload.isReady) mainText else title, maxLines = 3, fontSizeSp = 16)
                if (!payload.isReady) {
                    WidgetCaption(data.stringValue("subtitle", "More coming soon!"), maxLines = 1, fontSizeSp = 12)
                }
            } else {
                if (payload.isReady) {
                    CourseProgress(payload, rowWidthDp = 168, trackWidthDp = 76)
                    Spacer(GlanceModifier.height(4.dp))
                }
                WidgetTitle(title, maxLines = if (payload.isReady) 2 else 3, fontSizeSp = 20)
            }
        }
    }
}

@Composable
private fun SmallCourseContent(
    type: HDDhistoryWidgetType,
    payload: HDDhistoryHomeWidgetPayload,
    image: androidx.glance.ImageProvider,
    title: String,
    mainText: String,
    isCompact: Boolean,
) {
    val data = payload.data
    val imageWidth = if (isCompact) 44 else if (type == HDDhistoryWidgetType.SuggestCourse && !payload.isReady) 76 else if (type == HDDhistoryWidgetType.InProgress && !payload.isReady) 70 else 52
    val imageHeight = if (isCompact) 44 else if (type == HDDhistoryWidgetType.SuggestCourse && !payload.isReady) 52 else if (type == HDDhistoryWidgetType.InProgress && !payload.isReady) 70 else 52

    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .padding(16.dp),
    ) {
        WidgetImage(
            provider = image,
            widthDp = imageWidth,
            heightDp = imageHeight,
            contentScale = if (payload.isReady) ContentScale.Crop else ContentScale.Fit,
        )
        if (type == HDDhistoryWidgetType.SuggestCourse) {
            Spacer(GlanceModifier.height(8.dp))
            if (payload.isReady) {
                SuggestLabel(data.stringValue("label", "Today's suggestion"), fontSizeSp = 10)
                Spacer(GlanceModifier.height(4.dp))
            }
            WidgetTitle(if (payload.isReady) mainText else title, maxLines = if (payload.isReady && !isCompact) 3 else 2, fontSizeSp = 14)
            if (!payload.isReady) {
                WidgetCaption(data.stringValue("subtitle", "More coming soon!"), maxLines = 1, fontSizeSp = 10)
            }
        } else {
            Spacer(GlanceModifier.height(if (payload.isReady) 8.dp else 6.dp))
            if (payload.isReady) {
                CourseProgress(
                    payload,
                    rowWidthDp = if (isCompact) 116 else 126,
                    trackWidthDp = if (isCompact) 42 else 52,
                    fontSizeSp = if (isCompact) 11 else 12,
                )
                Spacer(GlanceModifier.height(8.dp))
            }
            WidgetTitle(title, maxLines = if (payload.isReady && !isCompact) 3 else 2, fontSizeSp = if (isCompact) 13 else 14)
        }
    }
}
