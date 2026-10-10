# Flutter ProGuard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase ProGuard Rules
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Cloudinary / HTTP Rules
-keep class com.cloudinary.** { *; }
-dontwarn com.cloudinary.**

# Play Store Core (Fixes R8 missing class errors)
-dontwarn com.google.android.play.core.**
