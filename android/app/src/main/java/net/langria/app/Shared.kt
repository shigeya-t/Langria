package net.langria.app

import android.annotation.SuppressLint
import android.content.Context
import android.content.SharedPreferences
import android.os.LocaleList
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.core.content.edit
import kotlinx.coroutines.suspendCancellableCoroutine
import org.json.JSONArray
import org.json.JSONObject
import kotlin.coroutines.resume

/**
 * The UI text (`i18n.js`), the target languages (`languages.js`) and the
 * commit hash (`version.js`) shared with the web app, the extension and the
 * iOS app. Android has no JavaScript engine of its own, so the scripts run once
 * in a WebView and their data is kept (until the app is updated); `t` and
 * `languageLabel` follow i18n.js.
 */
class Shared private constructor(private val prefs: SharedPreferences, data: JSONObject) {
  companion object {
    const val CUSTOM_TARGET = "other"
    private const val CACHE_KEY = "langria-shared-cache"
    private const val CACHE_VERSION_KEY = "langria-shared-cache-version"

    @SuppressLint("SetJavaScriptEnabled")
    suspend fun load(context: Context): Shared {
      val prefs = Settings.prefs(context)
      // The scripts come with the app, so they change only when it is updated.
      val version = context.packageManager.getPackageInfo(context.packageName, 0).lastUpdateTime
      val cached = prefs.getString(CACHE_KEY, null)
      if (cached != null && prefs.getLong(CACHE_VERSION_KEY, 0) == version) {
        runCatching { return Shared(prefs, JSONObject(cached)) }
      }
      val scripts = listOf("version.js", "i18n.js", "languages.js").mapNotNull { name ->
        runCatching { context.assets.open(name).bufferedReader().use { it.readText() } }.getOrNull()
      }
      val json = suspendCancellableCoroutine { continuation ->
        val webView = WebView(context)
        webView.settings.javaScriptEnabled = true
        webView.webViewClient = object : WebViewClient() {
          override fun onPageFinished(view: WebView, url: String?) {
            val script = scripts.joinToString(";\n") + ";\nJSON.stringify({ messages: LangriaI18n.messages, targets: LangriaLanguages.targets, commit: globalThis.LANGRIA_COMMIT || '' })"
            view.evaluateJavascript(script) { result ->
              view.destroy()
              // The result comes back as a JSON value: here a string holding JSON.
              val text = runCatching { JSONArray("[$result]").getString(0) }.getOrDefault("{}")
              if (continuation.isActive) continuation.resume(text)
            }
          }
        }
        webView.loadDataWithBaseURL(null, "<!doctype html><title></title>", "text/html", "utf-8", null)
        continuation.invokeOnCancellation { webView.destroy() }
      }
      prefs.edit { putString(CACHE_KEY, json); putLong(CACHE_VERSION_KEY, version) }
      return Shared(prefs, JSONObject(json))
    }
  }

  private val messages: Map<String, Map<String, String>>
  /** The target languages, by the English name given to the model. */
  val targets: List<String>
  private val labels: Map<String, Map<String, String>>
  /** BCP 47 tag of each target, for voice input and reading aloud. */
  val locales: Map<String, String>
  val commit: String

  /** The language picked in the settings ("en" / "ja"), or null to follow the device. */
  var choice by mutableStateOf<String?>(null)
    private set
  /** The UI language in use, "en" or "ja". */
  var language by mutableStateOf("en")
    private set

  init {
    val messageData = data.optJSONObject("messages") ?: JSONObject()
    messages = messageData.keys().asSequence().associateWith { language ->
      val entries = messageData.getJSONObject(language)
      entries.keys().asSequence().associateWith { entries.getString(it) }
    }
    val targetData = data.optJSONObject("targets") ?: JSONObject()
    targets = targetData.keys().asSequence().toList().ifEmpty { listOf("English", "Japanese") }
    labels = targets.associateWith { name ->
      val entry = targetData.optJSONObject(name) ?: JSONObject()
      entry.keys().asSequence().associateWith { entry.getString(it) }
    }
    locales = labels.mapValues { it.value["locale"].orEmpty() }.filterValues { it.isNotEmpty() }
    commit = data.optString("commit")
    choose(prefs.getString("langria-ui-language", null))
  }

  fun choose(next: String?) {
    choice = next?.takeIf { it in messages }
    prefs.edit { if (choice == null) remove("langria-ui-language") else putString("langria-ui-language", choice) }
    language = choice ?: if (LocaleList.getDefault()[0]?.language == "ja") "ja" else "en"
  }

  fun t(key: String, params: Map<String, String>): String {
    val text = messages[language]?.get(key) ?: messages["en"]?.get(key) ?: key
    return Regex("\\{(\\w+)\\}").replace(text) { match -> params[match.groupValues[1]] ?: match.value }
  }

  fun t(key: String, vararg params: Pair<String, String>) = t(key, params.toMap())

  fun languageLabel(target: String): String = labels[target]?.let { it[language] ?: it["en"] } ?: target

  /** The target used until one is picked: Japanese for a Japanese UI, English otherwise. */
  val defaultTarget: String get() = if (language == "ja") "Japanese" else "English"
}
