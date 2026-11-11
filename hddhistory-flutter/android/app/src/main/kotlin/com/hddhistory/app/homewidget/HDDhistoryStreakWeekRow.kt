package com.hddhistory.app.homewidget

import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.ContentScale
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.height
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.hddhistory.app.R

private val WeekActiveText = ColorProvider(androidx.compose.ui.graphics.Color(0xFF4B44CA))
private val WeekInactiveText = ColorProvider(androidx.compose.ui.graphics.Color(0xFF110751))
private val WeekCheckText = ColorProvider(androidx.compose.ui.graphics.Color.White)

@Composable
internal fun StreakWeekStudyRow(
    days: List<Boolean>,
    labels: List<String>,
    gapDp: Int,
    daySizeDp: Int,
) {
    val cellWidthDp = daySizeDp + gapDp
    val rowWidthDp = (cellWidthDp * 6) + daySizeDp
    Row(modifier = GlanceModifier.width(rowWidthDp.dp)) {
        StreakWeekDay(labels.getOrElse(0) { "M" }, days.isStudied(0), daySizeDp, cellWidthDp)
        StreakWeekDay(labels.getOrElse(1) { "T" }, days.isStudied(1), daySizeDp, cellWidthDp)
        StreakWeekDay(labels.getOrElse(2) { "W" }, days.isStudied(2), daySizeDp, cellWidthDp)
        StreakWeekDay(labels.getOrElse(3) { "T" }, days.isStudied(3), daySizeDp, cellWidthDp)
        StreakWeekDay(labels.getOrElse(4) { "F" }, days.isStudied(4), daySizeDp, cellWidthDp)
        StreakWeekDay(labels.getOrElse(5) { "S" }, days.isStudied(5), daySizeDp, cellWidthDp)
        StreakWeekDay(labels.getOrElse(6) { "S" }, days.isStudied(6), daySizeDp, daySizeDp)
    }
}

private fun List<Boolean>.isStudied(index: Int): Boolean = getOrElse(index) { false }

@Composable
private fun StreakWeekDay(label: String, active: Boolean, daySizeDp: Int, cellWidthDp: Int) {
    val labelSizeSp = if (daySizeDp <= 20) 10 else 11
    val checkSizeSp = if (daySizeDp <= 20) 12 else 13

    Column(
        modifier = GlanceModifier.width(cellWidthDp.dp),
        horizontalAlignment = Alignment.Horizontal.CenterHorizontally,
    ) {
        Box(
            modifier = GlanceModifier.size(daySizeDp.dp),
            contentAlignment = Alignment.Center,
        ) {
            Image(
                provider = ImageProvider(if (active) R.drawable.hddhistory_widget_week_day_active_shape else R.drawable.hddhistory_widget_week_day_inactive_shape),
                contentDescription = null,
                modifier = GlanceModifier.fillMaxSize(),
                contentScale = ContentScale.FillBounds,
            )
            if (active) {
                Text(
                    text = "✓",
                    style = TextStyle(color = WeekCheckText, fontSize = checkSizeSp.sp, fontWeight = FontWeight.Bold),
                )
            }
        }
        Spacer(GlanceModifier.height(2.dp))
        Text(
            text = label,
            maxLines = 1,
            style = TextStyle(
                color = if (active) WeekActiveText else WeekInactiveText,
                fontSize = labelSizeSp.sp,
                fontWeight = if (active) FontWeight.Bold else FontWeight.Medium,
            ),
        )
    }
}
