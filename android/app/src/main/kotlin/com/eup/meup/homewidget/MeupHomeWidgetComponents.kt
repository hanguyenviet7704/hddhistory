package com.eup.meup.homewidget

import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.ContentScale
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.eup.meup.R

private val BrandText = androidx.compose.ui.graphics.Color(0xFF362F82)
private val MutedText = androidx.compose.ui.graphics.Color(0xFF8A86A8)
private val BrandPrimary = androidx.compose.ui.graphics.Color(0xFF4B44CA)
private val SoftDot = androidx.compose.ui.graphics.Color(0xFFD8D5EA)
internal val BrandTextProvider = ColorProvider(BrandText)
internal val MutedTextProvider = ColorProvider(MutedText)
private val WhiteProvider = ColorProvider(androidx.compose.ui.graphics.Color.White)

@Composable
internal fun WidgetCard(
    modifier: GlanceModifier = GlanceModifier,
    backgroundResId: Int = R.drawable.meup_widget_card_background,
    paddingDp: Int = 16,
    content: @Composable () -> Unit,
) {
    Box(
        modifier = modifier
            .fillMaxSize(),
    ) {
        Image(
            provider = ImageProvider(backgroundResId),
            contentDescription = null,
            modifier = GlanceModifier.fillMaxSize(),
            contentScale = ContentScale.FillBounds,
        )
        Box(
            modifier = GlanceModifier
                .fillMaxSize()
                .padding(paddingDp.dp),
        ) {
            content()
        }
    }
}

@Composable
internal fun WidgetTitle(
    text: String,
    maxLines: Int = 2,
    fontSizeSp: Int = 14,
) {
    Text(
        text = text,
        maxLines = maxLines,
        style = TextStyle(
            color = BrandTextProvider,
            fontSize = fontSizeSp.sp,
            fontWeight = FontWeight.Bold,
        ),
    )
}

@Composable
internal fun WidgetCaption(
    text: String,
    maxLines: Int = 2,
    fontSizeSp: Int = 12,
) {
    Text(
        text = text,
        maxLines = maxLines,
        style = TextStyle(
            color = MutedTextProvider,
            fontSize = fontSizeSp.sp,
            fontWeight = FontWeight.Medium,
        ),
    )
}

@Composable
internal fun WidgetImage(
    provider: ImageProvider,
    sizeDp: Int = 52,
) {
    Image(
        provider = provider,
        contentDescription = null,
        modifier = GlanceModifier.size(sizeDp.dp),
        contentScale = ContentScale.Crop,
    )
}

@Composable
internal fun ProgressSegments(
    completed: Int,
    total: Int,
    widthDp: Int = 126,
) {
    val safeTotal = total.coerceAtLeast(1)
    val safeCompleted = completed.coerceIn(0, safeTotal)
    val activeWidth = ((widthDp * safeCompleted) / safeTotal).coerceAtLeast(if (safeCompleted > 0) 6 else 0)

    Box(
        modifier = GlanceModifier
            .width(widthDp.dp)
            .height(6.dp)
            .background(SoftDot),
        contentAlignment = Alignment.CenterStart,
    ) {
        if (activeWidth > 0) {
            Box(
                modifier = GlanceModifier
                    .width(activeWidth.dp)
                    .height(6.dp)
                    .background(BrandPrimary),
            ) {}
        }
    }
}

@Composable
internal fun WeekStudyRow(days: List<Boolean>) {
    val labels = listOf("M", "T", "W", "T", "F", "S", "S")
    Row(
        modifier = GlanceModifier.fillMaxWidth(),
        horizontalAlignment = Alignment.Horizontal.CenterHorizontally,
    ) {
        days.take(7).forEachIndexed { index, active ->
            Box(
                modifier = GlanceModifier
                    .size(24.dp)
                    .background(if (active) BrandPrimary else SoftDot),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text = if (active) "✓" else labels[index],
                    style = TextStyle(
                        color = if (active) WhiteProvider else MutedTextProvider,
                        fontSize = 10.sp,
                        fontWeight = FontWeight.Bold,
                    ),
                )
            }
            if (index < 6) Spacer(GlanceModifier.width(8.dp))
        }
    }
}

@Composable
internal fun SuggestLabel(text: String) {
    Text(
        text = text,
        maxLines = 1,
        style = TextStyle(
            color = MutedTextProvider,
            fontSize = 12.sp,
            fontWeight = FontWeight.Medium,
        ),
    )
}
