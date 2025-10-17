part of '../base.dart';

@JsonSerializable(createFactory: false)
@Freezed(genericArgumentFactories: true)
sealed class PageBreakRequest with _$PageBreakRequest {
  const factory PageBreakRequest({
    @Default(1) int page,
    @Default(10) int limit,
    @Default('createdAt') String orderBy,
    @Default(PageBreakOrder.asc) PageBreakOrder order,
    @Default('') String? search,
  }) = _PageBreakRequest;

  factory PageBreakRequest.fromJson(Map<String, dynamic> json) => _$PageBreakRequestFromJson(json);
}

enum PageBreakOrder {
  asc('asc'),
  desc('desc');

  final String name;
  const PageBreakOrder(this.name);
}
