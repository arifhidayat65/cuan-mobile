import 'package:cuan_mobile/core/widgets/error_state_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('menampilkan pesan error dan tombol Coba lagi',
      (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorStateCard(
            message: 'Tidak bisa terhubung ke server.',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('Tidak bisa terhubung ke server.'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);

    await tester.tap(find.text('Coba lagi'));
    expect(retried, isTrue);
  });

  testWidgets('judul "Gagal memuat data" selalu tampil', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ErrorStateCard(message: 'x', onRetry: _noop),
        ),
      ),
    );

    expect(find.text('Gagal memuat data'), findsOneWidget);
  });
}

void _noop() {}
