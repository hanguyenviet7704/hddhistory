part of '../../lesson.dart';

@freezed
abstract class KeypointQuotaModel with _$KeypointQuotaModel {
  const factory KeypointQuotaModel({
    @Default(0) int limit,
    @Default(0) int used,
    @Default(0) int remaining,
    String? claimedKeypointId,
  }) = _KeypointQuotaModel;

  factory KeypointQuotaModel.fromJson(Map<String, dynamic> json) => _$KeypointQuotaModelFromJson(json);
}

@freezed
abstract class KeypointAccessModel with _$KeypointAccessModel {
  const factory KeypointAccessModel({
    // NULL means "no limit", which is a different statement from 0 ("nothing
    // readable"). Both are real answers, so this cannot default.
    int? cardCap,
    String? reason,
    KeypointQuotaModel? quota,
  }) = _KeypointAccessModel;

  factory KeypointAccessModel.fromJson(Map<String, dynamic> json) => _$KeypointAccessModelFromJson(json);
}

@freezed
abstract class KeypointClaimModel with _$KeypointClaimModel {
  const factory KeypointClaimModel({
    @Default(false) bool granted,
    int? cardCap,
    String? reason,
    String? claimedKeypointId,
  }) = _KeypointClaimModel;

  factory KeypointClaimModel.fromJson(Map<String, dynamic> json) => _$KeypointClaimModelFromJson(json);
}

extension KeypointQuotaModelX on KeypointQuotaModel {
  KeypointQuotaEntity toEntity() => KeypointQuotaEntity(
        limit: limit,
        used: used,
        remaining: remaining,
        claimedKeypointId: claimedKeypointId,
      );
}

extension KeypointAccessModelX on KeypointAccessModel {
  KeypointAccessEntity toEntity() => KeypointAccessEntity(
        cardCap: cardCap,
        reason: KeypointAccessReason.fromWire(reason),
        quota: quota?.toEntity(),
      );
}

extension KeypointClaimModelX on KeypointClaimModel {
  KeypointClaimEntity toEntity() => KeypointClaimEntity(
        granted: granted,
        cardCap: cardCap,
        reason: KeypointAccessReason.fromWire(reason),
        claimedKeypointId: claimedKeypointId,
      );
}
