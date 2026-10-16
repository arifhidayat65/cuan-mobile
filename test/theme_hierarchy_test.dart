import 'package:cuan_mobile/core/theme/ledger_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Task 1 (UI redesign): text hierarchy tokens must map to neutral colors —
/// never the teal accent — in both theme modes.
void main() {
  const accent = Color(0xFF5EEAD4);

  tearDown(() => LedgerTheme.setDark(true));

  group('LedgerTheme text hierarchy', () {
    test('displayLarge uses primary text color in dark mode', () {
      LedgerTheme.setDark(true);
      expect(LedgerTheme.displayLarge.color, const Color(0xFFF2F5F3));
    });

    test('displayLarge uses primary text color in light mode', () {
      LedgerTheme.setDark(false);
      expect(LedgerTheme.displayLarge.color, const Color(0xFF141817));
    });

    test('headlineMedium uses primary text color in both modes', () {
      LedgerTheme.setDark(true);
      expect(LedgerTheme.headlineMedium.color, const Color(0xFFF2F5F3));
      LedgerTheme.setDark(false);
      expect(LedgerTheme.headlineMedium.color, const Color(0xFF141817));
    });

    test('bodyLarge uses primary text color in both modes', () {
      LedgerTheme.setDark(true);
      expect(LedgerTheme.bodyLarge.color, const Color(0xFFF2F5F3));
      LedgerTheme.setDark(false);
      expect(LedgerTheme.bodyLarge.color, const Color(0xFF141817));
    });

    test('bodyMedium uses primary text color in both modes', () {
      LedgerTheme.setDark(true);
      expect(LedgerTheme.bodyMedium.color, const Color(0xFFF2F5F3));
      LedgerTheme.setDark(false);
      expect(LedgerTheme.bodyMedium.color, const Color(0xFF141817));
    });

    test('caption uses muted color in both modes', () {
      LedgerTheme.setDark(true);
      expect(LedgerTheme.caption.color, const Color(0xFFA8B3AD));
      LedgerTheme.setDark(false);
      expect(LedgerTheme.caption.color, const Color(0xFF5C6663));
    });

    test('no hierarchy style uses the accent color', () {
      for (final dark in [true, false]) {
        LedgerTheme.setDark(dark);
        for (final style in [
          LedgerTheme.displayLarge,
          LedgerTheme.headlineMedium,
          LedgerTheme.bodyLarge,
          LedgerTheme.bodyMedium,
          LedgerTheme.caption,
        ]) {
          expect(style.color, isNot(accent),
              reason: 'dark=$dark memakai warna accent');
        }
      }
    });

    test('displayLarge uses tabular figures for aligned numerals', () {
      expect(
        LedgerTheme.displayLarge.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });

    test('hierarchy sizes are ordered display > headline > body > caption',
        () {
      final sizes = [
        LedgerTheme.displayLarge.fontSize!,
        LedgerTheme.headlineMedium.fontSize!,
        LedgerTheme.bodyLarge.fontSize!,
        LedgerTheme.bodyMedium.fontSize!,
        LedgerTheme.caption.fontSize!,
      ];
      for (var i = 0; i < sizes.length - 1; i++) {
        expect(sizes[i], greaterThan(sizes[i + 1]),
            reason: 'ukuran tidak menurun pada indeks $i');
      }
    });
  });
}
