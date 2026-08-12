import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  static const String _apiUrlKey = 'app_api_url';
  static const String _webUrlKey = 'app_web_url';

  // Default: use quizfreely.org public backend
  static const String defaultApiUrl = 'https://quizfreely.org';
  static const String defaultWebUrl = 'https://quizfreely.org';

  static final AppSettings _instance = AppSettings._internal();
  factory AppSettings() => _instance;
  AppSettings._internal();

  // Cached values
  String _apiUrl = defaultApiUrl;
  String _webUrl = defaultWebUrl;
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _apiUrl = prefs.getString(_apiUrlKey) ?? defaultApiUrl;
    _webUrl = prefs.getString(_webUrlKey) ?? defaultWebUrl;
    _loaded = true;
  }

  String get apiUrl => _apiUrl;
  String get webUrl => _webUrl;

  // e.g. https://my-quizfreely.onrender.com
  Future<void> setApiUrl(String url) async {
    final clean = url.trim().replaceAll(RegExp(r'/$'), '');
    _apiUrl = clean;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiUrlKey, clean);
  }

  Future<void> setWebUrl(String url) async {
    final clean = url.trim().replaceAll(RegExp(r'/$'), '');
    _webUrl = clean;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_webUrlKey, clean);
  }

  Future<void> resetToDefaults() async {
    _apiUrl = defaultApiUrl;
    _webUrl = defaultWebUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiUrlKey);
    await prefs.remove(_webUrlKey);
  }
}
