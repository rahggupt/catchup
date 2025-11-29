import 'package:airbridge_flutter_sdk/airbridge_flutter_sdk.dart';

class AirbridgeConfig {
  // TODO: Replace with your actual app token from Airbridge dashboard
  // Get this from: Dashboard → Settings → App → App Token
  static const String appToken = '1347a69cb593460ea7559e77067d2b0c';
  
  // TODO: Replace with your app name from Airbridge dashboard
  // This should be lowercase (e.g., 'catchup')
  static const String appName = 'catchup';
  
  static Future<void> initialize() async {
    final option = AirbridgeOptionBuilder(
      appName: appName,
      appToken: appToken,
    )
      ..setAutoStartTrackingEnabled(true) // Auto-track app opens
      ..setSessionTimeout(300) // 5 minutes session timeout
      ..setLogLevel(AirbridgeLogLevel.debug) // Change to warning in production
      ..setTrackAirbridgeLinkOnly(false) // Track all deep links
      ..build();
    
    await Airbridge.initialize(option);
    print('✅ Airbridge initialized successfully');
  }
  
  /// Set user identifier after login
  static Future<void> setUserIdentifier(String userId) async {
    await Airbridge.setUserId(userId);
    print('✅ Airbridge user set: $userId');
  }
  
  /// Set user email (optional)
  static Future<void> setUserEmail(String email) async {
    await Airbridge.setUserEmail(email);
    print('✅ Airbridge user email set: $email');
  }
  
  /// Clear user data on logout
  static Future<void> clearUser() async {
    await Airbridge.clearUser();
    print('✅ Airbridge user cleared');
  }
}

