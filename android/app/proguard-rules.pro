# Flutter standard ProGuard rules
# These keep-rules prevent R8 from stripping classes that Flutter
# accesses via reflection at runtime.

# Keep Flutter engine entrypoints
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Google Sign-In (uses reflection for account selection)
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Keep SQLite / Drift native bridge
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }

# Keep Supabase / Ktor networking internals
-dontwarn io.ktor.**
-keep class io.ktor.** { *; }

# Keep annotations used by json_serializable / freezed
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Prevent stripping of Kotlin metadata (required for Kotlin reflection)
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings { <fields>; }

# Suppress warnings for unused platform-specific stubs
-dontwarn java.lang.instrument.ClassFileTransformer
-dontwarn sun.misc.SignalHandler

# Flutter Play Core deferred components (not used by this app).
# The blanket `-keep class io.flutter.** { *; }` rule above retains
# PlayStoreDeferredComponentManager, whose Play Core references aren't on
# the classpath (we don't ship Play Feature Delivery). R8 treats those
# missing classes as fatal during :app:minifyReleaseWithR8 — these rules
# tell it they're intentionally absent.
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
