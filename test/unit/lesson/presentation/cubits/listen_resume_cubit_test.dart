import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

class _InMemoryHydratedStorage implements Storage {
  final Map<String, dynamic> _storage = <String, dynamic>{};

  @override
  dynamic read(String key) => _storage[key];

  @override
  Future<void> write(String key, dynamic value) async {
    _storage[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _storage.remove(key);
  }

  @override
  Future<void> clear() async {
    _storage.clear();
  }

  @override
  Future<void> close() async {}
}

void main() {
  setUpAll(() {
    HydratedBloc.storage = _InMemoryHydratedStorage();
  });

  test('recordFor returns the stored position for the same keypoint only', () {
    final cubit = ListenResumeCubit();
    cubit.record(keypointId: 'kp1', positionMs: 42000);
    expect(cubit.recordFor('kp1')?.positionMs, 42000);
    expect(cubit.recordFor('kp2'), isNull);
  });

  test('clear wipes only a matching keypoint', () {
    final cubit = ListenResumeCubit();
    cubit.record(keypointId: 'kp1', positionMs: 42000);
    cubit.clearFor('other'); // no-op
    expect(cubit.recordFor('kp1'), isNotNull);
    cubit.clearFor('kp1');
    expect(cubit.recordFor('kp1'), isNull);
  });

  test('a record older than 7 days is not offered', () {
    final cubit = ListenResumeCubit();
    cubit.record(keypointId: 'kp1', positionMs: 1000);
    cubit.emitForTest(
      cubit.state.copyWith(
        updatedAtMillis: DateTime.now().subtract(const Duration(days: 8)).millisecondsSinceEpoch,
      ),
    );
    expect(cubit.recordFor('kp1'), isNull);
  });

  test('an empty keypoint id is never recorded', () {
    final cubit = ListenResumeCubit();
    cubit.record(keypointId: '', positionMs: 9000);
    expect(cubit.recordFor(''), isNull);
  });
}
