import 'package:intl/intl.dart';

final _usd = NumberFormat.simpleCurrency(name: 'USD');

/// Formats a USD amount, e.g. `9.99` → `$9.99`.
String formatPrice(double amount) => _usd.format(amount);
