/// API constants for external services.
///
/// Provide [unsplashAccessKey] with --dart-define:
/// UNSPLASH_ACCESS_KEY
class ApiConstants {
  static const String unsplashAccessKey = String.fromEnvironment(
    'UNSPLASH_ACCESS_KEY',
  );
  static const String unsplashBaseUrl = 'https://api.unsplash.com';

  static bool get hasUnsplashKey => unsplashAccessKey.trim().isNotEmpty;
}
