import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';
import 'tables_financial.dart';

part 'app_database.g.dart';

/// پایگاه‌دادهٔ محلی (Source of Truth در حالت Offline — بند ۳/۲).
/// Drift/SQLite type-safe + Migration نسخه‌بندی. Encryption در لایهٔ بازکردن
/// با کلید KeyStore پیاده می‌شود (بند ۷۲).
@DriftDatabase(tables: [
  Users,
  UserSettings,
  Accounts,
  AccountAggregates,
  AssetTypes,
  Assets,
  AssetLots,
  AssetAggregates,
  FinancialEvents,
  LedgerEntries,
  Transactions,
  Categories,
  Tags,
  EventTags,
  PriceSources,
  PriceHistory,
  PriceCache,
  PriceOverrides,
  FeeRules,
  Debts,
  Receivables,
  Loans,
  Schedules,
  Checks,
  LiabilityAggregates,
  Budgets,
  Goals,
  GoalLinks,
  Attachments,
  SmsMessages,
  SmartRules,
  Recurring,
  AuditLogs,
  SyncOutbox,
  Backups,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _createDefaultExecutor());

  static QueryExecutor _createDefaultExecutor() {
    return LazyDatabase(() async {
      final dir = await getApplicationSupportDirectory();
      final file = File(p.join(dir.path, 'wealth_os.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedDefaults();
        },
        onUpgrade: (m, from, to) async {
          // نسخه‌بندی آینده: `if (from < 2) { await m.addColumn(...); }`
          await m.createAll();
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA journal_mode = WAL;');
          await customStatement('PRAGMA foreign_keys = ON;');
        },
      );

  /// دادهٔ پیش‌فرض (Seed) — انواع دارایی سیستمی (بند ۱۹).
  Future<void> _seedDefaults() async {
    const typeSeed = {
      'SILVER': 'نقره',
      'GOLD': 'طلا',
      'COIN': 'سکه',
      'CURRENCY': 'ارز',
      'STOCK': 'سهام',
      'FUND': 'صندوق',
      'CRYPTO': 'ارز دیجیتال',
      'PROPERTY': 'ملک',
      'VEHICLE': 'خودرو',
      'BUSINESS': 'سرمایهٔ کسب‌وکار',
      'CUSTOM': 'سفارشی',
    };
    for (final e in typeSeed.entries) {
      await into(assetTypes).insert(
        AssetTypesCompanion.insert(
          id: 'sys-type-${e.key}',
          userId: '',
          code: e.key,
          displayName: e.value,
          unitDefault: _unitFor(e.key),
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }
  }

  String _unitFor(String code) {
    switch (code) {
      case 'SILVER':
      case 'GOLD':
        return 'gram';
      case 'CURRENCY':
        return 'dollar';
      case 'STOCK':
      case 'FUND':
        return 'share';
      case 'CRYPTO':
        return 'token';
      case 'COIN':
        return 'piece';
      case 'PROPERTY':
        return 'm2';
      case 'VEHICLE':
        return 'vehicle';
      default:
        return 'unit';
    }
  }
}
