import 'dart:developer';

class AppLogger {
  static void info(String message) {
    log(
      message,
      name: 'INFO',
    );
  }

  static void error(String message) {
    log(
      message,
      name: 'ERROR',
    );
  }

  static void success(String message) {
    log(
      message,
      name: 'SUCCESS',
    );
  }
}