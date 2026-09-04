/// نتیجه‌ی عملیات — الگوی Result/Either برای مدیریت خطا بدون Exception.
/// هسته‌ی خالص؛ بدون Flutter. قابل تست با `dart test`.
library;

class AppError {
  final String code;
  final String message;
  final Object? cause;

  const AppError(this.code, this.message, [this.cause]);

  static const insufficientFunds =
      AppError('insufficient_funds', 'موجودی حساب کافی نیست');
  static const insufficientQuantity =
      AppError('insufficient_quantity', 'مقدار کافی برای فروش وجود ندارد');
  static const invalidAmount =
      AppError('invalid_amount', 'مبلغ نامعتبر است');
  static const invalidQuantity =
      AppError('invalid_quantity', 'مقدار نامعتبر است');
  static const shortNotAllowed =
      AppError('short_not_allowed', 'فروش بیش از موجودی مجاز نیست');
  static const unknown = AppError('unknown', 'خطای ناشناخته');

  @override
  String toString() => 'AppError($code: $message)';
}

sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);
}

final class Err<T> extends Result<T> {
  final AppError error;
  const Err(this.error);
}

Result<T> ok<T>(T value) => Ok<T>(value);
Result<T> err<T>(AppError error) => Err<T>(error);

extension ResultExt<T> on Result<T> {
  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;
  T? get value => this is Ok<T> ? (this as Ok<T>).value : null;
  AppError? get error => this is Err<T> ? (this as Err<T>).error : null;
}
