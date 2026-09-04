/// موتور کارمزد (بند ۳۲-۳۶).
/// - Resolution: بالاترین Priority برنده؛ در اولویت مساوی، آخرین‌قانون غالب (بند ۳۵/۳۷).
/// - Apply Override آخرین‌زمان (بند ۳۸).
/// - Compute فرمول + کف/سقف (بند ۳۶).
/// - Snapshot در لحظهٔ ثبت (بند ۳۷).
/// هستهٔ خالص؛ قابل تست.
library;

import 'fee_rule.dart';

/// حاصل محاسبهٔ کارمزد.
class FeeResult {
  final FeeRule? rule;
  final num fee;
  final bool overridden;

  const FeeResult({this.rule, required this.fee, this.overridden = false});
}

/// موتور کارمزد.
class FeeEngine {
  final List<FeeRule> _rules;
  final List<FeeOverride> _overrides;

  const FeeEngine(this._rules, [this._overrides = const []]);

  /// انتخاب قاعدهٔ غالب برای یک زمینه.
  FeeRule? resolve(FeeContext context) {
    FeeRule? best;
    for (final r in _rules) {
      if (!_matches(r, context)) continue;
      // اولویت بالاتر برنده؛ در هم‌رتبه آخرین غالب.
      if (best == null || r.priority.rank >= best.priority.rank) {
        best = r;
      }
    }
    if (best == null) return null;
    // آخرین override (بند ۳۸).
    final ov = _lastOverride(best.id);
    if (ov != null) {
      return FeeRule(
        id: best.id,
        kind: best.kind,
        priority: best.priority,
        rate: FeeRate(
          type: best.rate.type,
          percent: ov.overridePercent ?? best.rate.percent,
          fixed: ov.overrideRate ?? best.rate.fixed,
          minimum: best.rate.minimum,
          maximum: best.rate.maximum,
        ),
        assetId: best.assetId,
        assetTypeId: best.assetTypeId,
        userId: best.userId,
        conditions: best.conditions,
      );
    }
    return best;
  }

  bool _matches(FeeRule r, FeeContext c) {
    // scope.
    if (r.assetId != null && r.assetId != c.assetId) return false;
    if (r.assetTypeId != null && r.assetTypeId != c.assetTypeId) return false;
    if (r.userId != null && r.userId != c.userId) return false;
    // شرایط.
    return r.conditions.matches(c);
  }

  FeeOverride? _lastOverride(String ruleId) {
    FeeOverride? last;
    for (final o in _overrides) {
      if (o.ruleId != ruleId) continue;
      if (last == null || o.at.isAfter(last.at)) last = o;
    }
    return last;
  }

  /// محاسبهٔ کارمزد با فرمول و کف/سقف.
  FeeResult compute(FeeContext context) {
    final rule = resolve(context);
    if (rule == null) return const FeeResult(fee: 0);
    return FeeResult(
      rule: rule,
      fee: rule.rate.compute(context.amount),
      overridden: _lastOverride(rule.id) != null,
    );
  }

  /// ثبت اسنیپ‌شات (بند ۳۷).
  FeeRuleSnapshot snapshot(FeeRule rule) => FeeRuleSnapshot(
        ruleId: rule.id,
        rate: rule.rate,
        kind: rule.kind,
        capturedAt: DateTime.now().toUtc(),
      );
}
