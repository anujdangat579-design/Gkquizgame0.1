class AppConstants {
  AppConstants._();

  // Shown in the OS task switcher / window title and anywhere else the
  // app needs to refer to itself by name.
  static const String appName = 'Competition Admin';

  // Secure-storage key for the admin bearer token. Centralized here so
  // TokenStorage and anything that needs to invalidate/migrate the stored
  // token (e.g. a future "log out everywhere" feature) agree on the key.
  static const String authTokenStorageKey = 'admin_token';

  // Default pagination used when a screen/data source doesn't specify one.
  static const int defaultPage = 1;
  static const int defaultPageLimit = 20;

  // Form validation limits, enforced client-side to match backend limits.
  static const int nameMaxLength = 100;
  static const int descriptionMaxLength = 500;

  // Canonical display format for dates across the app (list, detail, forms).
  static const String dateDisplayFormat = 'd MMM yyyy';
}
