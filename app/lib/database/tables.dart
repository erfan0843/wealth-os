/// جدول‌های پایگاه‌دادهٔ محلی — مطابق ERD فاز ۳.
/// همهٔ جدول‌های کاربری دارای `user_id` (Row-Level isolation — بند ۷) و
/// `is_deleted`/`deleted_at` (Soft delete — بند ۷۴) هستند.
library;

import 'package:drift/drift.dart';

// ---------- Identity & Settings (بند ۷، ۸) ----------
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get emailHash => text().nullable()();
  TextColumn get phoneHash => text().nullable()();
  TextColumn get avatarPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class UserSettings extends Table {
  TextColumn get userId => text()();
  TextColumn get currency => text().withDefault(const Constant('IRT'))();
  TextColumn get referenceAsset => text().withDefault(const Constant('toman'))();
  TextColumn get dateFormat => text().withDefault(const Constant('shamsi'))();
  IntColumn get decimalPrecision => integer().withDefault(const Constant(0))();
  TextColumn get themeMode => text().withDefault(const Constant('system'))();
  TextColumn get accentColor => text().withDefault(const Constant('zemoori'))();
  TextColumn get dashboardWidgets => text().withDefault(const Constant('[]'))(); // JSON
  TextColumn get showAssetBalances => text().withDefault(const Constant('{}'))(); // JSON
  BoolColumn get appLockEnabled => boolean().withDefault(const Constant(false))();
  BoolColumn get aiEnabled => boolean().withDefault(const Constant(false))();
  BoolColumn get cloudSyncEnabled => boolean().withDefault(const Constant(false))();
  TextColumn get notificationsConfig => text().withDefault(const Constant('{}'))();
  TextColumn get privacyFlags => text().withDefault(const Constant('{}'))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {userId};
}

// ---------- Accounts (بند ۳۹) ----------
class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // CASH/BANK/WALLET/BUSINESS/OTHER
  TextColumn get currency => text().withDefault(const Constant('IRT'))();
  IntColumn get balanceMinor => integer().withDefault(const Constant(0))();
  TextColumn get owner => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('ACTIVE'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class AccountAggregates extends Table {
  TextColumn get accountId => text()();
  IntColumn get balanceMinor => integer().withDefault(const Constant(0))();
  TextColumn get lastEventId => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {accountId};
  @override
  List<Set<Column>> get uniqueKeys => [];
}

// ---------- Assets (بند ۱۹-۲۶؛ Generic) ----------
class AssetTypes extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get code => text()(); // GOLD/SILVER/COIN/CURRENCY/STOCK/FUND/CRYPTO/PROPERTY/VEHICLE/BUSINESS/EQUIPMENT/CUSTOM
  TextColumn get displayName => text()();
  TextColumn get unitDefault => text()(); // gram/dollar/share/token/piece/m2/vehicle...
  TextColumn get defaultCurrency => text().withDefault(const Constant('IRT'))();
  TextColumn get liquidityClass =>
      text().withDefault(const Constant('LIQUID'))(); // LIQUID/SEMI_LIQUID/NON_LIQUID
  BoolColumn get supportsShort => boolean().withDefault(const Constant(false))();
  IntColumn get decimalPrecision => integer().withDefault(const Constant(2))();
  TextColumn get metadataSchema => text().withDefault(const Constant('{}'))(); // JSON
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Assets extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get assetTypeId => text()();
  TextColumn get name => text()();
  TextColumn get identifier => text().nullable()();
  TextColumn get unit => text()();
  RealColumn get currentQuantity => real().withDefault(const Constant(0))();
  RealColumn get currentCostBasis => real().withDefault(const Constant(0))();
  TextColumn get costMethod => text().withDefault(const Constant('AVG'))(); // AVG/FIFO/SPECIFIC
  TextColumn get metadata => text().withDefault(const Constant('{}'))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class AssetLots extends Table {
  TextColumn get id => text()();
  TextColumn get assetId => text()();
  RealColumn get quantity => real()();
  RealColumn get unitPrice => real()();
  RealColumn get costBasisSum => real()();
  DateTimeColumn get openedAt => dateTime()();
  DateTimeColumn get closedAt => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('OPEN'))();
  TextColumn get sourceEventId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class AssetAggregates extends Table {
  TextColumn get assetId => text()();
  RealColumn get quantity => real().withDefault(const Constant(0))();
  RealColumn get costBasisTotal => real().withDefault(const Constant(0))();
  RealColumn get marketValue => real().withDefault(const Constant(0))();
  RealColumn get lastPrice => real().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {assetId};
}

// ---------- Accounts/Assets/Entities indexes ----------
// (تعریف ایندکس‌ها در فایل جدا؛ برای خوانایی Schema خالص)
