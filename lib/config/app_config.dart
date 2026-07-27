/// Central configuration for the app.
/// Keep API keys here — do NOT commit to public repos.
class AppConfig {
  AppConfig._();

  /// Google Gemini API key (free tier).
  /// Get yours at: https://aistudio.google.com/app/apikey
  /// The key must start with 'AIza...' — do NOT use OAuth tokens.
  static const String geminiApiKey = "YOUR_GEMINI_API_KEY";

  /// gemini-1.5-flash — fast, free tier, great for document analysis.
  static const String geminiModel = 'gemini-1.5-flash';

  /// Maximum file size the AI generator will accept (20 MB).
  static const int maxUploadBytes = 20 * 1024 * 1024;
}

