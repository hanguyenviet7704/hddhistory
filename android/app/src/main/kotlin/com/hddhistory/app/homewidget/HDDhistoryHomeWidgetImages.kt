package com.hddhistory.app.homewidget

import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import androidx.glance.ImageProvider
import java.io.File
import org.json.JSONObject

internal fun SharedPreferences.imageProviderFor(
    type: HDDhistoryWidgetType,
    data: JSONObject,
): ImageProvider {
    val imagePathKey = data.stringValue("imagePathKey")
    imagePathKey.takeIf { it.isNotBlank() }
        ?.let { getString(it, null) }
        ?.let { path -> decodeWidgetImage(path) }
        ?.let { return ImageProvider(it) }

    val staticAssetKey = data.stringValue("staticAssetKey", type.fallbackImageKey)
    getString(staticAssetKey, null)
        ?.let { path -> decodeWidgetImage(path) }
        ?.let { return ImageProvider(it) }

    return ImageProvider(type.fallbackImageResId)
}

private fun decodeWidgetImage(path: String) = runCatching {
    val imageFile = File(path)
    if (!imageFile.exists()) return@runCatching null
    BitmapFactory.decodeFile(imageFile.absolutePath)?.roundedCorners()
}.getOrNull()

private fun Bitmap.roundedCorners(): Bitmap {
    val output = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
    val radius = minOf(width, height) * 0.12f
    val rect = RectF(0f, 0f, width.toFloat(), height.toFloat())
    val path = Path().apply { addRoundRect(rect, radius, radius, Path.Direction.CW) }

    Canvas(output).apply {
        clipPath(path)
        drawBitmap(this@roundedCorners, 0f, 0f, Paint(Paint.ANTI_ALIAS_FLAG))
    }
    return output
}
