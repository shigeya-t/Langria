package io.github.shigeya_t.langria

import android.app.Activity
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.wrapContentHeight
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.viewinterop.AndroidView
import com.google.android.gms.ads.AdListener
import com.google.android.gms.ads.AdRequest
import com.google.android.gms.ads.AdSize
import com.google.android.gms.ads.AdView
import com.google.android.gms.ads.LoadAdError
import com.google.android.gms.ads.MobileAds
import com.google.android.ump.ConsentInformation
import com.google.android.ump.ConsentRequestParameters
import com.google.android.ump.UserMessagingPlatform
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume

/**
 * Asks for consent (UMP, showing Google's form where the law needs one) and
 * starts the Mobile Ads SDK once ads may be requested, as Ads.swift does.
 * Android has no App Tracking Transparency prompt.
 */
class Ads {
  /** True once consent allows ad requests and the SDK has started. */
  var ready by mutableStateOf(false)
    private set
  /** Some consent messages (GDPR) need a way back to the choices, shown in the settings. */
  var privacyOptionsRequired by mutableStateOf(false)
    private set
  private var gathering = false

  /** Runs each time the app comes to the front, as consent can expire. */
  suspend fun gatherConsent(activity: Activity) {
    if (ready || gathering) return
    gathering = true
    try {
      val consent = UserMessagingPlatform.getConsentInformation(activity)
      // On failure the choices from an earlier launch still apply: carry on and check canRequestAds.
      suspendCancellableCoroutine { continuation ->
        consent.requestConsentInfoUpdate(activity, ConsentRequestParameters.Builder().build(), { continuation.resume(Unit) }, { continuation.resume(Unit) })
      }
      suspendCancellableCoroutine { continuation ->
        UserMessagingPlatform.loadAndShowConsentFormIfRequired(activity) { continuation.resume(Unit) }
      }
      privacyOptionsRequired = consent.privacyOptionsRequirementStatus == ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED
      start(activity, consent)
    } finally {
      gathering = false
    }
  }

  fun showPrivacyOptions(activity: Activity) {
    UserMessagingPlatform.showPrivacyOptionsForm(activity) {
      start(activity, UserMessagingPlatform.getConsentInformation(activity))
    }
  }

  private fun start(activity: Activity, consent: ConsentInformation) {
    if (ready || !consent.canRequestAds()) return
    ready = true
    // Starting the SDK takes a while; it is meant to run off the main thread.
    CoroutineScope(Dispatchers.IO).launch { MobileAds.initialize(activity.applicationContext) }
  }
}

/** An inline adaptive banner across the width of the page. It takes no room until an ad arrives. */
@Composable
fun BannerAd(modifier: Modifier = Modifier) {
  BoxWithConstraints(modifier.fillMaxWidth()) {
    val width = maxWidth.value.toInt()
    // Set by the ad that arrives: an inline adaptive ad picks its own height.
    var height by remember { mutableIntStateOf(0) }
    val density = LocalDensity.current
    // A new width (rotation, a resized window) needs an ad of the new size.
    key(width) {
      Box(Modifier.fillMaxWidth().height(with(density) { height.toDp() }).clipToBounds()) {
        // Measured at its own height even before an ad arrives, as the SDK will
        // not load into a zero-height view; the box above hides it until then.
        AndroidView(
          modifier = Modifier.fillMaxWidth().wrapContentHeight(Alignment.Top, unbounded = true),
          factory = { context ->
            AdView(context).apply {
              setAdSize(AdSize.getCurrentOrientationInlineAdaptiveBannerAdSize(context, width))
              adUnitId = BuildConfig.BANNER_UNIT_ID
              adListener = object : AdListener() {
                override fun onAdLoaded() { height = adSize?.getHeightInPixels(context) ?: 0 }
                override fun onAdFailedToLoad(error: LoadAdError) { height = 0 }
              }
              loadAd(AdRequest.Builder().build())
            }
          },
          onRelease = { it.destroy() },
        )
      }
    }
  }
}
