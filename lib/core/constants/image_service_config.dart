class ImageServiceConfig {
  ImageServiceConfig._();

  static const String baseUrl = String.fromEnvironment('IMAGE_SERVICE_URL');

  static bool get isConfigured => baseUrl.isNotEmpty;
}
