# TensorFlow Lite — keep core and GPU delegate classes; the GPU delegate
# library is referenced reflectively even when it isn't bundled, so R8 needs
# to be told not to fail on the missing references.
-keep class org.tensorflow.lite.** { *; }
-keep interface org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**

-keep class org.tensorflow.lite.gpu.** { *; }
-keep interface org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.gpu.**

# Google Play Core (referenced by Flutter's deferred components even when unused)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
