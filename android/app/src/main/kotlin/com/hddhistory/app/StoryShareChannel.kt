package com.hddhistory.app

import android.content.Intent
import android.content.pm.PackageManager
import androidx.core.content.FileProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Hands a rendered PNG to Instagram's or Facebook's story composer.
 *
 * Not doable from Dart: both apps take the image as a `content://` URI on a
 * dedicated `ADD_TO_STORY` intent, and the sending app must grant read
 * permission on that URI. `share_plus` can only raise the generic chooser.
 *
 * The iOS counterpart is StoryShareChannel.swift, which needs the pasteboard
 * instead — same channel name, same contract.
 */
class StoryShareChannel(
    private val activity: MainActivity,
    messenger: BinaryMessenger,
) {
    companion object {
        const val CHANNEL_NAME = "hddhistory/story_share"

        private const val INSTAGRAM_ACTION = "com.instagram.share.ADD_TO_STORY"
        private const val FACEBOOK_ACTION = "com.facebook.stories.ADD_TO_STORY"

        /** Must match the authority declared for the provider in the manifest. */
        private const val PROVIDER_SUFFIX = ".storyshare"
    }

    init {
        MethodChannel(messenger, CHANNEL_NAME).setMethodCallHandler { call, result ->
            if (call.method != "shareToStory") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val platform = call.argument<String>("platform")
            val png = call.argument<ByteArray>("image")
            if (platform == null || png == null) {
                result.success(false)
                return@setMethodCallHandler
            }
            result.success(share(platform, png))
        }
    }

    private fun share(platform: String, png: ByteArray): Boolean {
        val action = when (platform) {
            "instagram" -> INSTAGRAM_ACTION
            "facebook" -> FACEBOOK_ACTION
            else -> return false
        }

        return try {
            // Written under cacheDir/story_share, which the provider's paths file
            // is scoped to — nothing else in the cache becomes readable.
            val dir = File(activity.cacheDir, "story_share").apply { mkdirs() }
            val file = File(dir, "course-story.png")
            file.writeBytes(png)

            val uri = FileProvider.getUriForFile(
                activity,
                activity.packageName + PROVIDER_SUFFIX,
                file,
            )

            val appId = activity.getString(R.string.facebook_app_id)

            val intent = Intent(action).apply {
                setDataAndType(uri, "image/png")
                // The two apps read the app id from DIFFERENT extras, and the
                // comment that used to sit here ("harmless for Facebook Stories")
                // was the bug: Instagram's `source_application` means nothing to
                // Facebook, which wants `com.facebook.platform.extra.APPLICATION_ID`
                // and drops the image without it. Both are set rather than
                // branched — each app ignores the extra it does not know, and one
                // shape is one less thing to keep in sync with the iOS side.
                putExtra("source_application", appId)
                putExtra("com.facebook.platform.extra.APPLICATION_ID", appId)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }

            // resolveActivity is the "is that app installed and does it accept
            // this?" check — without it startActivity throws for absent apps.
            if (intent.resolveActivity(activity.packageManager) == null) return false

            activity.startActivity(intent)
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        } catch (_: Exception) {
            false
        }
    }
}
