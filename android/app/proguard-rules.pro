# App entry point — must not be stripped by R8
-keep class com.prismpegway.pegwaygame.** { *; }

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# audioplayers
-keep class xyz.luan.audioplayers.** { *; }
-dontwarn xyz.luan.audioplayers.**

# webview_flutter
-keep class io.flutter.plugins.webviewflutter.** { *; }
-dontwarn io.flutter.plugins.webviewflutter.**

# shared_preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Keep game assets and model classes
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
