part of '../base.dart';

@Freezed(toJson: false, fromJson: false)
abstract class PageBreakRequestV2<T> with _$PageBreakRequestV2<T> {
  const factory PageBreakRequestV2({
    @Default(1) int page,
    @JsonKey(name: 'take') @Default(10) int limit,
    @JsonKey(name: 'orderBy') @Default('createdAt') String orderBy,
    @JsonKey(name: 'order') @Default(PageBreakOrder.asc) PageBreakOrder order,
    @JsonKey(name: 'search') String? search,
    T? filter,
  }) = _PageBreakRequestV2;

  static const reservedKeys = {'page', 'take', 'orderBy', 'order', 'search'};

  factory PageBreakRequestV2.fromJson(
    Map<String, dynamic> json,
    T? Function(Map<String, dynamic>)? filterFromJson,
  ) {
    final page = json['page'] as int? ?? 1;
    final limit = json['take'] as int? ?? 10;
    final orderBy = json['orderBy'] as String? ?? 'createdAt';
    final orderValue = json['order'] as String? ?? 'asc';
    final order = orderValue == 'desc' ? PageBreakOrder.desc : PageBreakOrder.asc;
    final search = json['search'] as String?;

    T? filter;
    if (filterFromJson != null) {
      final filterJson = Map<String, dynamic>.from(json)..removeWhere((key, value) => reservedKeys.contains(key));
      if (filterJson.isNotEmpty) {
        filter = filterFromJson(filterJson);
      }
    }

    return PageBreakRequestV2<T>(
      page: page,
      limit: limit,
      orderBy: orderBy,
      order: order,
      search: search,
      filter: filter,
    );
  }
}

extension PageBreakRequestV2Extension<T> on PageBreakRequestV2<T> {
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'page': page,
      'take': limit,
      'orderBy': orderBy,
      'order': order.name,
    };

    if (search != null && search!.isNotEmpty) {
      json['search'] = search;
    }

    if (filter == null) return json;

    try {
      final filterJson = (filter as dynamic).toJson() as Map<String, dynamic>;

      for (final entry in filterJson.entries) {
        if (PageBreakRequestV2.reservedKeys.contains(entry.key)) {
          throw ArgumentError(
            'Filter field "${entry.key}" conflicts with PageBreakRequest reserved fields: ${PageBreakRequestV2.reservedKeys}',
          );
        }
        if (entry.value == null) continue;
        json[entry.key] = entry.value;
      }
    } catch (e) {
      if (e is ArgumentError) rethrow;
      throw ArgumentError(
        'Filter type ${filter.runtimeType} must have a toJson() method that returns Map<String, dynamic>',
      );
    }

    return json;
  }
}

enum PageBreakOrder {
  asc('asc'),
  desc('desc');

  final String name;
  const PageBreakOrder(this.name);
}
