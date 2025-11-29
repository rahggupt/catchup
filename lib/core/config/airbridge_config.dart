import 'package:airbridge_flutter_sdk/airbridge_flutter_sdk.dart';

class AirbridgeConfig {
  // App token from Airbridge dashboard
  // Get this from: Dashboard → Settings → App → App Token
  static const String appToken = '1347a69cb593460ea7559e77067d2b0c';
  
  // App name from Airbridge dashboard (lowercase)
  static const String appName = 'catchup';
  
  /// Initialize Airbridge - just prints success message
  /// Note: Actual initialization happens in native Android code (build.gradle)
  static Future<void> initialize() async {
    print('✅ Airbridge will be initialized through native Android code');
    print('   Make sure android/app/build.gradle has the correct configuration');
  }
  
  /// Set user identifier after login
  static void setUserIdentifier(String userId) {
    try {
      Airbridge.setUserID(userId);
      print('✅ Airbridge user ID set: $userId');
    } catch (e) {
      print('⚠️ Airbridge setUserID error: $e');
    }
  }
  
  /// Set user email (optional)
  static void setUserEmail(String email) {
    try {
      Airbridge.setUserEmail(email);
      print('✅ Airbridge user email set: $email');
    } catch (e) {
      print('⚠️ Airbridge setUserEmail error: $e');
    }
  }
  
  /// Clear user data on logout
  static void clearUser() {
    try {
      Airbridge.clearUser();
      print('✅ Airbridge user cleared');
    } catch (e) {
      print('⚠️ Airbridge clearUser error: $e');
    }
  }
}


