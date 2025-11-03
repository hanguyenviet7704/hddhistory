part of '../base.dart';

abstract interface class JsonRequestConvertible {
  Map<String, dynamic> toJson();
}

@Freezed(toJson: false, fromJson: false, genericArgumentFactories: true)
abstract class PageBreakRequest<T extends JsonRequestConvertible> with _$PageBreakRequest<T> {
  const PageBreakRequest._();

  const factory PageBreakRequest({
    @Default(1) int page,
    @JsonKey(name: 'take') @Default(10) int limit,
    @JsonKey(name: 'orderBy') @Default('createdAt') String orderBy,
    @JsonKey(name: 'order') @Default(PageBreakOrder.asc) PageBreakOrder order,
    @JsonKey(name: 'search') String? search,
    T? filter,
  }) = _PageBreakRequest<T>;

  static const _reservedKeys = {'page', 'take', 'orderBy', 'order', 'search'};

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

    final filterJson = filter!.toJson();
    for (final entry in filterJson.entries) {
      if (_reservedKeys.contains(entry.key)) {
        throw ArgumentError(
          'Filter field "${entry.key}" conflicts with PageBreakRequest reserved fields: $_reservedKeys',
        );
      }

      if (entry.value == null) continue;
      json[entry.key] = entry.value;
    }

    return json;
  }

  factory PageBreakRequest.fromJson(
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
      final filterJson = Map<String, dynamic>.from(json)..removeWhere((key, value) => _reservedKeys.contains(key));
      if (filterJson.isNotEmpty) {
        filter = filterFromJson(filterJson);
      }
    }

    return PageBreakRequest<T>(
      page: page,
      limit: limit,
      orderBy: orderBy,
      order: order,
      search: search,
      filter: filter,
    );
  }
}
