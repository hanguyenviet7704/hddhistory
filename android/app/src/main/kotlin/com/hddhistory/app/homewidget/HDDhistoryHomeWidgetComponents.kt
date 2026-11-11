package com.hddhistory.app.homewidget

import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
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
import androidx.glance.unit.ColorProvider
import com.hddhistory.app.R

private val BrandText = androidx.compose.ui.graphics.Color(0xFF362F82)
private val MutedText = androidx.compose.ui.graphics.Color(0xFF8A86A8)
internal val BrandTextProvider = ColorProvider(BrandText)
internal val MutedTextProvider = ColorProvider(MutedText)

@Composable
internal fun WidgetCard(
    modifier: GlanceModifier = GlanceModifier,
    backgroundResId: Int = R.drawable.hddhistory_widget_card_shape,
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
    WidgetImage(provider = provider, widthDp = sizeDp, heightDp = sizeDp, contentScale = ContentScale.Crop)
}

@Composable
internal fun WidgetImage(
    provider: ImageProvider,
    widthDp: Int,
    heightDp: Int,
    contentScale: ContentScale = ContentScale.Crop,
) {
    Image(
        provider = provider,
        contentDescription = null,
        modifier = GlanceModifier.width(widthDp.dp).height(heightDp.dp),
        contentScale = contentScale,
    )
}

@Composable
internal fun ProgressSegments(
    completed: Int,
    total: Int,
    widthDp: Int = 52,
    heightDp: Int = 6,
) {
    val safeTotal = total.coerceAtLeast(1)
    val safeCompleted = completed.coerceIn(0, safeTotal)
    val activeWidth = ((widthDp * safeCompleted) / safeTotal).coerceAtLeast(if (safeCompleted > 0) heightDp else 0)

    Box(
        modifier = GlanceModifier
            .width(widthDp.dp)
            .height(heightDp.dp),
        contentAlignment = Alignment.CenterStart,
    ) {
        Image(
            provider = ImageProvider(R.drawable.hddhistory_widget_progress_track_shape),
            contentDescription = null,
            modifier = GlanceModifier.fillMaxSize(),
            contentScale = ContentScale.FillBounds,
        )
        if (activeWidth > 0) {
            Image(
                provider = ImageProvider(R.drawable.hddhistory_widget_progress_active_shape),
                contentDescription = null,
                modifier = GlanceModifier
                    .width(activeWidth.dp)
                    .height(heightDp.dp),
                contentScale = ContentScale.FillBounds,
            )
        }
    }
}

@Composable
internal fun SuggestLabel(
    text: String,
    fontSizeSp: Int,
) {
    Text(
        text = text,
        maxLines = 1,
        style = TextStyle(
            color = MutedTextProvider,
            fontSize = fontSizeSp.sp,
            fontWeight = FontWeight.Medium,
        ),
    )
}

@Composable
internal fun CourseProgress(
    payload: HDDhistoryHomeWidgetPayload,
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
        verticalAlignment = Alignment.Vertical.CenterVertically,
    ) {
        ProgressSegments(completed, total, widthDp = trackWidthDp)
        Spacer(GlanceModifier.width(8.dp))
        Text(
            text = data.stringValue("progressText", "$completed/$total lesson"),
            maxLines = 1,
            style = TextStyle(color = MutedTextProvider, fontSize = fontSizeSp.sp),
        )
    }
}
