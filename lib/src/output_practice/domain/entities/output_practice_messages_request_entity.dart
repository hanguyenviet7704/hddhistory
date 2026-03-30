part of '../../output_practice.dart';

class OutputPracticeMessagesRequestEntity implements JsonRequestConvertible {
  const OutputPracticeMessagesRequestEntity({
    required this.conversationId,
    this.page = 1,
    this.take = 10,
    this.orderBy = 'createdAt',
    this.order = PageBreakOrder.desc,
  });

  final String conversationId;
  final int page;
  final int take;
  final String orderBy;
  final PageBreakOrder order;

  OutputPracticeMessagesRequestEntity copyWith({
    String? conversationId,
    int? page,
    int? take,
    String? orderBy,
    PageBreakOrder? order,
  }) {
    return OutputPracticeMessagesRequestEntity(
      conversationId: conversationId ?? this.conversationId,
      page: page ?? this.page,
      take: take ?? this.take,
      orderBy: orderBy ?? this.orderBy,
      order: order ?? this.order,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'conversationId': conversationId,
      'page': page,
      'take': take,
      'orderBy': orderBy,
      'order': order.name,
    };
  }
}
