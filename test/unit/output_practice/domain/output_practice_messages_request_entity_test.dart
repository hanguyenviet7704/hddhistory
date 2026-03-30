import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  test('OutputPracticeMessagesRequestEntity serializes conversation scoped queries', () {
    const request = OutputPracticeMessagesRequestEntity(
      conversationId: 'conversation-1',
      page: 2,
      take: 20,
      orderBy: 'createdAt',
      order: PageBreakOrder.desc,
    );

    expect(request.toJson(), {
      'conversationId': 'conversation-1',
      'page': 2,
      'take': 20,
      'orderBy': 'createdAt',
      'order': 'desc',
    });
  });
}
