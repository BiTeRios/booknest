# L6: правила R8 для release-сборки.
#
# shared_preferences_android 2.5 вызывает свой Kotlin-код из Dart через JNI
# (мост Pigeon + jnigen, пакет jni). JNI находит классы и методы по СТРОКОВЫМ
# именам и полным сигнатурам, а R8 в release вырезает «неиспользуемое» и
# переименовывает остальное. В debug R8 не работает — там всё было хорошо;
# в release приложение висело на splash:
#   NoSuchMethodError  SharedPreferencesApiRegistrar.getAll(...)
#   ClassNotFoundException  kotlin/coroutines/intrinsics/CoroutineSingletons
# Собственные правила пакета jni сохраняют только com.github.dart_lang.jni.

# Мост плагина: методы, которые Dart вызывает по имени.
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Классы Kotlin stdlib, которые пакет jni ищет по имени (lib/**.dart):
# suspend-функции получают Continuation и отвечают COROUTINE_SUSPENDED
# или kotlin.Result.
-keep class kotlin.Unit { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$Failure { *; }
-keep class kotlin.coroutines.Continuation { *; }
-keep class kotlin.coroutines.intrinsics.** { *; }
-keep class kotlin.jvm.internal.DefaultConstructorMarker
