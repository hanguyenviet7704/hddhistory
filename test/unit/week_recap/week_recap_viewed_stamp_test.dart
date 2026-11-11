import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hddhistory/hddhistory.dart';

/// Who records that the week was READ.
///
/// `viewedAt` is the only stamp that ends the Monday popup for good, and the
/// popup re-offers on the first open of every day until it is written. So every
/// way of actually opening the poster has to write it — otherwise a reader who
/// opened their week from the Library banner is offered it again tomorrow, and
/// the "MỚI" pill (which keys off the same stamp) never goes out either.
///
/// Pinned at the cubit rather than at each call site: the banner, the Monday
/// popup, a deeplink and Sổ tay all funnel through `openRecap`/`openRecapById`,
/// and a fifth entry point added later must not have to remember this.
class _FakeWeekRecapRepository implements IWeekRecapRepository {
  _FakeWeekRecapRepository(this.recap);

  WeekRecapEntity? recap;

  /// Every id the cubit reported as viewed, in order.
  final List<String> viewed = <String>[];
  final List<String> dismissed = <String>[];

  @override
  TaskEither<AppException, CurrentWeekRecapEntity> getCurrent({required int tzOffset}) =>
      TaskEither.right(CurrentWeekRecapEntity(recap: recap, archiveCount: 1));

  @override
  TaskEither<AppException, BasePageBreak<WeekRecapSummaryEntity>> getArchive({
    required int page,
    required int take,
  }) => TaskEither.right(const BasePageBreak<WeekRecapSummaryEntity>());

  @override
  TaskEither<AppException, WeekRecapEntity> getById(String id) => TaskEither.right(_weekRecap(id: id));

  @override
  TaskEither<AppException, Unit> markInteracted({required String id, required bool viewed}) {
    (viewed ? this.viewed : dismissed).add(id);

    return TaskEither.right(unit);
  }
}

WeekRecapEntity _weekRecap({String id = 'w1', DateTime? viewedAt}) {
  final monday = DateTime(2026, 8, 24);

  return WeekRecapEntity(
    id: id,
    weekNumber: 2,
    weekStart: monday,
    weekEnd: monday.add(const Duration(days: 7)),
    viewedAt: viewedAt,
  );
}

WeekRecapCubit _cubit(_FakeWeekRecapRepository repository) => WeekRecapCubit(
  GetCurrentWeekRecapUseCase(repository),
  GetWeekRecapArchiveUseCase(repository),
  GetWeekRecapUseCase(repository),
  MarkWeekRecapInteractedUseCase(repository),
);

void main() {
  group('opening the current week records it as viewed', () {
    test('from the Library banner, which hands the recap straight in', () async {
      final repository = _FakeWeekRecapRepository(_weekRecap());
      final cubit = _cubit(repository);
      await cubit.loadCurrent();

      cubit.openRecap(cubit.state.current!);
      await Future<void>.delayed(Duration.zero);

      expect(repository.viewed, <String>['w1']);
      expect(cubit.state.current?.viewedAt, isNotNull, reason: 'the pill must go out at once');
      await cubit.close();
    });

    test('from a deeplink, which arrives with only the id', () async {
      final repository = _FakeWeekRecapRepository(_weekRecap());
      final cubit = _cubit(repository);
      await cubit.loadCurrent();

      await cubit.openRecapById('w1');
      await Future<void>.delayed(Duration.zero);

      expect(repository.viewed, <String>['w1']);
      await cubit.close();
    });

    test('but an older week out of Sổ tay leaves this week unanswered', () async {
      final repository = _FakeWeekRecapRepository(_weekRecap());
      final cubit = _cubit(repository);
      await cubit.loadCurrent();

      await cubit.openRecapById('older-week');
      await Future<void>.delayed(Duration.zero);

      expect(repository.viewed, isEmpty);
      expect(cubit.state.current?.viewedAt, isNull);
      await cubit.close();
    });

    test('and a week already viewed is not stamped a second time', () async {
      final repository = _FakeWeekRecapRepository(_weekRecap(viewedAt: DateTime(2026, 9, 1)));
      final cubit = _cubit(repository);
      await cubit.loadCurrent();

      cubit.openRecap(cubit.state.current!);
      await Future<void>.delayed(Duration.zero);

      expect(repository.viewed, isEmpty);
      await cubit.close();
    });
  });
}
