part of '../../community.dart';

@lazySingleton
class SetCommunityReactionUseCase {
  final ICommunityRepository _repository;

  SetCommunityReactionUseCase(this._repository);

  TaskEither<AppException, Unit> call({
    required CommunityTargetType targetType,
    required String targetId,
    required CommunityReactionKind kind,
    required bool active,
  }) {
    return _repository.setReaction(
      targetType: targetType,
      targetId: targetId,
      kind: kind,
      active: active,
    );
  }
}

/// "Ẩn nội dung này" — for this reader only. Not a report: nothing is flagged
/// for the team and the item stays up for everyone else.
@lazySingleton
class HideCommunityItemUseCase {
  final ICommunityRepository _repository;

  HideCommunityItemUseCase(this._repository);

  TaskEither<AppException, Unit> call({
    required CommunityTargetType targetType,
    required String targetId,
  }) {
    return _repository.hideItem(targetType: targetType, targetId: targetId);
  }
}

@lazySingleton
class ReportCommunityItemUseCase {
  final ICommunityRepository _repository;

  ReportCommunityItemUseCase(this._repository);

  TaskEither<AppException, Unit> call({
    required CommunityTargetType targetType,
    required String targetId,
    required CommunityReportReason reason,
    String? note,
  }) {
    return _repository.report(
      targetType: targetType,
      targetId: targetId,
      reason: reason,
      note: note,
    );
  }
}
