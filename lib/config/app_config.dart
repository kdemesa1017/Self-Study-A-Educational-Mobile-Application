/// Central configuration for the app.
/// Keep API keys here — do NOT commit to public repos.
class AppConfig {
  AppConfig._();

  /// Google Gemini API key (free tier).
  static const String geminiApiKey = "GEMINI_API_KEY";

  /// Primary model for AI quiz generation.
  static const String geminiModel = 'gemini-flash-latest';

  /// Maximum file size the AI generator will accept (20 MB).
  static const int maxUploadBytes = 20 * 1024 * 1024;
}
