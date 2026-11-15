/// مفاتيح التخزين المحلي (shared_preferences) — مفتاح واحد لكل حاجة.
abstract final class StorageKeys {
  /// سجل الملخصات — JSON list من SummaryModel.
  static const String history = 'besbasa_history_v1';

  /// الثيم المحفوظ: 'light' / 'dark' / null (يتبع النظام).
  static const String themeMode = 'besbasa_theme_mode';

  /// اللغة المحفوظة: 'ar' / 'en' / null (افتراضي عربي).
  static const String locale = 'besbasa_locale';
}
