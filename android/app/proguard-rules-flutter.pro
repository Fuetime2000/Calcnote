# Flutter theming and color preservation rules
-keep class * extends android.graphics.drawable.Drawable { *; }
-keep class * extends android.graphics.drawable.DrawableWrapper { *; }
-keep class * extends android.graphics.drawable.ColorDrawable { *; }
-keep class * extends android.graphics.drawable.StateListDrawable { *; }
-keep class * extends android.graphics.drawable.RippleDrawable { *; }

# Keep Flutter painting and rendering classes
-keep class io.flutter.embedding.engine.renderer.FlutterRenderer { *; }
-keep class io.flutter.embedding.engine.renderer.SurfaceTextureWrapper { *; }
-keep class io.flutter.view.TextureRegistry { *; }
-keep class io.flutter.plugin.platform.PlatformView { *; }
-keep class io.flutter.plugin.platform.PlatformViewFactory { *; }

# Keep Flutter engine classes
-keep class io.flutter.embedding.engine.FlutterEngine { *; }
-keep class io.flutter.embedding.engine.dart.DartExecutor { *; }
-keep class io.flutter.embedding.engine.dart.DartExecutor$DartEntrypoint { *; }

# Keep Flutter plugin classes
-keep class io.flutter.plugin.common.MethodCall { *; }
-keep class io.flutter.plugin.common.MethodChannel { *; }
-keep class io.flutter.plugin.common.MethodChannel$MethodCallHandler { *; }
-keep class io.flutter.plugin.common.PluginRegistry { *; }
-keep class io.flutter.plugin.common.PluginRegistry$ViewDestroyListener { *; }
-keep class io.flutter.plugin.platform.PlatformViewRegistry { *; }

# Keep Flutter view classes
-keep class io.flutter.embedding.android.FlutterView { *; }
-keep class io.flutter.embedding.android.FlutterSurfaceView { *; }
-keep class io.flutter.embedding.android.FlutterTextureView { *; }
-keep class io.flutter.embedding.android.RenderMode { *; }
-keep class io.flutter.embedding.android.TransparencyMode { *; }

# Keep Flutter activity and fragment classes
-keep class io.flutter.embedding.android.FlutterActivity { *; }
-keep class io.flutter.embedding.android.FlutterFragment { *; }
-keep class io.flutter.embedding.android.FlutterFragmentActivity { *; }
-keep class io.flutter.embedding.android.FlutterActivityAndFragmentDelegate { *; }

# Keep Flutter app component classes
-keep class io.flutter.app.FlutterApplication { *; }
-keep class io.flutter.app.FlutterActivity { *; }
-keep class io.flutter.app.FlutterFragmentActivity { *; }
-keep class io.flutter.app.FlutterActivityDelegate { *; }
-keep class io.flutter.app.FlutterActivityEvents { *; }
-keep class io.flutter.app.FlutterApplication { *; }
-keep class io.flutter.app.FlutterApplication$ActivityLifecycleCallbacks { *; }

# Keep Android theme and color resources
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Keep color state lists
-keep class android.content.res.ColorStateList { *; }
-keep class android.content.res.Resources { *; }
-keep class android.content.res.Resources$Theme { *; }

# Keep all color and drawable getters
-keepclassmembers class * {
    *** getColor(...);
    *** getDrawable(...);
    *** getBackground(...);
    *** setBackgroundColor(...);
    *** setBackground(...);
}

# Keep TextFormField and EditText related classes
-keep class android.widget.EditText { *; }
-keep class android.widget.TextView { *; }
-keep class android.text.TextWatcher { *; }
-keep class android.text.Editable { *; }
-keep class android.text.InputFilter { *; }
-keep class android.text.InputType { *; }

# Keep all methods that deal with colors
-keepclassmembers class * {
    android.graphics.Color *;
    int getColor*(...);
    void setColor*(...);
}

# Preserve all theme attributes
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

# Don't optimize or obfuscate theme-related code
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-dontpreverify

# Keep all Flutter Material widgets
-keep class io.flutter.plugins.** { *; }
-keep interface io.flutter.plugins.** { *; }

# Keep all custom Flutter platform views
-keep class * implements io.flutter.plugin.platform.PlatformView { *; }
-keep class * extends io.flutter.plugin.platform.PlatformView { *; }
