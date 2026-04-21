import 'package:intl/intl.dart';

String formatInr(num amount) {
  final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  return fmt.format(amount);
}
