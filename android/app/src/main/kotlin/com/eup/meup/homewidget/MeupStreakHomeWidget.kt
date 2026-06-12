package com.eup.meup.homewidget

import android.content.Context
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.LocalSize
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.eup.meup.R
import com.eup.meup.MainActivity
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.actionStartActivity

private val StreakTitleText = BrandTextProvider

class StreakHomeWidget : GlanceAppWidget() {
    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val state = currentState<HomeWidgetGlanceState>()
            val payload = state.preferences.readMeupPayload(MeupWidgetType.Streak)
            val isMedium = LocalSize.current.width >= 240.dp
            WidgetCard(
                modifier = GlanceModifier.clickable(
                    onClick = actionStartActivity<MainActivity>(context, Uri.parse(payload.deeplink)),
                ),
                backgroundResId = R.drawable.meup_widget_card_background,
                paddingDp = 0,
            ) {
                StreakContent(state, payload, isMedium)
            }
        }
    }
}

@Composable
private fun StreakContent(
    state: HomeWidgetGlanceState,
    payload: MeupHomeWidgetPayload,
    isMedium: Boolean,
) {
    val data = payload.data
    val days = data.boolList("weekStudy", 7)
    val currentStreak = data.intValue("currentStreak")
    val subtitle = data.stringValue("subtitle", "Start your streak today")
    val flame = state.preferences.imageProviderFor(MeupWidgetType.Streak, data)

    if (isMedium) {
        MediumStreakContent(flame, currentStreak, subtitle, days)
    } else {
        SmallStreakContent(flame, currentStreak, subtitle)
    }
}

@Composable
private fun SmallStreakContent(
    flame: androidx.glance.ImageProvider,
    currentStreak: Int,
    subtitle: String,
) {
    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .padding(start = 16.dp, top = 18.dp, end = 16.dp, bottom = 14.dp),
        horizontalAlignment = Alignment.Horizontal.CenterHorizontally,
    ) {
        WidgetImage(flame, sizeDp = 68)
        Spacer(GlanceModifier.height(6.dp))
        StreakCountText(currentStreak, fontSizeSp = 26)
        WidgetCaption(subtitle, maxLines = 2, fontSizeSp = 12)
    }
}

@Composable
private fun MediumStreakContent(
    flame: androidx.glance.ImageProvider,
    currentStreak: Int,
    subtitle: String,
    days: List<Boolean>,
) {
    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .padding(start = 20.dp, top = 14.dp, end = 20.dp, bottom = 14.dp),
        horizontalAlignment = Alignment.Horizontal.CenterHorizontally,
    ) {
        Row(
            modifier = GlanceModifier.fillMaxWidth(),
            verticalAlignment = Alignment.Vertical.CenterVertically,
        ) {
            WidgetImage(flame, sizeDp = 44)
            Spacer(GlanceModifier.width(8.dp))
            Column {
                StreakCountText(currentStreak, fontSizeSp = 24)
                WidgetCaption(subtitle, maxLines = 1, fontSizeSp = 12)
            }
        }

        Spacer(GlanceModifier.height(18.dp))
        WeekStudyRow(days)
    }
}

@Composable
private fun StreakCountText(
    currentStreak: Int,
    fontSizeSp: Int,
) {
    Text(
        text = "$currentStreak day${if (currentStreak == 1) "" else "s"}",
        style = TextStyle(
            color = StreakTitleText,
            fontSize = fontSizeSp.sp,
            fontWeight = FontWeight.Bold,
        ),
    )
}
