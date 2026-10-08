class ApiConfig {
  ApiConfig._();

  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://notiq.bitmintlab.in',
  );

  static void validate() {
    final uri = Uri.tryParse(baseUrl);
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      throw StateError('Supply a valid API_BASE_URL using --dart-define.');
    }
    const production = bool.fromEnvironment('dart.vm.product');
    if (production && uri.scheme != 'https') {
      throw StateError('Production API_BASE_URL must use HTTPS.');
    }
  }
}
