import 'package:cuan_mobile/features/debts/data/debt_repository.dart';
import 'package:cuan_mobile/features/splitbill/bloc/split_bill_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake repo capturing the create payload.
class _FakeDebtRepo extends DebtRepository {
  Map<String, dynamic>? lastPayload;
  Object? errorToThrow;
  int createCalls = 0;

  @override
  Future<void> create({
    required String type,
    required String personName,
    required String amount,
    String? description,
    String? dueDate,
  }) async {
    createCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    lastPayload = {
      'type': type,
      'personName': personName,
      'amount': amount,
      if (description != null) 'description': description,
    };
  }
}

SplitBillCubit _cubitWith({
  required String total,
  required String people,
  double tax = 0,
  double tip = 0,
  _FakeDebtRepo? repo,
}) {
  final c = SplitBillCubit(debtRepository: repo);
  c.setTotal(total);
  c.setPeople(people);
  c.setTax(tax);
  c.setTip(tip);
  return c;
}

void main() {
  group('receivableAmount', () {
    test('3 orang, tanpa pajak/tip: 2 bagian untuk saya', () {
      final c = _cubitWith(total: '300000', people: '3');
      expect(c.state.perPerson, 100000);
      expect(c.receivableAmount, 200000);
      c.close();
    });

    test('memperhitungkan pajak dan tip', () {
      final c = _cubitWith(total: '100000', people: '2', tax: 10);
      // grandTotal 110000, perPerson 55000, 1 orang lain berutang
      expect(c.receivableAmount, 55000);
      c.close();
    });

    test('1 orang: tidak ada piutang', () {
      final c = _cubitWith(total: '100000', people: '1');
      expect(c.receivableAmount, 0);
      c.close();
    });
  });

  group('buildDescription', () {
    test('memuat rincian perhitungan', () {
      final c = _cubitWith(total: '300000', people: '3', tax: 10, tip: 5);
      final d = c.buildDescription();
      expect(d, contains('3 orang'));
      expect(d, contains('Pajak 10%'));
      expect(d, contains('Tip 5%'));
      c.close();
    });
  });

  group('save', () {
    test('menyimpan sebagai piutang dengan payload benar', () async {
      final repo = _FakeDebtRepo();
      final c = _cubitWith(total: '300000', people: '3', repo: repo);
      final ok = await c.save(label: 'Makan bareng');
      expect(ok, isTrue);
      expect(repo.createCalls, 1);
      expect(repo.lastPayload!['type'], 'piutang');
      expect(repo.lastPayload!['personName'], contains('Makan bareng'));
      expect(repo.lastPayload!['amount'], '200000');
      expect(repo.lastPayload!['description'], isNotNull);
      expect(c.state.saving, isFalse);
      expect(c.state.saveError, isNull);
      c.close();
    });

    test('gagal simpan: return false + saveError terisi, repo tetap dipanggil', () async {
      final repo = _FakeDebtRepo()..errorToThrow = Exception('boom');
      final c = _cubitWith(total: '300000', people: '3', repo: repo);
      final ok = await c.save(label: 'Makan bareng');
      expect(ok, isFalse);
      expect(c.state.saveError, isNotNull);
      expect(c.state.saving, isFalse);
      c.close();
    });

    test('tidak menyimpan jika tidak ada piutang (1 orang)', () async {
      final repo = _FakeDebtRepo();
      final c = _cubitWith(total: '100000', people: '1', repo: repo);
      final ok = await c.save(label: 'Sendiri');
      expect(ok, isFalse);
      expect(repo.createCalls, 0);
      c.close();
    });

    test('label kosong: pakai default', () async {
      final repo = _FakeDebtRepo();
      final c = _cubitWith(total: '300000', people: '3', repo: repo);
      await c.save(label: '   ');
      expect(repo.lastPayload!['personName'], contains('Patungan'));
      c.close();
    });
  });
}
