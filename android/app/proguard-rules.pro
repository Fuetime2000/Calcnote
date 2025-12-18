# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Flutter framework classes related to theming and colors
-keep class * extends flutter.painting.Color { *; }
-keep class * extends flutter.material.ThemeData { *; }
-keep class * extends flutter.material.ColorScheme { *; }
-keep class * extends flutter.painting.BoxDecoration { *; }
-keep class * extends flutter.painting.BoxShadow { *; }

# Keep all Flutter Material and Cupertino widgets
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.android.** { *; }
-keep class io.flutter.embedding.engine.** { *; }

# Preserve all widget constructors and methods
-keepclassmembers class * extends io.flutter.plugin.common.MethodChannel {
    <methods>;
}

# Keep all theme and color related classes
-keep class ** { 
    *** getColorScheme(...);
    *** getTheme(...);
    *** getBackgroundColor(...);
    *** getSurfaceColor(...);
}

# Don't obfuscate Flutter framework
-dontwarn io.flutter.**
-dontwarn androidx.**

# Keep Material Design components
-keep class com.google.android.material.** { *; }
-dontwarn com.google.android.material.**

# Keep AndroidX
-keep class androidx.** { *; }
-keep interface androidx.** { *; }

# Preserve all View subclasses
-keep public class * extends android.view.View {
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
    public <init>(android.content.Context, android.util.AttributeSet, int);
    public void set*(...);
}

# Keep custom views
-keepclasseswithmembers class * {
    public <init>(android.content.Context, android.util.AttributeSet);
}

-keepclasseswithmembers class * {
    public <init>(android.content.Context, android.util.AttributeSet, int);
}

# Play Core
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.ktx.** { *; }
-keep class com.google.android.play.core.common.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Flutter Deferred Components (simplified)
-keep class io.flutter.embedding.engine.deferredcomponents.PlayStoreDeferredComponentManager { *; }
-keep class io.flutter.embedding.engine.loader.FlutterLoader { *; }

# Hive
-keep class hive.** { *; }
-keep class * extends hive.HiveObject { *; }
-keep class * implements hive.HiveObjectMixin { *; }
-keepclassmembers class * extends hive.HiveObject {
    <fields>;
}
-keepclassmembers class * implements hive.HiveObjectMixin {
    <fields>;
}

# Keep all model classes with Hive annotations
-keep @hive.HiveType class * { *; }
-keep @hive.HiveField class * { *; }
-keepclassmembers class * {
    @hive.HiveField *;
}

# Keep NoteModel and related classes
-keep class com.example.calcnote.** { *; }
-keep class calcnote.** { *; }

# Keep all model classes
-keep class **.models.** { *; }
-keep class **.providers.** { *; }

# Preserve annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Preserve line numbers for debugging
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Flutter Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# PDF related
-keep class com.github.barteksc.pdfviewer.** { *; }
-keep class com.syncfusion.** { *; }

# Bluetooth
-keep class com.boskokg.flutter_blue_plus.** { *; }

# Text editing and controllers
-keep class android.widget.EditText { *; }
-keep class android.text.** { *; }

# Preserve all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Play Core
-keep class com.google.android.play.core.install.InstallStateUpdatedListener { *; }
-keep class com.google.android.play.core.install.InstallState { *; }
-keep class com.google.android.play.core.install.InstallException { *; }
-keep class com.google.android.play.core.install.model.InstallStatus { *; }
-keep class com.google.android.play.core.install.model.InstallErrorCode { *; }
-keep class com.google.android.play.core.install.model.AppUpdateType { *; }
-keep class com.google.android.play.core.install.model.UpdateAvailability { *; }
-keep class com.google.android.play.core.install.model.ActivityResult { *; }
-keep class com.google.android.play.core.install.model.InstallErrorCode { *; }

# For Kotlin coroutines support
-keep class kotlinx.coroutines.** { *; }

# Keep all serialization methods
-keepclassmembers class * {
    *** toMap();
    *** fromMap(***);
    *** toJson();
    *** fromJson(***);
}

# Gson (if used)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Prevent obfuscation of enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepnames class * implements java.io.Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Math expressions
-keep class math_expressions.** { *; }

# URL Launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# Share Plus
-keep class dev.fluttercommunity.plus.share.** { *; }

# Path Provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# File Picker
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# Image Picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# Permission Handler
-keep class com.baseflow.permissionhandler.** { *; }

# Local Auth
-keep class io.flutter.plugins.localauth.** { *; }

# Markdown
-keep class markdown.** { *; }

# Flutter Color Picker
-keep class com.mchome.flutter_colorpicker.** { *; }

# Image Picker (already included but adding for completeness)
-keep class io.flutter.plugins.imagepicker.** { *; }

# CRITICAL: Prevent any optimization of theme and color code
-keep,allowobfuscation,allowshrinking class * {
    *** scaffoldBackgroundColor;
    *** backgroundColor;
    *** surface;
    *** colorScheme;
    *** brightness;
}

# Keep all getter methods for colors and themes
-keepclassmembers class * {
    *** get*Color(...);
    *** get*Theme(...);
    *** get*Scheme(...);
    *** getBrightness(...);
}

# Prevent optimization of Color class
-keep class * extends java.lang.Number { *; }
-keepclassmembers class * {
    int color;
    long value;
}

# Keep all theme-related fields
-keepclassmembers class * {
    *** scaffoldBackgroundColor;
    *** backgroundColor;
    *** primaryColor;
    *** accentColor;
    *** surface;
    *** background;
}
