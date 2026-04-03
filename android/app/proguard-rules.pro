# Flutter 基础规则
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.android.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.embedding.engine.plugins.** { *; }

# Hive 数据库
-keep class * extends com.tekartik.sqflite.** { *; }
-keep class * extends app.simple.inure.database.instances.** { *; }

# Provider 状态管理
-keep class * extends provider.** { *; }

# 反射类
-keepattributes Signature
-keepattributes *Annotation*
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-keep class kotlin.coroutines.** { *; }

# v2ray 相关
-keep class com.v2ray.** { *; }
-keep class com.github.shadowsocks.** { *; }
-keep class com.xray.** { *; }

# JSON 序列化
-keep class * implements com.google.gson.TypeAdapter
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.squareup.moshi.JsonAdapter
-keep class * extends com.squareup.moshi.JsonAdapter

# 应用类
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider
-keep public class * extends android.app.Application

# View 绑定
-keepclasseswithmembernames class * {
    public <init>(android.content.Context, android.util.AttributeSet);
}
-keepclasseswithmembernames class * {
    public <init>(android.content.Context, android.util.AttributeSet, int);
}

# 保留所有 native 方法
-keepclasseswithmembers class * {
    native <methods>;
}

# 保留 v2ray 核心库
-keep class libv2ray.** { *; }
-dontwarn libv2ray.**

# 日志类
-keep class timber.log.** { *; }
-keep class org.slf4j.** { *; }

# HTTP 客户端
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }
-dontwarn okhttp3.**
-dontwarn retrofit2.**

# 通用规则
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# 不要警告缺失类
-dontwarn sun.misc.**
-dontnote sun.misc.**