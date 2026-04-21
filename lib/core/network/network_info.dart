import 'dart:io';

/// Helpers for detecting network availability without an extra package.
///
/// Uses [InternetAddress.lookup] (built into dart:io) to probe DNS.
/// All checks are async and should not be called on the UI thread hot-path.
abstract class NetworkInfo {
  NetworkInfo._();

  static const String offlineMessage =
      'No internet connection. Please check your network and try again.';

  /// Returns `true` if the device can resolve DNS for an external host.
  static Future<bool> isConnected() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on Exception {
      return false;
    }
  }

  /// Returns `true` when [error] is caused by a missing/broken network
  /// connection — covers SocketException, DNS failure, timeout, etc.
  static bool isNetworkError(Object error) {
    if (error is SocketException) return true;
    if (error is HandshakeException) return true;
    final msg = error.toString().toLowerCase();
    return msg.contains('socketexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('no address associated') ||
        msg.contains('network is unreachable') ||
        msg.contains('connection refused') ||
        msg.contains('connection timed out') ||
        msg.contains('errno = 7') ||
        msg.contains('errno = 101') ||
        msg.contains('errno = 111');
  }
}
