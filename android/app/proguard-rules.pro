# ML Kit's text recognition fails in a minified build: R8 (full mode) breaks
# its internal components, and every photo reads as an error. Keep them whole.
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_** { *; }
