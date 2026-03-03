# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.editing.** { *; }

# ML Kit Text Recognition
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Desugaring
-dontwarn java.lang.invoke.*
-dontwarn **.File

# Play Core & Deferred Components
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Awesome Notifications
-keep class me.carda.awesome_notifications.** { *; }
-dontwarn me.carda.awesome_notifications.**

# Hive
-keep class com.hivedb.** { *; }
-keep class com.google.common.hash.** { *; }
-keepnames class * extends io.hive.TypeAdapter
-keep class * extends io.hive.TypeAdapter { *; }
-keep interface io.hive.TypeAdapter { *; }
-dontwarn com.google.common.hash.**
