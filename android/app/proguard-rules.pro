# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }

# MediaPipe
-keep class com.google.mediapipe.** { *; }
-dontwarn com.google.mediapipe.**

# AutoValue / javax
-dontwarn javax.lang.model.**
-dontwarn autovalue.shaded.**
-dontwarn com.google.auto.value.**

# Camera
-keep class androidx.camera.** { *; }
