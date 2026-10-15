import 'package:flutter_test/flutter_test.dart';
import 'package:cuan_mobile/core/utils/format.dart';

void main() {
  group('idr', () {
    test('formats with thousand separators', () {
      expect(idr(17105000), 'Rp17.105.000');
    });

    test('handles zero and negative', () {
      expect(idr(0), 'Rp0');
      expect(idr(-2500), '-Rp2.500');
    });

    test('short form abbreviates', () {
      expect(idrCompact(2500000), 'Rp2.5 jt');
      expect(idrCompact(1500000000), 'Rp1.5 M');
      expect(idrCompact(500000), 'Rp500 rb');
      expect(idrCompact(999), 'Rp999');
    });
  });

  group('monthLabel', () {
    test('formats Indonesian month names', () {
      expect(monthLabel(DateTime(2026, 1, 5)), 'Januari 2026');
      expect(monthLabel(DateTime(2026, 10, 14)), 'Oktober 2026');
      expect(monthLabel(DateTime(2026, 12, 25)), 'Desember 2026');
    });
  });

  group('monthKey', () {
    test('pads month with zero', () {
      expect(monthKey(DateTime(2026, 3, 1)), '2026-03');
      expect(monthKey(DateTime(2026, 11, 30)), '2026-11');
    });
  });
}
