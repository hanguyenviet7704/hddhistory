part of '../base.dart';

@freezed
sealed class PageBreakRequest with _$PageBreakRequest {
  const factory PageBreakRequest({
    @Default(1) int page,
    @JsonKey(name: 'take') @Default(10) int limit,
    @JsonKey(name: 'orderBy') @Default('createdAt') String orderBy,
    @JsonKey(name: 'order') @Default(PageBreakOrder.asc) PageBreakOrder order,
    @JsonKey(name: 'search') String? search,
  }) = _PageBreakRequest;

  factory PageBreakRequest.fromJson(Map<String, dynamic> json) => _$PageBreakRequestFromJson(json);
}

enum PageBreakOrder {
  asc('asc'),
  desc('desc');

  final String name;
  const PageBreakOrder(this.name);
}
