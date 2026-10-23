package io.github.shigeya_t.langria

import android.Manifest
import android.content.pm.PackageManager
import android.net.Uri
import androidx.activity.compose.LocalActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.VolumeUp
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Fingerprint
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.outlined.CameraAlt
import androidx.compose.material.icons.outlined.ContentCopy
import androidx.compose.material.icons.outlined.Image
import androidx.compose.material.icons.outlined.MicNone
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material.icons.outlined.StopCircle
import androidx.compose.material.icons.outlined.SwapHoriz
import androidx.compose.material.icons.outlined.UnfoldMore
import androidx.compose.material3.Button
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilledTonalIconButton
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.onLongClick
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import java.io.File
import java.lang.ref.WeakReference

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ContentScreen(model: AppModel, ads: Ads, onOpenSettings: () -> Unit) {
  val shared = model.shared
  val activity = LocalActivity.current
  val focus = LocalFocusManager.current
  LaunchedEffect(model, activity) { model.activity = WeakReference(activity) }

  Scaffold(
    containerColor = MaterialTheme.colorScheme.background,
    topBar = {
      CenterAlignedTopAppBar(
        title = {
          Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            // Outlined like the web app's brand mark, so the dark half shows on a dark bar.
            Image(painterResource(R.drawable.logo), contentDescription = null, Modifier.size(24.dp).border(1.dp, MaterialTheme.colorScheme.outlineVariant, RoundedCornerShape(6.dp)))
            Text("Langria", fontWeight = FontWeight.ExtraBold, fontSize = 18.sp)
          }
        },
        actions = {
          IconButton(onClick = onOpenSettings) {
            Icon(Icons.Outlined.Settings, shared.t("web.openSettings"), tint = MaterialTheme.colorScheme.onSurfaceVariant)
          }
        },
        colors = TopAppBarDefaults.topAppBarColors(containerColor = MaterialTheme.colorScheme.background),
      )
    },
  ) { padding ->
    Box(Modifier.fillMaxSize().padding(padding).imePadding()) {
      // The panes grow to fill the screen (sharing the height when stacked)
      // and the page scrolls once their text needs more room.
      BoxWithConstraints(Modifier.fillMaxSize()) {
        val wide = maxWidth >= 600.dp
        val banner = if (ads.ready) 70.dp else 0.dp
        val paneHeight = if (wide) (maxHeight - 340.dp - banner).coerceAtLeast(220.dp) else ((maxHeight - 420.dp - banner) / 2).coerceAtLeast(150.dp)
        Column(
          Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp).navigationBarsPadding(),
          verticalArrangement = Arrangement.spacedBy(14.dp),
          horizontalAlignment = Alignment.CenterHorizontally,
        ) {
          Column(Modifier.widthIn(max = 1100.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
            ProviderPicker(model)
            LanguageStrip(model, onSwap = { focus.clearFocus(); model.swap() })
            if (wide) {
              Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                InputPane(model, paneHeight, Modifier.weight(1f))
                OutputPane(model, paneHeight, Modifier.weight(1f), onOpenSettings)
              }
            } else {
              InputPane(model, paneHeight)
              OutputPane(model, paneHeight, Modifier, onOpenSettings)
            }
            Text(
              shared.t("ios.ocrNote"),
              style = MaterialTheme.typography.bodySmall,
              color = MaterialTheme.colorScheme.onSurfaceVariant,
              modifier = Modifier.padding(horizontal = 4.dp),
            )
            // At the end of the page, so it scrolls with the text and never covers it.
            if (ads.ready) BannerAd()
          }
        }
      }
      Toast(model.toast, Modifier.align(Alignment.BottomCenter).navigationBarsPadding().padding(bottom = 24.dp))
    }
  }
}

@Composable
private fun ProviderPicker(model: AppModel) {
  SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
    Provider.entries.forEachIndexed { index, provider ->
      SegmentedButton(
        selected = model.provider == provider,
        onClick = { model.pickProvider(provider) },
        shape = SegmentedButtonDefaults.itemShape(index, Provider.entries.size),
        icon = {},
      ) {
        Text("${provider.orb} ${provider.title}", maxLines = 1, overflow = TextOverflow.Ellipsis)
      }
    }
  }
}

@Composable
private fun LanguageStrip(model: AppModel, onSwap: () -> Unit) {
  val shared = model.shared
  Surface(color = MaterialTheme.colorScheme.surfaceContainer, shape = RoundedCornerShape(14.dp)) {
    Column(Modifier.padding(horizontal = 12.dp, vertical = 6.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
      Row(verticalAlignment = Alignment.CenterVertically) {
        Row(Modifier.weight(1f), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
          Box(Modifier.size(7.dp).clip(CircleShape).background(MaterialTheme.colorScheme.primary))
          Text(shared.t("web.autoDetect"), style = MaterialTheme.typography.labelLarge, maxLines = 1, overflow = TextOverflow.Ellipsis)
        }
        FilledTonalIconButton(onClick = onSwap, enabled = model.result != null, modifier = Modifier.size(36.dp)) {
          Icon(Icons.Outlined.SwapHoriz, shared.t("web.swap"), Modifier.size(20.dp))
        }
        Box(Modifier.weight(1f), contentAlignment = Alignment.CenterEnd) {
          var open by remember { mutableStateOf(false) }
          TextButton(onClick = { open = true }) {
            Text(if (model.target == Shared.CUSTOM_TARGET) shared.t("target.other") else shared.languageLabel(model.target), maxLines = 1, overflow = TextOverflow.Ellipsis)
            Icon(Icons.Outlined.UnfoldMore, null, Modifier.size(16.dp))
          }
          DropdownMenu(open, onDismissRequest = { open = false }) {
            (shared.targets + Shared.CUSTOM_TARGET).forEach { target ->
              MenuItem(if (target == Shared.CUSTOM_TARGET) shared.t("target.other") else shared.languageLabel(target), selected = model.target == target) {
                open = false
                model.pickTarget(target)
              }
            }
          }
        }
      }
      if (model.target == Shared.CUSTOM_TARGET) {
        OutlinedTextField(
          value = model.customTarget,
          onValueChange = model::updateCustomTarget,
          placeholder = { Text(shared.t("target.customPlaceholder")) },
          singleLine = true,
          modifier = Modifier.fillMaxWidth().padding(bottom = 6.dp).semantics { contentDescription = shared.t("target.customLabel") },
        )
      }
    }
  }
}

@Composable
private fun InputPane(model: AppModel, minHeight: Dp, modifier: Modifier = Modifier) {
  val shared = model.shared
  val context = LocalContext.current
  val focus = LocalFocusManager.current
  val photo = remember { File(context.cacheDir, "photos/photo.jpg") }
  val photoUri = remember { FileProvider.getUriForFile(context, "${context.packageName}.photos", photo.also { it.parentFile?.mkdirs() }) }
  val camera = rememberLauncherForActivityResult(ActivityResultContracts.TakePicture()) { taken -> if (taken) model.read(photoUri) }
  val picker = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri: Uri? -> uri?.let(model::read) }
  val microphone = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
    if (granted) model.toggleDictation() else model.dictationDenied()
  }
  val hasCamera = remember { context.packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA_ANY) }

  Card(
    modifier,
    header = {
      Text(shared.t("web.original"), style = MaterialTheme.typography.titleSmall, maxLines = 1)
      ModePicker(model, Modifier.weight(1f, fill = false))
      Spacer(Modifier.weight(1f))
      TextButton(onClick = { model.clear() }, enabled = model.source.isNotEmpty() || model.image != null) {
        Text(shared.t("web.clear"), maxLines = 1)
      }
    },
    content = {
      model.image?.let { image ->
        Box(Modifier.padding(top = 6.dp)) {
          Image(
            image.asImageBitmap(),
            contentDescription = null,
            contentScale = ContentScale.Fit,
            modifier = Modifier.heightIn(max = 160.dp).clip(RoundedCornerShape(10.dp)),
          )
          if (model.recognizing) {
            CircularProgressIndicator(Modifier.align(Alignment.Center).size(32.dp))
          }
          IconButton(onClick = { model.removeImage() }, modifier = Modifier.align(Alignment.TopEnd)) {
            Icon(Icons.Filled.Cancel, shared.t("ios.removeImage"), tint = Color.White, modifier = Modifier.background(Color.Black.copy(alpha = 0.5f), CircleShape))
          }
        }
      }
      BasicTextField(
        value = model.source,
        onValueChange = { model.source = it },
        textStyle = MaterialTheme.typography.bodyLarge.copy(color = MaterialTheme.colorScheme.onSurface, fontSize = 18.sp, lineHeight = 28.sp),
        cursorBrush = SolidColor(MaterialTheme.colorScheme.primary),
        modifier = Modifier.fillMaxWidth().heightIn(min = minHeight - if (model.image != null) 170.dp else 0.dp).padding(vertical = 10.dp),
        decorationBox = { field ->
          Box {
            if (model.source.isEmpty()) Text(shared.t("web.sourcePlaceholder"), style = MaterialTheme.typography.bodyLarge.copy(fontSize = 18.sp), color = MaterialTheme.colorScheme.outline)
            field()
          }
        },
      )
    },
    footer = {
      if (model.listening) {
        Text(shared.t("ios.listening", "lang" to shared.languageLabel(model.dictationLanguage)), color = MaterialTheme.colorScheme.error, maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1f))
      } else {
        Text(model.characterCount, maxLines = 1, modifier = Modifier.weight(1f))
      }
      DictationButton(model) {
        focus.clearFocus()
        if (model.listening || ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED) model.toggleDictation()
        else microphone.launch(Manifest.permission.RECORD_AUDIO)
      }
      if (hasCamera) {
        IconButton(onClick = { focus.clearFocus(); model.openingOtherScreen = true; camera.launch(photoUri) }) {
          Icon(Icons.Outlined.CameraAlt, shared.t("ios.camera"))
        }
      }
      IconButton(onClick = { focus.clearFocus(); model.openingOtherScreen = true; picker.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)) }) {
        Icon(Icons.Outlined.Image, shared.t("ios.photo"))
      }
      IconButton(onClick = { model.copy(model.source) }) {
        Icon(Icons.Outlined.ContentCopy, shared.t("web.copyOriginal"))
      }
    },
  )
}

@Composable
private fun ModePicker(model: AppModel, modifier: Modifier) {
  val shared = model.shared
  var open by remember { mutableStateOf(false) }
  Box(modifier) {
    TextButton(onClick = { open = true }, modifier = Modifier.semantics { contentDescription = shared.t("mode.label"); stateDescription = shared.t("mode.${model.mode.id}") }) {
      Text(shared.t("mode.${model.mode.id}"), maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1f, fill = false))
      Icon(Icons.Outlined.UnfoldMore, null, Modifier.size(16.dp))
    }
    DropdownMenu(open, onDismissRequest = { open = false }) {
      TranslationMode.entries.forEach { mode ->
        MenuItem(shared.t("mode.${mode.id}"), selected = model.mode == mode) { open = false; model.pickMode(mode) }
      }
    }
  }
}

/** The language voice input listens in, shown short ("EN", "Auto · JA"), and the microphone: tap to start or stop, touch and hold to pick the language. */
@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun DictationButton(model: AppModel, onToggle: () -> Unit) {
  val shared = model.shared
  var open by remember { mutableStateOf(false) }
  // "en-US" → "EN"; Chinese keeps its region, which tells the two apart.
  fun code(language: String): String {
    val tag = shared.locales[language] ?: language
    return (if (tag.startsWith("zh")) tag else tag.substringBefore('-')).uppercase()
  }
  Row(verticalAlignment = Alignment.CenterVertically) {
    TextButton(onClick = { open = true }, modifier = Modifier.semantics { contentDescription = shared.t("ios.dictationLanguage"); stateDescription = shared.languageLabel(model.dictationLanguage) }) {
      val code = code(model.dictationLanguage)
      Text(if (model.dictationChoice == AppModel.AUTO_DICTATION) shared.t("ios.dictationAutoShort", "lang" to code) else code, style = MaterialTheme.typography.labelMedium, maxLines = 1)
    }
    Box {
    Box(
      Modifier.size(40.dp).clip(CircleShape)
        .combinedClickable(onClick = onToggle, onLongClick = { open = true })
        .semantics {
          role = Role.Button
          contentDescription = shared.t(if (model.listening) "ios.stopDictation" else "ios.dictate")
          onLongClick(shared.t("ios.dictationLanguage")) { open = true; true }
        },
      contentAlignment = Alignment.Center,
    ) {
      Icon(if (model.listening) Icons.Filled.Mic else Icons.Outlined.MicNone, null, tint = if (model.listening) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.primary)
    }
    DropdownMenu(open, onDismissRequest = { open = false }) {
      Text(shared.t("ios.dictationAutoNote"), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp).widthIn(max = 280.dp))
      MenuItem(shared.t("ios.dictationAuto", "lang" to shared.languageLabel(model.autoDictationLanguage)), selected = model.dictationChoice == AppModel.AUTO_DICTATION) {
        open = false
        model.pickDictation(AppModel.AUTO_DICTATION)
      }
      shared.targets.forEach { target ->
        MenuItem(shared.languageLabel(target), selected = model.dictationChoice == target) { open = false; model.pickDictation(target) }
      }
    }
    }
  }
}

@Composable
private fun OutputPane(model: AppModel, minHeight: Dp, modifier: Modifier, onOpenSettings: () -> Unit) {
  val shared = model.shared
  val activity = LocalActivity.current
  Card(
    modifier,
    header = {
      Text(shared.t("web.translation"), style = MaterialTheme.typography.titleSmall, maxLines = 1)
      Spacer(Modifier.weight(1f))
      Text(
        model.currentModel,
        style = MaterialTheme.typography.labelSmall,
        fontFamily = FontFamily.Monospace,
        color = MaterialTheme.colorScheme.primary,
        maxLines = 1,
        overflow = TextOverflow.Ellipsis,
        modifier = Modifier.padding(start = 8.dp).semantics { contentDescription = "${shared.t("web.modelOf", "name" to model.provider.title)}: ${model.currentModel}" },
      )
    },
    content = {
      Box(Modifier.fillMaxWidth().heightIn(min = minHeight).padding(vertical = 10.dp)) {
        when (val pane = model.pane) {
          Pane.Empty -> Column(Modifier.align(Alignment.Center), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text("✦", fontSize = 22.sp, color = MaterialTheme.colorScheme.outline)
            Text(shared.t("web.empty"), color = MaterialTheme.colorScheme.onSurfaceVariant)
          }
          Pane.Translating -> CircularProgressIndicator(Modifier.align(Alignment.Center).size(32.dp))
          is Pane.Result -> androidx.compose.foundation.text.selection.SelectionContainer {
            Text(pane.text, style = MaterialTheme.typography.bodyLarge.copy(fontSize = 18.sp, lineHeight = 28.sp))
          }
          Pane.NoKey -> Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(shared.t("web.noKey"))
            OutlinedButton(onClick = onOpenSettings) { Text(shared.t("web.openSettings")) }
          }
          Pane.NoTarget -> Text(shared.t("web.enterTarget"))
          Pane.Locked -> Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(shared.t("web.locked"))
            Button(onClick = { activity?.let { model.unlock(it) } }, enabled = !model.unlocking) {
              Icon(Icons.Filled.Fingerprint, null, Modifier.padding(end = 8.dp))
              Text(shared.t("ios.unlockButton", "method" to model.lockMethod))
            }
            if (model.unlockError.isNotEmpty()) Text(model.unlockError, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.error)
          }
          is Pane.Failure -> androidx.compose.foundation.text.selection.SelectionContainer {
            Text(model.message(pane), color = MaterialTheme.colorScheme.error)
          }
        }
      }
    },
    footer = {
      Text(shared.t(model.statusKey), maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1f))
      IconButton(onClick = { model.toggleSpeaking() }, enabled = model.result != null || model.speaking) {
        Icon(if (model.speaking) Icons.Outlined.StopCircle else Icons.AutoMirrored.Filled.VolumeUp, shared.t(if (model.speaking) "ios.stopSpeaking" else "ios.speak"))
      }
      IconButton(onClick = { model.copy(model.result) }, enabled = model.result != null) {
        Icon(Icons.Outlined.ContentCopy, shared.t("web.copyTranslation"))
      }
    },
  )
}

/** A rounded pane with a title row and a footer row, like the web app's panes. */
@Composable
private fun Card(
  modifier: Modifier,
  header: @Composable RowScope.() -> Unit,
  content: @Composable ColumnScope.() -> Unit,
  footer: @Composable RowScope.() -> Unit,
) {
  Surface(modifier, color = MaterialTheme.colorScheme.surfaceContainer, shape = RoundedCornerShape(14.dp)) {
    Column {
      Row(Modifier.fillMaxWidth().heightIn(min = 48.dp).padding(start = 14.dp, end = 4.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp), content = header)
      HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant)
      Column(Modifier.padding(horizontal = 14.dp), content = content)
      HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant)
      androidx.compose.runtime.CompositionLocalProvider(androidx.compose.material3.LocalContentColor provides MaterialTheme.colorScheme.onSurfaceVariant, androidx.compose.material3.LocalTextStyle provides MaterialTheme.typography.bodySmall) {
        Row(Modifier.fillMaxWidth().heightIn(min = 48.dp).padding(start = 14.dp, end = 4.dp), verticalAlignment = Alignment.CenterVertically, content = footer)
      }
    }
  }
}

@Composable
fun MenuItem(text: String, selected: Boolean, onClick: () -> Unit) {
  DropdownMenuItem(
    text = { Text(text) },
    onClick = onClick,
    trailingIcon = { if (selected) Icon(Icons.Filled.Check, null, tint = MaterialTheme.colorScheme.primary) },
  )
}

@Composable
private fun Toast(message: String?, modifier: Modifier) {
  // Keeps the last message while it fades out.
  var shown by remember { mutableStateOf("") }
  if (message != null) shown = message
  AnimatedVisibility(message != null, modifier, enter = fadeIn() + slideInVertically { it }, exit = fadeOut() + slideOutVertically { it }) {
    Surface(color = MaterialTheme.colorScheme.inverseSurface, shape = RoundedCornerShape(50), shadowElevation = 4.dp) {
      Text(shown, style = MaterialTheme.typography.labelLarge, modifier = Modifier.padding(horizontal = 16.dp, vertical = 10.dp))
    }
  }
}
