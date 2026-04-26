# Flutter / Dart obfuscation rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Hive
-keep class * extends com.google.protobuf.GeneratedMessageLite { *; }

# Kotlin coroutines
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}

# Play Core (used by Flutter deferred components — classes may be absent on older devices)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Keep all annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses,EnclosingMethod
