package com.eup.meup.homewidget

import android.content.Context
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.eup.meup.MainActivity
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.actionStartActivity

private val StreakTitleText = ColorProvider(Color(0xFF1B1F24))

class StreakHomeWidget : GlanceAppWidget() {
    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val state = currentState<HomeWidgetGlanceState>()
            val payload = state.preferences.readMeupPayload(MeupWidgetType.Streak)
            WidgetCard(
                modifier = GlanceModifier.clickable(
                    onClick = actionStartActivity<MainActivity>(context, Uri.parse(payload.deeplink)),
                ),
            ) {
                StreakContent(state, payload)
            }
        }
    }
}

@Composable
private fun StreakContent(
    state: HomeWidgetGlanceState,
    payload: MeupHomeWidgetPayload,
) {
    val data = payload.data
    val days = data.boolList("weekStudy", 7)
    val currentStreak = data.intValue("currentStreak")
    val subtitle = data.stringValue("subtitle", "Start your streak today")
    val flame = state.preferences.imageProviderFor(MeupWidgetType.Streak, data)

    Column(horizontalAlignment = Alignment.Horizontal.CenterHorizontally) {
        Row(
            modifier = GlanceModifier.fillMaxWidth(),
            verticalAlignment = Alignment.Vertical.CenterVertically,
            horizontalAlignment = Alignment.Horizontal.CenterHorizontally,
        ) {
            WidgetImage(flame, sizeDp = 44)
            Spacer(GlanceModifier.width(8.dp))
            Column {
                Text(
                    text = "$currentStreak day${if (currentStreak == 1) "" else "s"}",
                    style = TextStyle(
                        color = StreakTitleText,
                        fontSize = 20.sp,
                        fontWeight = FontWeight.Bold,
                    ),
                )
                WidgetCaption(subtitle, maxLines = 1)
            }
        }

        Spacer(GlanceModifier.height(14.dp))
        WeekStudyRow(days)
    }
}
