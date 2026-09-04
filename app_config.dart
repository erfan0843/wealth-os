/// پیکربندی سراسری برنامه. (Feature flags — بند ۸۳، ۹۹، ۷۹)
class AppConfig {
  AppConfig._();

  static const appName = 'سامانهٔ ثروت'; // Wealth OS
  static const supportAi = false; // بند ۷۹: AI کاملاً اختیاری و در حال حاضر خاموش.
  static const supportSms = false; // بند ۴۱: پردازش SMS اختیاری — فعلاً خاموش.
  static const supportCloud = false; // بند ۳: Cloud فقط Backup/Sync — فعلاً خاموش.
}
