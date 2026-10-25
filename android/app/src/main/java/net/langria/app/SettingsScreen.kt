package net.langria.app

import androidx.activity.compose.BackHandler
import androidx.activity.compose.LocalActivity
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.outlined.LockOpen
import androidx.compose.material3.Button
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.ExperimentalMaterial3Api
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
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.AlertDialog
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(model: AppModel, holder: AppHolder, onClose: () -> Unit) {
  val shared = model.shared
  val activity = LocalActivity.current
  val context = LocalContext.current
  val scope = rememberCoroutineScope()
  var editing by rememberSaveable { mutableStateOf(model.provider) }
  var key by rememberSaveable { mutableStateOf("") }
  var modelName by rememberSaveable { mutableStateOf("") }
  var showKey by rememberSaveable { mutableStateOf(false) }
  var error by remember { mutableStateOf("") }
  // The key and model as stored, to tell whether the fields were changed.
  var savedKey by remember { mutableStateOf("") }
  var savedModel by remember { mutableStateOf("") }
  var justSaved by remember { mutableStateOf(false) }
  // Set while asking whether to drop unsaved changes: the provider to switch
  // to, or one holding null when closing the settings.
  var leaving by remember { mutableStateOf<Leaving?>(null) }
  // The service (and whether the keys were readable) the fields were filled
  // for, so that after a rotation they keep what was typed.
  var filledFor by rememberSaveable { mutableStateOf("") }

  fun fill() {
    savedKey = model.keys?.get(editing.id).orEmpty()
    savedModel = model.model(editing)
    key = savedKey
    modelName = savedModel
    error = ""
  }

  LaunchedEffect(editing, model.keys) {
    val now = "${editing.id}:${model.keys != null}"
    if (filledFor == now) {
      savedKey = model.keys?.get(editing.id).orEmpty()
      savedModel = model.model(editing)
    } else {
      fill()
      filledFor = now
    }
  }

  val trimmedKey = key.trim()
  // A blank model field means the default model, as when saving.
  val effectiveModel = modelName.trim().ifEmpty { editing.defaultModel }
  val hasChanges = (model.keys != null && trimmedKey != savedKey) || effectiveModel != savedModel

  suspend fun save(): Boolean = try {
    model.save(trimmedKey, modelName, editing)
    fill()
    justSaved = true
    true
  } catch (failure: Exception) {
    error = model.describe(failure)
    false
  }

  fun leave(saving: Boolean) {
    val target = leaving ?: return
    leaving = null
    scope.launch {
      if (saving && !save()) return@launch
      if (target.provider != null) { editing = target.provider; justSaved = false } else onClose()
    }
  }

  BackHandler { if (hasChanges) leaving = Leaving(null) else onClose() }

  Scaffold(
    containerColor = MaterialTheme.colorScheme.background,
    topBar = {
      TopAppBar(
        title = { Text(shared.t("settings.title")) },
        navigationIcon = {
          IconButton(onClick = { if (hasChanges) leaving = Leaving(null) else onClose() }) {
            Icon(Icons.AutoMirrored.Filled.ArrowBack, shared.t("ios.done"))
          }
        },
        colors = TopAppBarDefaults.topAppBarColors(containerColor = MaterialTheme.colorScheme.background),
      )
    },
  ) { padding ->
    Column(
      Modifier.fillMaxSize().padding(padding).imePadding().verticalScroll(rememberScrollState()).padding(16.dp).navigationBarsPadding(),
      horizontalAlignment = Alignment.CenterHorizontally,
    ) {
      Column(Modifier.widthIn(max = 640.dp).fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(20.dp)) {
        Section("${shared.t("settings.apiKey")} · ${editing.title}", shared.t("android.settingsDescription")) {
          SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
            Provider.entries.forEachIndexed { index, provider ->
              SegmentedButton(
                selected = editing == provider,
                onClick = { if (provider != editing) { if (hasChanges) leaving = Leaving(provider) else { editing = provider; justSaved = false } } },
                shape = SegmentedButtonDefaults.itemShape(index, Provider.entries.size),
                icon = {},
              ) { Text(provider.title, maxLines = 1) }
            }
          }
          OutlinedTextField(
            value = key,
            onValueChange = { key = it; justSaved = false },
            enabled = model.keys != null,
            label = { Text(shared.t("settings.apiKey")) },
            placeholder = { Text(shared.t(if (model.keys == null) "settings.lockedPlaceholder" else "settings.keyPlaceholder")) },
            singleLine = true,
            textStyle = TextStyle(fontFamily = FontFamily.Monospace),
            visualTransformation = if (showKey) VisualTransformation.None else PasswordVisualTransformation(),
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password, autoCorrectEnabled = false),
            trailingIcon = {
              TextButton(onClick = { showKey = !showKey }, enabled = model.keys != null) { Text(shared.t(if (showKey) "settings.hide" else "settings.show")) }
            },
            modifier = Modifier.fillMaxWidth().semantics { contentDescription = "${shared.t("settings.apiKey")} ${editing.title}" },
          )
          OutlinedTextField(
            value = modelName,
            onValueChange = { modelName = it; justSaved = false },
            label = { Text(shared.t("settings.model")) },
            placeholder = { Text(editing.defaultModel) },
            singleLine = true,
            textStyle = TextStyle(fontFamily = FontFamily.Monospace),
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Uri, autoCorrectEnabled = false),
            modifier = Modifier.fillMaxWidth(),
          )
          Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Button(onClick = { scope.launch { save() } }, enabled = hasChanges) { Text(shared.t("settings.save")) }
            AnimatedVisibility(justSaved, enter = fadeIn(), exit = fadeOut()) {
              Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Icon(Icons.Filled.CheckCircle, null, Modifier.size(16.dp), tint = MaterialTheme.colorScheme.primary)
                Text(shared.t("web.savedProvider", "name" to editing.title), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
              }
            }
          }
        }

        Section(shared.t("ios.lockTitle"), shared.t("android.lockNote", "method" to model.lockMethod)) {
          if (model.keys == null) {
            OutlinedButton(onClick = { activity?.let { model.unlock(it) } }, enabled = !model.unlocking) {
              Icon(Icons.Outlined.LockOpen, null, Modifier.padding(end = 8.dp))
              Text(shared.t("vault.unlock"))
            }
          }
          Row(verticalAlignment = Alignment.CenterVertically) {
            Text(shared.t("ios.lockToggle", "method" to model.lockMethod), Modifier.weight(1f))
            Switch(
              checked = model.locked,
              onCheckedChange = { on -> error = ""; scope.launch { try { model.setLock(on) } catch (failure: Exception) { error = model.describe(failure) } } },
              enabled = model.keys != null,
            )
          }
          if (error.isNotEmpty()) Text(error, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.error)
          if (model.unlockError.isNotEmpty()) Text(model.unlockError, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.error)
        }

        Section(null, null) {
          Choice(
            shared.t("ios.displayLanguage"),
            listOf("" to shared.t("ios.system"), "en" to "English", "ja" to "日本語"),
            shared.choice.orEmpty(),
          ) { shared.choose(it.ifEmpty { null }); model.uiLanguageChanged() }
          Choice(
            shared.t("ios.appearance"),
            listOf("" to shared.t("ios.system"), "light" to shared.t("ios.light"), "dark" to shared.t("ios.dark")),
            holder.theme,
            holder::pickTheme,
          )
        }

        Section(null, null) {
          Text(shared.t("web.securityNote"), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
          val uri = LocalUriHandler.current
          TextButton(onClick = { uri.openUri("https://github.com/shigeya-t/Langria") }) { Text(shared.t("settings.repo")) }
          if (holder.ads.privacyOptionsRequired) {
            TextButton(onClick = { activity?.let { holder.ads.showPrivacyOptions(it) } }) { Text(shared.t("ios.adPrivacy")) }
          }
          Row {
            Text(shared.t("ios.version"), Modifier.weight(1f))
            val version = remember { context.packageManager.getPackageInfo(context.packageName, 0).versionName.orEmpty() }
            Text(if (shared.commit.isEmpty()) version else "$version (${shared.commit})", color = MaterialTheme.colorScheme.onSurfaceVariant)
          }
        }
      }
    }
  }

  if (leaving != null) {
    AlertDialog(
      onDismissRequest = { leaving = null },
      title = { Text(shared.t("ios.unsavedTitle")) },
      text = { Text(shared.t("ios.unsavedMessage", "name" to editing.title)) },
      confirmButton = {
        Row {
          TextButton(onClick = { leave(saving = false) }) { Text(shared.t("ios.discard"), color = MaterialTheme.colorScheme.error) }
          TextButton(onClick = { leave(saving = true) }) { Text(shared.t("settings.save")) }
        }
      },
      dismissButton = { TextButton(onClick = { leaving = null }) { Text(shared.t("vault.cancel")) } },
    )
  }
}

/** Where to go once the unsaved-changes question is answered: another service, or out of the settings. */
private data class Leaving(val provider: Provider?)

@Composable
private fun Section(title: String?, footer: String?, content: @Composable ColumnScope.() -> Unit) {
  Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
    title?.let { Text(it, style = MaterialTheme.typography.titleSmall, color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.padding(horizontal = 4.dp)) }
    Surface(color = MaterialTheme.colorScheme.surfaceContainer, shape = RoundedCornerShape(14.dp)) {
      Column(Modifier.fillMaxWidth().padding(14.dp), verticalArrangement = Arrangement.spacedBy(12.dp), content = content)
    }
    footer?.let { Text(it, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.padding(horizontal = 4.dp)) }
  }
}

/** A row with a menu of choices, like a menu-style picker. */
@Composable
private fun Choice(label: String, options: List<Pair<String, String>>, selected: String, onPick: (String) -> Unit) {
  var open by remember { mutableStateOf(false) }
  Row(Modifier.fillMaxWidth().heightIn(min = 40.dp).clickable { open = true }, verticalAlignment = Alignment.CenterVertically) {
    Text(label, Modifier.weight(1f))
    Box {
      Text(options.firstOrNull { it.first == selected }?.second.orEmpty(), color = MaterialTheme.colorScheme.primary)
      DropdownMenu(open, onDismissRequest = { open = false }) {
        options.forEach { (value, title) -> MenuItem(title, selected = value == selected) { open = false; onPick(value) } }
      }
    }
  }
}
