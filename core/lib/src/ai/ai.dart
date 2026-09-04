/// لایهٔ AI (فاز ۱۴ مستر) — کاملاً اختیاری (بند ۵/۷۹/۱۰۲).
/// - FinancialSummaryExtractor: «استخراج ساختاریافته» را در دستگاه انجام می‌دهد
///   (بند ۷۸: سیستِم اول دادهٔ ساختاریافته را می‌کْشد؛ AI نه محاسبات پایه).
/// - AiProvider: رابط تزریق (بدون کلید/URL هاردکد — بند ۶).
/// - AiAssistant: اگر خاموش/بدون Provider → null و برنامه بدون AI کامل کار می‌کند (بند ۷۹).
/// - LocalAnalytics: تحلیل/آنومالی ساده به‌صورت Local (بند ۷۷/۸۰) — بدون AI.
/// همهٔ مبالغ واحد جزئی؛ دادهٔ حساس با Privacy redact (بند ۶).
/// هستهٔ خالص؛ قابل تست.
library;

/// حالت حریم خصوصی (بند ۶): فقط دادهٔ ضروری علامت‌گذاری/رد می‌شود.
enum AiPrivacyMode { off, minimal }

class AiSettings {
  final bool enabled;
  final AiPrivacyMode privacy;

  const AiSettings({this.enabled = false, this.privacy = AiPrivacyMode.minimal});
}

/// یک واقعیت ساختاریافته (محاسبه در دستگاه). فقط حقایق؛ نه متن.
class FinancialSummary {
  final int incomeMinor;
  final int expenseMinor;
  final int assetValueChangeMinor; // تغییر ارزش دارایی.
  final int liabilityChangeMinor; // تغییر بدهی.
  final int realizedPnlMinor;
  final int unrealizedPnlMinor;
  final int netWorthMinor;
  final double netWorthGrowthPercent;
  final List<Insight> insights;

  const FinancialSummary({
    required this.incomeMinor,
    required this.expenseMinor,
    required this.assetValueChangeMinor,
    required this.liabilityChangeMinor,
    required this.realizedPnlMinor,
    required this.unrealizedPnlMinor,
    required this.netWorthMinor,
    required this.netWorthGrowthPercent,
    this.insights = const [],
  });

  /// تغییر خالص ثروت = درآمد − هزینه + تغییر دارایی − تغییر بدهی + P&L.
  int get netChangeMinor =>
      incomeMinor - expenseMinor + assetValueChangeMinor -
      liabilityChangeMinor + realizedPnlMinor + unrealizedPnlMinor;

  /// نسخهٔ خلاصهٔ قابل‌اتصال به AI (Privacy-redact — بند ۶).
  String buildAiSafeSummary() {
    return [
      '${incomeMinor} درآمد، ${expenseMinor} هزینه، '
          '${assetValueChangeMinor} تغییر ارزش دارایی، ${liabilityChangeMinor} تغییر بدهی، '
          '${realizedPnlMinor} سود تحقق‌یافته، ${unrealizedPnlMinor} سود تحقق‌نیافته، '
          '${netWorthMinor} دارایی خالص (${netWorthGrowthPercent}٪ رشد)'
    ].join();
  }
}

/// پرچم/نشانهٔ محلی (LocalAnalytics).
class Insight {
  final String id;
  final String kind; // ANOMALY / TREND / ALERT.
  final String messageFa;
  final int severity; // 1 کم ... 3 مهم.

  const Insight(this.id, this.kind, this.messageFa, this.severity);
}

/// استخراج ساختاریافته — در دستگاه (بند ۷۸).
class FinancialSummaryExtractor {
  const FinancialSummaryExtractor();

  FinancialSummary build({
    required int incomeMinor,
    required int expenseMinor,
    required int assetValueChangeMinor,
    required int liabilityChangeMinor,
    required int realizedPnlMinor,
    required int unrealizedPnlMinor,
    required int netWorthMinor,
    required double netWorthGrowthPercent,
  }) {
    return FinancialSummary(
      incomeMinor: incomeMinor,
      expenseMinor: expenseMinor,
      assetValueChangeMinor: assetValueChangeMinor,
      liabilityChangeMinor: liabilityChangeMinor,
      realizedPnlMinor: realizedPnlMinor,
      unrealizedPnlMinor: unrealizedPnlMinor,
      netWorthMinor: netWorthMinor,
      netWorthGrowthPercent: netWorthGrowthPercent,
    );
  }
}

/// رابط AI (تزریقِ خارجی — کلید/URL در لایهٔ App/SecureStorage؛ نه اینجا).
abstract interface class AiProvider {
  Future<String?> generateInsight(FinancialSummary summary, String question);
}

/// دستیار AI — اختیاری. اگر خاموش/بدون Provider → null.
class AiAssistant {
  final AiProvider? _provider;
  final AiSettings _settings;

  const AiAssistant(this._provider, this._settings);

  bool get enabled => _settings.enabled && _provider != null;

  Future<String?> ask(String question, FinancialSummary summary) async {
    if (!enabled) return null;
    // بند ۶: در حالت minimal فقط حقایقِ ضروری و بدون شناسهٔ شخصی.
    return _provider!.generateInsight(summary, question);
  }
}

/// تحلیل محلی (بند ۷۷/۸۰) — بدون AI.
class LocalAnalytics {
  const LocalAnalytics();

  /// میانگینِ نرمال برای یک دوره.
  double average(double total, int count) => count == 0 ? 0 : total / count;

  /// رشد دسته‌بندی (٪).
  double categoryGrowth(double now, double before) =>
      before == 0 ? 0 : (now - before) / before * 100;

  /// آنومالی ساده: اگر نرخ تغییر بیش از آستانه → هشدار (بند ۷۷).
  Insight? anomalyOnChange({required double changePercent, required double threshold}) {
    if (changePercent >= threshold) {
      return Insight(
        'anomaly',
        'ANOMALY',
        'مقدار نسبت به دورهٔ قبل ${changePercent.round()}٪ تغییر کرده (آستانه ${threshold.round()}٪).',
        2,
      );
    }
    return null;
  }
}
