class AppConstants {
  // Platform fee in ZAR cents (R5.00)
  static const int platformFeeCents = 500;

  // Pagination
  static const int defaultPageSize = 20;
  static const int dataSaverPageSize = 10;

  // Image
  static const int maxImageWidth = 600;
  static const int imageQuality = 70;
  static const int maxImageSizeBytes = 2 * 1024 * 1024; // 2MB

  // Cache
  static const int firestoreCacheSizeMB = 50;

  // Rate limits (client-side enforcement as UX guard)
  static const int maxOrdersPerMinute = 10;

  // Timeouts
  static const Duration networkTimeout = Duration(seconds: 15);

  // Developer email
  static const String developerEmail = 'tshikotaeats@nortsideconnect.co.za';
}
