import 'package:test/test.dart';
import 'package:wealth_core/wealth_core.dart';

class _MockAi implements AiProvider {
  final List<String> _received = [];
  @override
  Future<String?> generateInsight(FinancialSummary summary, String question) async {
    _received.add(question);
    return 'تحلیل: (ساختاریافته)';
  }
  List<String> get received => _received;
}

void main() {
  const extractor = FinancialSummaryExtractor();

  FinancialSummary summary() => extractor.build(
        incomeMinor: 10000000,
        expenseMinor: 7500000,
        assetValueChangeMinor: 2000000,
        liabilityChangeMinor: 1000000,
        realizedPnlMinor: 500000,
        unrealizedPnlMinor: 300000,
        netWorthMinor: 117000000,
        netWorthGrowthPercent: 17,
      );

  group('AiLayer — فاز ۱۴ (اختیاری، بند ۵/۷۸/۷۹)', () {
    test('خاموش → null (برنامه بدون AI کامل کار می‌کند)', () async {
      final ai = AiAssistant(_MockAi(), const AiSettings(enabled: false));
      final r = await ai.ask('چرا کم شده؟', summary());
      expect(ai.enabled, false);
      expect(r, isNull);
    });

    test('بدون Provider → null', () async {
      final ai = AiAssistant(null, const AiSettings(enabled: true));
      expect(ai.enabled, false);
      expect(await ai.ask('سؤال', summary()), isNull);
    });

    test('فعال + Provider → پاسخ و فقط دادهٔ ساختاریافته', () async {
      final mock = _MockAi();
      final ai = AiAssistant(mock, const AiSettings(enabled: true));
      final r = await ai.ask('این ماه چرا دارایی‌ام کم شده؟', summary());
      expect(ai.enabled, true);
      expect(r, isNotNull);
      expect(mock.received, isNotEmpty);
    });

    test('استخراج ساختاریافته — AI محاسبات پایه نمی‌کند (بند ۷۸)', () {
      final s = summary();
      // خالص تغییر ثروت = درآمد − هزینه + تغییر دارایی − تغییر بدهی + P&L.
      expect(s.netChangeMinor,
          10000000 - 7500000 + 2000000 - 1000000 + 500000 + 300000);
      // رشتهٔ امن حاوی حقایق، نه نام/شناسهٔ شخصی.
      final safe = s.buildAiSafeSummary();
      expect(safe, contains('117000000'));
    });

    test('LocalAnalytics — آنومالی بدون AI (بند ۷۷)', () {
      const la = LocalAnalytics();
      expect(la.average(100, 4), closeTo(25, 0.001));
      expect(la.categoryGrowth(120, 100), closeTo(20, 0.001));
      // بالای آستانه → هشدار.
      expect(la.anomalyOnChange(changePercent: 60, threshold: 50), isNotNull);
      expect(la.anomalyOnChange(changePercent: 10, threshold: 50), isNull);
    });
  });
}
