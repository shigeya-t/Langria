package io.github.shigeya_t.langria

import android.app.Application
import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.core.content.edit
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.launch
import java.lang.ref.WeakReference

/** Holds the app's state across configuration changes (rotation, a resized window). */
class AppHolder(app: Application) : AndroidViewModel(app) {
  private val prefs = Settings.prefs(app)
  /** Null until the shared scripts are read, which takes a moment on the first launch. */
  var model by mutableStateOf<AppModel?>(null)
    private set
  val ads = Ads()
  /** "light", "dark", or "" to follow the system, under the web app's name. */
  var theme by mutableStateOf(prefs.getString("langria-theme", null).orEmpty())
    private set
  /** Text shared from another app, put in once the model is ready. */
  private var incoming: String? = null

  init {
    viewModelScope.launch {
      val shared = Shared.load(app)
      model = AppModel(app, shared, viewModelScope).also { model -> incoming?.let { model.source = it } }
      incoming = null
    }
  }

  fun pickTheme(next: String) {
    theme = next
    prefs.edit { putString("langria-theme", next) }
  }

  fun receive(text: String) {
    val model = model
    if (model == null) incoming = text else { model.removeImage(); model.source = text }
  }

  override fun onCleared() { model?.close() }
}

class MainActivity : ComponentActivity() {
  private val holder: AppHolder by viewModels()

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    if (savedInstanceState == null) receive(intent)
    setContent {
      val dark = when (holder.theme) { "light" -> false; "dark" -> true; else -> isSystemInDarkTheme() }
      LaunchedEffect(dark) {
        val style = if (dark) SystemBarStyle.dark(android.graphics.Color.TRANSPARENT) else SystemBarStyle.light(android.graphics.Color.TRANSPARENT, android.graphics.Color.TRANSPARENT)
        enableEdgeToEdge(style, style)
      }
      LangriaTheme(dark) {
        var showSettings by rememberSaveable { mutableStateOf(false) }
        Surface(Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) {
          val model = holder.model
          if (model == null) {
            Box(Modifier.fillMaxSize())
          } else if (showSettings) {
            SettingsScreen(model, holder, onClose = { showSettings = false })
          } else {
            ContentScreen(model, holder.ads, onOpenSettings = { showSettings = true })
          }
        }
      }
    }
  }

  override fun onNewIntent(intent: Intent) {
    super.onNewIntent(intent)
    receive(intent)
  }

  override fun onStart() {
    super.onStart()
    lifecycleScope.launch { holder.ads.gatherConsent(this@MainActivity) }
  }

  override fun onResume() {
    super.onResume()
    holder.model?.let { it.activity = WeakReference(this); it.openingOtherScreen = false }
  }

  override fun onStop() {
    super.onStop()
    if (!isChangingConfigurations) holder.model?.didEnterBackground()
  }

  /** Text from the share sheet, or from "Langria" in another app's text selection menu. */
  private fun receive(intent: Intent?) {
    val text = when (intent?.action) {
      Intent.ACTION_SEND -> intent.getStringExtra(Intent.EXTRA_TEXT)
      Intent.ACTION_PROCESS_TEXT -> intent.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)?.toString()
      else -> null
    }
    if (!text.isNullOrBlank()) holder.receive(text.trim())
  }
}
