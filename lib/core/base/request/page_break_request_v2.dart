part of '../base.dart';

// abstract class JsonConvertible {
//   Map<String, dynamic> toJson();
// }

// @Freezed(toJson: false, fromJson: false, genericArgumentFactories: true)
// abstract class PageBreakRequestV2<T extends JsonConvertible?> with _$PageBreakRequestV2<T> {
//   const PageBreakRequestV2._();

//   const factory PageBreakRequestV2({
//     @Default(1) int page,
//     @JsonKey(name: 'take') @Default(10) int limit,
//     @JsonKey(name: 'orderBy') @Default('createdAt') String orderBy,
//     @JsonKey(name: 'order') @Default(PageBreakOrder.asc) PageBreakOrder order,
//     @JsonKey(name: 'search') String? search,
//     T? filter,
//   }) = _PageBreakRequestV2<T>;

//   static const _reservedKeys = {'page', 'take', 'orderBy', 'order', 'search'};

//   Map<String, dynamic> toJson() {
//     final json = <String, dynamic>{
//       'page': page,
//       'take': limit,
//       'orderBy': orderBy,
//       'order': order.name,
//     };

//     if (search != null && search!.isNotEmpty) {
//       json['search'] = search;
//     }

//     if (filter == null) return json;

//     final filterJson = filter!.toJson();
//     for (final entry in filterJson.entries) {
//       if (_reservedKeys.contains(entry.key)) {
//         throw ArgumentError(
//           'Filter field "${entry.key}" conflicts with PageBreakRequestV2 reserved fields: $_reservedKeys',
//         );
//       }
//       if (entry.value != null) {
//         json[entry.key] = entry.value;
//       }
//     }

//     return json;
//   }

//   factory PageBreakRequestV2.fromJsonWithFilter(
//     Map<String, dynamic> json,
//     T? Function(Map<String, dynamic>)? filterFromJson,
//   ) {
//     final page = json['page'] as int? ?? 1;
//     final limit = json['take'] as int? ?? 10;
//     final orderBy = json['orderBy'] as String? ?? 'createdAt';
//     final orderValue = json['order'] as String? ?? 'asc';
//     final order = orderValue == 'desc' ? PageBreakOrder.desc : PageBreakOrder.asc;
//     final search = json['search'] as String?;

//     T? filter;
//     if (filterFromJson != null) {
//       final filterJson = Map<String, dynamic>.from(json)..removeWhere((key, value) => _reservedKeys.contains(key));
//       if (filterJson.isNotEmpty) {
//         filter = filterFromJson(filterJson);
//       }
//     }

//     return PageBreakRequestV2<T>(
//       page: page,
//       limit: limit,
//       orderBy: orderBy,
//       order: order,
//       search: search,
//       filter: filter,
//     );
//   }
// }
