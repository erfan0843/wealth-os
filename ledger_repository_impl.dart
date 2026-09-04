import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:wealth_core/wealth_core.dart';

import '../../database/app_database.dart';
import '../domain/ledger_repository.dart';

/// پیاده‌سازی Drift برای LedgerRepository — ثبت اتمیک رویداد + سند + Aggregate.
/// (بند ۱۶: هر رویداد اثر مالی واقعی؛ بند ۷۴: Reversal به‌جای Hard Delete.)
class LedgerRepositoryImpl implements LedgerRepository {
  final AppDatabase db;
  final Uuid _uuid = const Uuid();
  final LedgerEngine _engine = const LedgerEngine();

  LedgerRepositoryImpl(this.db);

  @override
  Future<Result<FinancialEvent>> recordEvent(FinancialEvent event) async {
    // اعتبارسنجی درستی (بند ۱۵): تعادل دوبادگانه.
    if (!_engine.validateBalanced(event.entries).valid) {
      return const Err(AppError('unbalanced_ledger', 'دفتر کل متوازن نیست'));
    }
    try {
      await db.transaction(() async {
        await db.into(db.financialEvents).insert(
              FinancialEventsCompanion.insert(
                id: event.id,
                userId: event.userId,
                kind: event.kind.name,
                status: event.status.name,
                occurredAt: event.occurredAt,
                currency: event.currency.code,
                totalAmountMinor: Value(event.totalMinor),
                referenceEventId: Value(event.referenceEventId),
                note: Value(event.note),
              ),
            );
        for (final e in event.entries) {
          await db.into(db.ledgerEntries).insert(
                LedgerEntriesCompanion.insert(
                  id: _uuid.v4(),
                  eventId: event.id,
                  side: e.side.name,
                  subjectType: e.subjectType.name,
                  subjectId: e.subjectId,
                  amountMinor: Value(e.amount.amountMinor),
                  quantity: Value(e.quantity),
                  unit: Value(e.unit),
                  currency: e.amount.currency.code,
                ),
              );
          // به‌روزرسانی Aggregate (C1): حساب یا دارایی.
          await _updateAggregate(e);
        }
      });
      return Ok(event);
    } catch (err) {
      return Err(AppError('db_record_event', 'خطا در ثبت رویداد', err));
    }
  }

  Future<void> _updateAggregate(LedgerEntry e) async {
    if (e.subjectType == SubjectType.account) {
      final delta = e.side == Side.credit
          ? e.amount.amountMinor
          : -e.amount.amountMinor;
      await _bumpAccountAggregate(e.subjectId, delta);
    } else if (e.subjectType == SubjectType.asset) {
      await _bumpAssetAggregate(e);
    }
  }

  Future<void> _bumpAccountAggregate(String accountId, int delta) async {
    final agg = await (db.select(db.accountAggregates)
          ..where((t) => t.accountId.equals(accountId)))
        .getSingleOrNull();
    final newBal = (agg?.balanceMinor ?? 0) + delta;
    await (db.update(db.accountAggregates)
          ..where((t) => t.accountId.equals(accountId)))
        .write(AccountAggregatesCompanion(
            balanceMinor: Value(newBal),
            lastEventId: Value(agg?.lastEventId),
            updatedAt: Value(DateTime.now().toUtc())));
  }

  Future<void> _bumpAssetAggregate(LedgerEntry e) async {
    final qty = e.quantity ?? 0;
    final deltaQty = e.side == Side.debit ? qty : -qty;
    final agg = await (db.select(db.assetAggregates)
          ..where((t) => t.assetId.equals(e.subjectId)))
        .getSingleOrNull();
    await (db.into(db.assetAggregates).insert(
          AssetAggregatesCompanion.insert(
            assetId: e.subjectId,
            quantity: Value((agg?.quantity ?? 0) + deltaQty),
            costBasisTotal: Value(agg?.costBasisTotal ?? 0),
            marketValue: Value(agg?.marketValue ?? 0),
            lastPrice: Value(agg?.lastPrice ?? 0),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
          mode: InsertMode.insertOrIgnore,
        ));
  }

  @override
  Future<Result<List<FinancialEvent>>> listEvents(String userId,
      {DateTime? from, DateTime? to, EventKind? kind}) async {
    try {
      final q = db.select(db.financialEvents)
        ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false));
      if (from != null) q.where((t) => t.occurredAt.isBiggerOrEqualValue(from));
      if (to != null) q.where((t) => t.occurredAt.isSmallerOrEqualValue(to));
      if (kind != null) q.where((t) => t.kind.equals(kind.name));
      final rows = await q.get();
      final result = <FinancialEvent>[];
      for (final r in rows) {
        final entries = await (db.select(db.ledgerEntries)
              ..where((t) => t.eventId.equals(r.id)))
            .get();
        result.add(FinancialEvent(
          id: r.id,
          userId: r.userId,
          kind: EventKind.values.firstWhere((k) => k.name == r.kind),
          occurredAt: r.occurredAt,
          currency: Currency.values.firstWhere((c) => c.code == r.currency),
          status: EventStatus.values.firstWhere((s) => s.name == r.status),
          referenceEventId: r.referenceEventId,
          note: r.note,
          entries: entries
              .map((e) => LedgerEntry(
                    side: Side.values.firstWhere((s) => s.name == e.side),
                    subjectType:
                        SubjectType.values.firstWhere((s) => s.name == e.subjectType),
                    subjectId: e.subjectId,
                    amount: Money(e.amountMinor ?? 0,
                        Currency.values.firstWhere((c) => c.code == e.currency)),
                    quantity: e.quantity,
                    unit: e.unit,
                  ))
              .toList(),
        ));
      }
      return Ok(result);
    } catch (err) {
      return Err(AppError('db_list_events', 'خطا در بازیابی رویدادها', err));
    }
  }

  @override
  Future<Result<FinancialEvent>> reverseEvent(
      String eventId, String userId) async {
    try {
      // رویداد اصلی را REVERSED می‌کنیم.
      await (db.update(db.financialEvents)..where((t) => t.id.equals(eventId)))
          .write(const FinancialEventsCompanion(status: Value('REVERSED')));
      // رویداد برگشت جدید با سندهای معکوس.
      final revId = _uuid.v4();
      await db.transaction(() async {
        final entries = await (db.select(db.ledgerEntries)
              ..where((t) => t.eventId.equals(eventId)))
            .get();
        for (final e in entries) {
          await db.into(db.ledgerEntries).insert(
                LedgerEntriesCompanion.insert(
                  id: _uuid.v4(),
                  eventId: revId,
                  side: e.side == 'credit' ? 'debit' : 'credit',
                  subjectType: e.subjectType,
                  subjectId: e.subjectId,
                  amountMinor: Value(e.amountMinor),
                  quantity: Value(e.quantity),
                  unit: Value(e.unit),
                  currency: e.currency,
                ),
              );
        }
        await db.into(db.financialEvents).insert(
              FinancialEventsCompanion.insert(
                id: revId,
                userId: userId,
                kind: 'other',
                status: 'ACTIVE',
                occurredAt: DateTime.now().toUtc(),
                currency: 'IRT',
                referenceEventId: Value(eventId),
              ),
            );
      });
      return const Ok(FinancialEvent(
          id: '', userId: '', kind: EventKind.other,
          occurredAt: null, currency: Currency.irt,
          entries: []));
    } catch (err) {
      return Err(AppError('db_reverse_event', 'خطا در برگشت رویداد', err));
    }
  }

  @override
  Future<Result<int>> balanceOf(String accountId, Currency currency) async {
    try {
      final agg = await (db.select(db.accountAggregates)
            ..where((t) => t.accountId.equals(accountId)))
          .getSingleOrNull();
      return Ok(agg?.balanceMinor ?? 0);
    } catch (err) {
      return Err(AppError('db_balance', 'خطا در خواندن موجودی', err));
    }
  }
}
