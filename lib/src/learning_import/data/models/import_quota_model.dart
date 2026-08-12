part of '../../learning_import.dart';

@freezed
abstract class ImportQuotaModel with _$ImportQuotaModel {
  const factory ImportQuotaModel({
    @Default(0) int limit,
    @Default(0) int used,
    @Default(0) int remaining,
    String? resetsAt,
    @Default(false) bool isPremium,
    @Default(0) int premiumLimit,
  }) = _ImportQuotaModel;

  factory ImportQuotaModel.fromJson(Map<String, dynamic> json) =>
      _$ImportQuotaModelFromJson(json);
}

extension ImportQuotaModelX on ImportQuotaModel {
  ImportQuotaEntity toEntity() => ImportQuotaEntity(
    limit: limit,
    used: used,
    remaining: remaining,
    resetsAt: DateTime.tryParse(resetsAt ?? ''),
    isPremium: isPremium,
    // Older servers do not send it. Falling back to `limit` keeps the upsell
    // line grammatical ("Premium gives you N every week") instead of quoting a
    // zero, and on a premium reader the two are the same number anyway.
    premiumLimit: premiumLimit > 0 ? premiumLimit : limit,
  );
}
