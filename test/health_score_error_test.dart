import 'package:cuan_mobile/features/home/bloc/health_score_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HealthScoreCubit error state', () {
    test('gagal load: errorMessage terisi, bukan hilang diam-diam', () async {
      final cubit = HealthScoreCubit(
        fetchHealthScore: (_) async => throw Exception('boom'),
      );
      await cubit.load();
      expect(cubit.state.loading, isFalse);
      expect(cubit.state.data, isNull);
      expect(cubit.state.errorMessage, isNotNull);
      expect(cubit.state.errorMessage, isNotEmpty);
      await cubit.close();
    });

    test('retry setelah gagal lalu sukses: errorMessage bersih', () async {
      var calls = 0;
      final cubit = HealthScoreCubit(
        fetchHealthScore: (_) async {
          calls++;
          if (calls == 1) throw Exception('boom');
          return {'score': 80, 'grade': 'B', 'tips': <String>[]};
        },
      );
      await cubit.load();
      expect(cubit.state.errorMessage, isNotNull);
      await cubit.load();
      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.data?['score'], 80);
      await cubit.close();
    });

    test('sukses: tidak ada errorMessage', () async {
      final cubit = HealthScoreCubit(
        fetchHealthScore: (_) async =>
            {'score': 90, 'grade': 'A', 'tips': <String>[]},
      );
      await cubit.load();
      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.data?['grade'], 'A');
      await cubit.close();
    });
  });
}
