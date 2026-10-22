package io.github.shigeya_t.langria

import android.content.Context
import android.content.SharedPreferences

/**
 * The app's settings, stored under the web app's localStorage names
 * (`langria-provider` and so on), as the iOS app does in UserDefaults.
 */
object Settings {
  fun prefs(context: Context): SharedPreferences = context.getSharedPreferences("langria", Context.MODE_PRIVATE)
}
