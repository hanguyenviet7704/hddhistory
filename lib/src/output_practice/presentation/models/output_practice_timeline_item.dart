part of '../../output_practice.dart';

enum OutputPracticeDeliveryStatus { confirmed, sending, failed }

enum OutputPracticeTimelineAuthor { assistant, user }

class OutputPracticeTimelineItem {
  const OutputPracticeTimelineItem({
    required this.id,
    required this.author,
    required this.content,
    this.deliveryStatus = OutputPracticeDeliveryStatus.confirmed,
    this.isStreaming = false,
  });

  final String id;
  final OutputPracticeTimelineAuthor author;
  final String content;
  final OutputPracticeDeliveryStatus deliveryStatus;
  final bool isStreaming;

  bool get isUser => author == OutputPracticeTimelineAuthor.user;

  bool get isAssistant => author == OutputPracticeTimelineAuthor.assistant;

  OutputPracticeTimelineItem copyWith({
    String? id,
    OutputPracticeTimelineAuthor? author,
    String? content,
    OutputPracticeDeliveryStatus? deliveryStatus,
    bool? isStreaming,
  }) {
    return OutputPracticeTimelineItem(
      id: id ?? this.id,
      author: author ?? this.author,
      content: content ?? this.content,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  factory OutputPracticeTimelineItem.assistant({
    required String id,
    required String content,
    bool isStreaming = false,
  }) {
    return OutputPracticeTimelineItem(
      id: id,
      author: OutputPracticeTimelineAuthor.assistant,
      content: content,
      isStreaming: isStreaming,
    );
  }

  factory OutputPracticeTimelineItem.user({
    required String id,
    required String content,
    OutputPracticeDeliveryStatus deliveryStatus = OutputPracticeDeliveryStatus.confirmed,
  }) {
    return OutputPracticeTimelineItem(
      id: id,
      author: OutputPracticeTimelineAuthor.user,
      content: content,
      deliveryStatus: deliveryStatus,
    );
  }
}
