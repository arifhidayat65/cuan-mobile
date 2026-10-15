import 'package:intl/intl.dart';

final _idr = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp',
  decimalDigits: 0,
);

/// "Rp23.457.398" — tight thousand separators.
String idr(num value) => _idr.format(value).replaceAll('Rp', 'Rp');

String idrCompact(num value) {
  if (value >= 1000000000) {
    return 'Rp${(value / 1000000000).toStringAsFixed(1)} M';
  }
  if (value >= 1000000) {
    return 'Rp${(value / 1000000).toStringAsFixed(1)} jt';
  }
  if (value >= 1000) {
    return 'Rp${(value / 1000).toStringAsFixed(0)} rb';
  }
  return 'Rp${value.toStringAsFixed(0)}';
}

String monthKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}';

String monthLabel(DateTime d) {
  const months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  return '${months[d.month - 1]} ${d.year}';
}
