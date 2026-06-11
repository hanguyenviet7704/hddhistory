package com.eup.meup.homewidget

import android.content.SharedPreferences
import android.graphics.BitmapFactory
import androidx.glance.ImageProvider
import java.io.File
import org.json.JSONObject

internal fun SharedPreferences.imageProviderFor(
    type: MeupWidgetType,
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
    BitmapFactory.decodeFile(imageFile.absolutePath)
}.getOrNull()
