# Airbridge SDK
-keep class co.ab180.airbridge.** { *; }
-dontwarn co.ab180.airbridge.**

# Firebase Messaging (required by Airbridge for uninstall tracking)
-keep class com.google.firebase.messaging.** { *; }
-dontwarn com.google.firebase.messaging.**

# Keep Airbridge uninstall tracking methods
-keepclassmembers class co.ab180.airbridge.Airbridge {
    public static boolean isUninstallTrackingNotification(...);
}

