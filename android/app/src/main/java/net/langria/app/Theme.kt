package net.langria.app

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

// The web app's colors (styles.css): the lime accent, dark ink on light paper
// and the reverse.
private val light = lightColorScheme(
  primary = Color(0xFF5F8A1A),
  onPrimary = Color.White,
  primaryContainer = Color(0xFFDDEFC0),
  onPrimaryContainer = Color(0xFF17200B),
  secondaryContainer = Color(0xFFE6E9E1),
  onSecondaryContainer = Color(0xFF161A17),
  background = Color(0xFFF5F6F2),
  onBackground = Color(0xFF161A17),
  surface = Color(0xFFF5F6F2),
  onSurface = Color(0xFF161A17),
  onSurfaceVariant = Color(0xFF69726C),
  surfaceContainer = Color(0xFFFFFFFF),
  surfaceContainerHigh = Color(0xFFEEF1EA),
  surfaceContainerHighest = Color(0xFFE6E9E1),
  outline = Color(0xFF8A938C),
  outlineVariant = Color(0xFFDDE2D9),
  error = Color(0xFFC62828),
  inverseSurface = Color(0xFF2A3030),
  inverseOnSurface = Color(0xFFEDF0EA),
)

private val dark = darkColorScheme(
  primary = Color(0xFFC8F859),
  onPrimary = Color(0xFF17200B),
  primaryContainer = Color(0xFF3A4A1C),
  onPrimaryContainer = Color(0xFFE4FBB0),
  secondaryContainer = Color(0xFF2A3030),
  onSecondaryContainer = Color(0xFFEDF0EA),
  background = Color(0xFF111516),
  onBackground = Color(0xFFEDF0EA),
  surface = Color(0xFF111516),
  onSurface = Color(0xFFEDF0EA),
  onSurfaceVariant = Color(0xFF8F9894),
  surfaceContainer = Color(0xFF171C1D),
  surfaceContainerHigh = Color(0xFF1C2223),
  surfaceContainerHighest = Color(0xFF202627),
  outline = Color(0xFF66706D),
  outlineVariant = Color(0xFF2A3233),
  error = Color(0xFFFF8F8F),
  inverseSurface = Color(0xFFE8EEE6),
  inverseOnSurface = Color(0xFF172017),
)

@Composable
fun LangriaTheme(dark: Boolean, content: @Composable () -> Unit) {
  MaterialTheme(colorScheme = if (dark) net.langria.app.dark else light, content = content)
}
