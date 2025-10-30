# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# ML Kit Text Recognition - Keep all classes
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.vision.** { *; }
-keep class com.google.mlkit.common.** { *; }

# Google Play Core - Keep all classes
-keep class com.google.android.play.core.** { *; }

# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep all classes with 'google' in the name
-keep class **google** { *; }

# Keep all classes with 'mlkit' in the name
-keep class **mlkit** { *; }

# Keep all classes with 'play' in the name
-keep class **play** { *; }
