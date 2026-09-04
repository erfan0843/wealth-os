/// لاگ توسعه‌دهنده — بند ۹۸: هرگز دادهٔ مالی تولیدکننده در لاگ چاپ نمی‌شود.
enum LogLevel { debug, info, warn, error }

class Logger {
  Logger._();
  static const bool enableLogging = true;

  static void debug(String tag, String msg) => _log(LogLevel.debug, tag, msg);
  static void info(String tag, String msg) => _log(LogLevel.info, tag, msg);
  static void warn(String tag, String msg) => _log(LogLevel.warn, tag, msg);
  static void error(String tag, String msg, [Object? e, StackTrace? s]) {
    _log(LogLevel.error, tag, msg);
    if (s != null) '${s.toString().split('\n').take(8).join('\n')}';
  }

  static void _log(LogLevel l, String tag, String msg) {
    if (!enableLogging) return;
    // NOTE: در فازهای بعد اینجا به یک Log sink امن (بدون دادهٔ مالی) وصل می‌شود.
    // ignore: avoid_print
    print('[${l.name.toUpperCase()}] $tag: $msg');
  }
}
