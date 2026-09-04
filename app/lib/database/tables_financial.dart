/// جدول‌های مالی — رویداد، دفتر کل، تراکنش، بدهی/طلب/وام/چک، قیمت، کارمزد،
/// بودجه/هدف، پیوست، SMS، تکرارشونده، Audit/Sync/Backup.
library;

import 'package:drift/drift.dart';

import 'tables.dart';

// ---------- Events & Ledger (بند ۱۴-۱۶، ۷۴) ----------
class FinancialEvents extends Table {
  TextColumn get id => text()(); // row_uuid پایدار
  TextColumn get userId => text()();
  TextColumn get kind => text()(); // INCOME/EXPENSE/TRANSFER/ASSET_BUY/...
  TextColumn get status => text().withDefault(const Constant('ACTIVE'))();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get currency => text().withDefault(const Constant('IRT'))();
  IntColumn get totalAmountMinor => integer().withDefault(const Constant(0))();
  TextColumn get referenceEventId => text().nullable()(); // Reversal (بند ۷۴)
  TextColumn get note => text().nullable()();
  TextColumn get tags => text().nullable()(); // JSON
  TextColumn get metadata => text().nullable()(); // JSON
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class LedgerEntries extends Table {
  TextColumn get id => text()();
  TextColumn get eventId => text()();
  TextColumn get side => text()(); // DEBIT/CREDIT
  TextColumn get subjectType => text()(); // ACCOUNT/ASSET/LIABILITY
  TextColumn get subjectId => text()();
  IntColumn get amountMinor => integer().nullable()();
  RealColumn get quantity => real().nullable()();
  TextColumn get unit => text().nullable()();
  TextColumn get currency => text().withDefault(const Constant('IRT'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get eventId => text()();
  TextColumn get userId => text()();
  TextColumn get kind => text()(); // EXPENSE/INCOME/TRANSFER/...
  TextColumn get counterparty => text().nullable()();
  TextColumn get merchant => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get fromAccountId => text().nullable()();
  TextColumn get toAccountId => text().nullable()();
  IntColumn get amountMinor => integer()();
  IntColumn get feeMinor => integer().withDefault(const Constant(0))();
  IntColumn get taxMinor => integer().withDefault(const Constant(0))();
  TextColumn get priceSnapshot => text().nullable()(); // JSON (بند ۳۷)
  TextColumn get feeSnapshot => text().nullable()(); // JSON (بند ۳۷)
  TextColumn get manualOverride => text().nullable()(); // JSON (بند ۳۸)
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get parentId => text().nullable()();
  TextColumn get type => text()(); // INCOME/EXPENSE
  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class EventTags extends Table {
  TextColumn get eventId => text()();
  TextColumn get tagId => text()();

  @override
  Set<Column> get primaryKey => {eventId, tagId};
}

// ---------- Pricing (بند ۲۷-۳۱) ----------
class PriceSources extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()(); // NULL = global/system
  TextColumn get code => text()(); // MANUAL/API/CSV/CHARISMA/CUSTOM
  TextColumn get name => text()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  TextColumn get config => text().withDefault(const Constant('{}'))(); // JSON
  DateTimeColumn get lastFetchAt => dateTime().nullable()();
  TextColumn get lastStatus => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class PriceHistory extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get assetTypeId => text()();
  TextColumn get assetId => text().nullable()();
  RealColumn get priceFloat => real()();
  IntColumn get priceMinor => integer().nullable()();
  TextColumn get currency => text().withDefault(const Constant('IRT'))();
  TextColumn get unit => text()();
  TextColumn get sourceId => text()();
  TextColumn get sourceStatus => text().withDefault(const Constant('LIVE'))();
  DateTimeColumn get observedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class PriceCache extends Table {
  TextColumn get assetTypeId => text()();
  TextColumn get assetId => text().nullable()();
  RealColumn get lastPrice => real().withDefault(const Constant(0))();
  TextColumn get lastCurrency => text().withDefault(const Constant('IRT'))();
  DateTimeColumn get lastObservedAt => dateTime().nullable()();
  TextColumn get sourceId => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('STALE'))(); // LIVE/STALE
  DateTimeColumn get fetchedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {assetTypeId, assetId};
}

class PriceOverrides extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get assetId => text()();
  RealColumn get previous => real()();
  RealColumn get newValue => real()();
  TextColumn get reason => text().nullable()();
  DateTimeColumn get changedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------- Fee (بند ۳۲-۳۶) ----------
class FeeRules extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()(); // NULL = global
  TextColumn get scope =>
      text().withDefault(const Constant('GLOBAL'))(); // GLOBAL/TYPE/ASSET/TRANSACTION/USER
  TextColumn get assetTypeId => text().nullable()();
  TextColumn get assetId => text().nullable()();
  TextColumn get kind => text()(); // PERCENT/FIXED/PERCENT_FIXED/MIN/MAX
  RealColumn get value => real()();
  RealColumn get min => real().nullable()();
  RealColumn get max => real().nullable()();
  TextColumn get appliesTo => text().withDefault(const Constant('BOTH'))(); // BUY/SELL/BOTH
  TextColumn get timeStart => text().nullable()(); // "08:00"
  TextColumn get timeEnd => text().nullable()(); // "14:00"
  IntColumn get dayOfWeek => integer().nullable()(); // 0-6 (شنبه=0)
  DateTimeColumn get dateFrom => dateTime().nullable()();
  DateTimeColumn get dateTo => dateTime().nullable()();
  RealColumn get qtyFrom => real().nullable()();
  RealColumn get qtyTo => real().nullable()();
  RealColumn get amountFrom => real().nullable()();
  RealColumn get amountTo => real().nullable()();
  IntColumn get priority => integer().withDefault(const Constant(0))(); // بند ۳۵
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------- Liabilities (بند ۴۵-۴۹؛ C5) ----------
class Debts extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get creditor => text()();
  IntColumn get principalMinor => integer()();
  IntColumn get remainingMinor => integer()();
  IntColumn get paidMinor => integer().withDefault(const Constant(0))();
  TextColumn get currency => text().withDefault(const Constant('IRT'))();
  DateTimeColumn get issuedAt => dateTime()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  RealColumn get interestRate => real().nullable()();
  IntColumn get feeMinor => integer().withDefault(const Constant(0))();
  IntColumn get penaltyMinor => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('OPEN'))(); // OPEN/PAID/OVERDUE
  TextColumn get notes => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Receivables extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get debtor => text()();
  IntColumn get principalMinor => integer()();
  IntColumn get remainingMinor => integer()();
  IntColumn get paidMinor => integer().withDefault(const Constant(0))();
  TextColumn get currency => text().withDefault(const Constant('IRT'))();
  DateTimeColumn get issuedAt => dateTime()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('OPEN'))(); // OPEN/COLLECTED/OVERDUE
  TextColumn get notes => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Loans extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get direction => text()(); // BORROW/LEND
  IntColumn get principalMinor => integer()();
  IntColumn get interestMinor => integer().withDefault(const Constant(0))();
  IntColumn get feeMinor => integer().withDefault(const Constant(0))();
  IntColumn get remainingMinor => integer()();
  IntColumn get paidMinor => integer().withDefault(const Constant(0))();
  TextColumn get currency => text().withDefault(const Constant('IRT'))();
  DateTimeColumn get disbursedAt => dateTime()();
  TextColumn get status => text().withDefault(const Constant('OPEN'))(); // OPEN/CLOSED

  @override
  Set<Column> get primaryKey => {id};
}

class Schedules extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get ownerType => text()(); // LOAN/INSTALLMENT/BNPL/DEBT/RECEIVABLE/CHECK/RECURRING
  TextColumn get ownerId => text()();
  TextColumn get kind => text()(); // DAILY/WEEKLY/MONTHLY/YEARLY/CUSTOM
  IntColumn get frequency => integer().withDefault(const Constant(1))();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  IntColumn get amountMinor => integer()();
  TextColumn get currency => text().withDefault(const Constant('IRT'))();
  DateTimeColumn get nextDueAt => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('ACTIVE'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Checks extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get direction => text()(); // ISSUED/RECEIVED
  IntColumn get amountMinor => integer()();
  DateTimeColumn get issueDate => dateTime()();
  DateTimeColumn get dueDate => dateTime()();
  TextColumn get counterparty => text()();
  TextColumn get bank => text().nullable()();
  TextColumn get reference => text().nullable()();
  TextColumn get status =>
      text().withDefault(const Constant('PENDING'))(); // PENDING/CLEARED/RETURNED/CANCELLED
  TextColumn get notes => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class LiabilityAggregates extends Table {
  TextColumn get entityType => text()(); // DEBT/RECEIVABLE/LOAN
  TextColumn get entityId => text()();
  IntColumn get remainingMinor => integer()();
  IntColumn get paidMinor => integer()();
  TextColumn get status => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {entityType, entityId};
}

// ---------- Budget/Goal (بند ۵۹-۶۰) ----------
class Budgets extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get categoryId => text()();
  TextColumn get period => text()();
  IntColumn get amountMinor => integer()();
  TextColumn get currency => text().withDefault(const Constant('IRT'))();
  TextColumn get status => text().withDefault(const Constant('ACTIVE'))();

  @override
  Set<Column> get primaryKey => {id};
}

class Goals extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get targetType => text()(); // AMOUNT/QUANTITY
  RealColumn get targetValue => real()();
  TextColumn get unit => text().nullable()();
  RealColumn get currentValue => real().withDefault(const Constant(0))();
  DateTimeColumn get targetDate => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('OPEN'))();

  @override
  Set<Column> get primaryKey => {id};
}

class GoalLinks extends Table {
  TextColumn get goalId => text()();
  TextColumn get entityType => text()(); // ASSET/ACCOUNT/RECEIVABLE
  TextColumn get entityId => text()();
  RealColumn get weight => real().withDefault(const Constant(1.0))();

  @override
  Set<Column> get primaryKey => {goalId, entityId};
}

// ---------- Attachments / OCR (بند ۶۵-۶۶) ----------
class Attachments extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get ownerType => text()(); // EVENT/ASSET
  TextColumn get ownerId => text()();
  TextColumn get filePath => text()();
  TextColumn get mime => text()();
  TextColumn get bytes => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('LOCAL'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------- SMS (بند ۴۱-۴۳) ----------
class SmsMessages extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get smsId => text()();
  TextColumn get sender => text()();
  TextColumn get bodyHash => text()();
  TextColumn get parsed => text().nullable()(); // JSON
  TextColumn get matchStatus => text().nullable()();
  TextColumn get duplicateOf => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class SmartRules extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get matcherType => text()(); // MERCHANT/REGEX/AMOUNT
  TextColumn get pattern => text()();
  TextColumn get action => text()(); // category_id/direction/...
  IntColumn get hitCount => integer().withDefault(const Constant(0))();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------- Recurring (بند ۴۴) ----------
class Recurring extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get kind => text()();
  TextColumn get categoryId => text().nullable()();
  IntColumn get amountMinor => integer()();
  TextColumn get scheduleId => text()();
  TextColumn get nextDue => text().nullable()(); // JSON cursor
  TextColumn get status => text().withDefault(const Constant('ACTIVE'))();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------- Audit / Sync / Backup (بند ۶۸-۶۹، ۷۳) ----------
class AuditLogs extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get action => text()();
  TextColumn get oldValue => text().nullable()(); // JSON
  TextColumn get newValue => text().nullable()(); // JSON
  TextColumn get reason => text().nullable()();
  DateTimeColumn get changedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get deviceId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class SyncOutbox extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get op => text()(); // CREATE/UPDATE/DELETE
  IntColumn get revision => integer().withDefault(const Constant(0))();
  TextColumn get payload => text()(); // JSON
  TextColumn get state => text().withDefault(const Constant('PENDING'))();
  TextColumn get conflictLog => text().nullable()(); // JSON
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Backups extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get filePath => text()();
  TextColumn get kind => text().withDefault(const Constant('LOCAL'))(); // LOCAL/CLOUD
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get restoredAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
