package com.eup.meup.homewidget

import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.appwidget.cornerRadius
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
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

private val DarkText = Color(0xFF1B1F24)
private val MutedText = Color(0xFF667085)
private val BrandGreen = Color(0xFF1BAA76)
private val SoftGreen = Color(0xFFE7F6EF)
private val SoftBlue = Color(0xFFEAF2FF)
private val SoftGray = Color(0xFFE4E7EC)
private val DarkTextProvider = ColorProvider(DarkText)
private val MutedTextProvider = ColorProvider(MutedText)
private val BrandGreenProvider = ColorProvider(BrandGreen)
private val WhiteProvider = ColorProvider(Color.White)

@Composable
internal fun WidgetCard(
    modifier: GlanceModifier = GlanceModifier,
    content: @Composable () -> Unit,
) {
    Box(
        modifier = modifier
            .fillMaxSize()
            .background(Color.White)
            .cornerRadius(20.dp)
            .padding(14.dp),
    ) {
        content()
    }
}

@Composable
internal fun WidgetTitle(text: String, maxLines: Int = 2) {
    Text(
        text = text,
        maxLines = maxLines,
        style = TextStyle(
            color = DarkTextProvider,
            fontSize = 16.sp,
            fontWeight = FontWeight.Bold,
        ),
    )
}

@Composable
internal fun WidgetCaption(text: String, maxLines: Int = 2) {
    Text(
        text = text,
        maxLines = maxLines,
        style = TextStyle(color = MutedTextProvider, fontSize = 12.sp),
    )
}

@Composable
internal fun WidgetImage(provider: ImageProvider, sizeDp: Int = 54) {
    Image(
        provider = provider,
        contentDescription = null,
        modifier = GlanceModifier.size(sizeDp.dp).cornerRadius(16.dp),
        contentScale = ContentScale.Crop,
    )
}

@Composable
internal fun ProgressSegments(progress: Double) {
    Row(modifier = GlanceModifier.fillMaxWidth()) {
        repeat(10) { index ->
            Box(
                modifier = GlanceModifier
                    .height(6.dp)
                    .width(8.dp)
                    .background(if (index < (progress * 10).toInt()) BrandGreen else SoftGray)
                    .cornerRadius(4.dp),
            ) {}
            if (index < 9) Spacer(GlanceModifier.width(3.dp))
        }
    }
}

@Composable
internal fun WeekStudyRow(days: List<Boolean>) {
    Row(
        modifier = GlanceModifier.fillMaxWidth(),
        horizontalAlignment = Alignment.Horizontal.CenterHorizontally,
    ) {
        days.take(7).forEachIndexed { index, active ->
            Box(
                modifier = GlanceModifier
                    .size(18.dp)
                    .background(if (active) BrandGreen else SoftGreen)
                    .cornerRadius(9.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text = if (active) "✓" else (index + 1).toString(),
                    style = TextStyle(
                        color = if (active) WhiteProvider else MutedTextProvider,
                        fontSize = 9.sp,
                        fontWeight = FontWeight.Bold,
                    ),
                )
            }
            if (index < 6) Spacer(GlanceModifier.width(4.dp))
        }
    }
}

@Composable
internal fun SuggestLabel(text: String) {
    Box(
        modifier = GlanceModifier
            .background(SoftBlue)
            .cornerRadius(10.dp)
            .padding(horizontal = 8.dp, vertical = 4.dp),
    ) {
        Text(
            text = text,
            style = TextStyle(color = DarkTextProvider, fontSize = 11.sp, fontWeight = FontWeight.Bold),
        )
    }
}
