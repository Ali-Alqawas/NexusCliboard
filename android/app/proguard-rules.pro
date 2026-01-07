# NexusClip ProGuard Rules
# قواعد ProGuard لتطبيق NexusClip

# Flutter-specific rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Play Core library - Required for Flutter deferred components
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

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep accessibility service
-keep class com.nexusclip.clip.ClipboardAccessibilityService { *; }
-keep class com.nexusclip.clip.NexusClipService { *; }

# Keep method channel handlers
-keep class com.nexusclip.clip.MainActivity { *; }
-keep class com.nexusclip.clip.OverlayActivity { *; }
-keep class com.nexusclip.clip.BootReceiver { *; }

# Hive database
-keep class * extends com.google.crypto.tink.** { *; }
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Encryption
-keep class javax.crypto.** { *; }
-keep class java.security.** { *; }

# Keep R classes
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
