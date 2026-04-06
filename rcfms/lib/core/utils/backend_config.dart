import 'package:shared_preferences/shared_preferences.dart';
import '../constants/supabase_config.dart';

/// Helper to manage configurable backend URL for mobile device access.
/// On physical devices, 127.0.0.1 won't reach the dev machine —
/// users must set their computer's LAN IP here.
class BackendConfig {
  static const _key = 'custom_backend_url';

  /// Get the active backend URL (custom or default).
  static Future<String> getBackendUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getString(_key);
    if (custom != null && custom.isNotEmpty) return custom;
    return SupabaseConfig.backendUrl;
  }

  /// Set a custom backend URL (e.g., http://192.168.x.x:5000/api).
  static Future<void> setBackendUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, url.trim());
  }

  /// Clear the custom URL and revert to default.
  static Future<void> clearBackendUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Get the current custom URL (null if using default).
  static Future<String?> getCustomUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }
}
