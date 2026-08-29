# Keep Supabase / Gotrue / Realtime models from being stripped since they
# rely on reflection-free but still benefit from conservative keep rules.
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Flutter's Play Store deferred-components support references the Play Core
# split-install API optionally at runtime. This app doesn't use dynamic
# feature modules / deferred components, and the Play Core split-install
# artifact isn't on the classpath, so R8 can't resolve these classes during
# minification. Suppress rather than keep, since they're never actually
# exercised. See: https://github.com/flutter/flutter/issues/109402
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task
