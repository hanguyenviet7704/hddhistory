package com.hddhistory.app.homewidget

import android.content.Context
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalSize
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.provideContent
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.ContentScale
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import com.hddhistory.app.R
import com.hddhistory.app.MainActivity
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.actionStartActivity

private val StreakTitleText = BrandTextProvider

class StreakHomeWidget : GlanceAppWidget() {
    override val stateDefinition = HomeWidgetGlanceStateDefinition()
    override val sizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val state = currentState<HomeWidgetGlanceState>()
            val payload = state.preferences.readHDDhistoryPayload(HDDhistoryWidgetType.Streak)
            val widgetSize = LocalSize.current
            val isMedium = widgetSize.width >= 190.dp
            val isCompact = widgetSize.width < 170.dp || widgetSize.height < 145.dp
            WidgetCard(
                modifier = GlanceModifier.clickable(
                    onClick = actionStartActivity<MainActivity>(context, Uri.parse(payload.deeplink)),
                ),
                backgroundResId = R.drawable.hddhistory_widget_card_shape,
                paddingDp = 0,
            ) {
                StreakContent(state, payload, isMedium, isCompact)
            }
        }
    }
}

@Composable
private fun StreakContent(
    state: HomeWidgetGlanceState,
    payload: HDDhistoryHomeWidgetPayload,
    isMedium: Boolean,
    isCompact: Boolean,
) {
    val data = payload.data
    val days = data.boolList("weekStudy", 7)
    val weekLabels = data.stringList("weekLabels", listOf("M", "T", "W", "T", "F", "S", "S"), 7)
    val currentStreak = data.intValue("currentStreak")
    val countText = data.stringValue("countText", "$currentStreak day${if (currentStreak == 1) "" else "s"}")
    val subtitle = data.stringValue("subtitle", "Start your streak today")
    val flame = state.preferences.imageProviderFor(HDDhistoryWidgetType.Streak, data)

    if (isMedium) {
        MediumStreakContent(flame, countText, subtitle, days, weekLabels, isCompact)
    } else {
        SmallStreakContent(flame, countText, subtitle, isCompact)
    }
}

@Composable
private fun SmallStreakContent(
    flame: androidx.glance.ImageProvider,
    countText: String,
    subtitle: String,
    isCompact: Boolean,
) {
    val imageSize = if (isCompact) 54 else 68
    val titleSize = if (isCompact) 22 else 26
    val captionSize = if (isCompact) 10 else 12

    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .padding(start = 14.dp, top = if (isCompact) 10.dp else 18.dp, end = 14.dp, bottom = 10.dp),
        horizontalAlignment = Alignment.Horizontal.CenterHorizontally,
    ) {
        WidgetImage(flame, sizeDp = imageSize)
        Spacer(GlanceModifier.height(if (isCompact) 2.dp else 6.dp))
        StreakCountText(countText, fontSizeSp = titleSize)
        WidgetCaption(subtitle, maxLines = 1, fontSizeSp = captionSize)
    }
}

@Composable
private fun MediumStreakContent(
    flame: androidx.glance.ImageProvider,
    countText: String,
    subtitle: String,
    days: List<Boolean>,
    weekLabels: List<String>,
    isCompact: Boolean,
) {
    val verticalPadding = if (isCompact) 12 else 16
    val flameSize = if (isCompact) 42 else 48
    val artWidth = if (isCompact) 112 else 148
    val artHeight = if (isCompact) 68 else 90
    val spacerHeight = if (isCompact) 10 else 20
    val daySize = if (isCompact) 20 else 22

    Box(modifier = GlanceModifier.fillMaxSize()) {
        Row(
            modifier = GlanceModifier.fillMaxSize(),
            horizontalAlignment = Alignment.Horizontal.End,
            verticalAlignment = Alignment.Vertical.Bottom,
        ) {
            Image(
                provider = ImageProvider(R.drawable.hddhistory_widget_streak_medium_art),
                contentDescription = null,
                modifier = GlanceModifier.width(artWidth.dp).height(artHeight.dp),
                contentScale = ContentScale.Fit,
            )
        }
        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .padding(start = 16.dp, top = verticalPadding.dp, end = 16.dp, bottom = 10.dp),
        ) {
            Row(verticalAlignment = Alignment.Vertical.CenterVertically) {
                WidgetImage(flame, sizeDp = flameSize)
                Spacer(GlanceModifier.width(12.dp))
                Column {
                    StreakCountText(countText, fontSizeSp = 24)
                    WidgetCaption(subtitle, maxLines = 1, fontSizeSp = 12)
                }
            }

            Spacer(GlanceModifier.height(spacerHeight.dp))
            StreakWeekStudyRow(days, weekLabels, gapDp = if (isCompact) 7 else 8, daySizeDp = daySize)
        }
    }
}

@Composable
private fun StreakCountText(
    countText: String,
    fontSizeSp: Int,
) {
    Text(
        text = countText,
        maxLines = 1,
        style = TextStyle(
            color = StreakTitleText,
            fontSize = fontSizeSp.sp,
            fontWeight = FontWeight.Bold,
        ),
    )
}
