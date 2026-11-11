part of '../../output_practice.dart';

enum OutputPracticeDeliveryStatus { confirmed, sending, failed }

enum OutputPracticeTimelineAuthor { assistant, user }

class OutputPracticeTimelineItem {
  const OutputPracticeTimelineItem({
    required this.id,
    required this.author,
    required this.content,
    this.deliveryStatus = OutputPracticeDeliveryStatus.confirmed,
    this.messageType = OutputPracticeMessageType.unknown,
    this.serverSeq,
    this.isStreaming = false,
  });

  final String id;
  final OutputPracticeTimelineAuthor author;
  final String content;
  final OutputPracticeDeliveryStatus deliveryStatus;
  final OutputPracticeMessageType messageType;
  final int? serverSeq;
  final bool isStreaming;

  bool get isUser => author == OutputPracticeTimelineAuthor.user;

  bool get isAssistant => author == OutputPracticeTimelineAuthor.assistant;

  OutputPracticeTimelineItem copyWith({
    String? id,
    OutputPracticeTimelineAuthor? author,
    String? content,
    OutputPracticeDeliveryStatus? deliveryStatus,
    OutputPracticeMessageType? messageType,
    int? serverSeq,
    bool? isStreaming,
  }) {
    return OutputPracticeTimelineItem(
      id: id ?? this.id,
      author: author ?? this.author,
      content: content ?? this.content,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      messageType: messageType ?? this.messageType,
      serverSeq: serverSeq ?? this.serverSeq,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  factory OutputPracticeTimelineItem.assistant({
    required String id,
    required String content,
    OutputPracticeMessageType messageType = OutputPracticeMessageType.message,
    int? serverSeq,
    bool isStreaming = false,
  }) {
    return OutputPracticeTimelineItem(
      id: id,
      author: OutputPracticeTimelineAuthor.assistant,
      content: content,
      messageType: messageType,
      serverSeq: serverSeq,
      isStreaming: isStreaming,
    );
  }

  factory OutputPracticeTimelineItem.user({
    required String id,
    required String content,
    OutputPracticeDeliveryStatus deliveryStatus = OutputPracticeDeliveryStatus.confirmed,
    OutputPracticeMessageType messageType = OutputPracticeMessageType.message,
    int? serverSeq,
  }) {
    return OutputPracticeTimelineItem(
      id: id,
      author: OutputPracticeTimelineAuthor.user,
      content: content,
      deliveryStatus: deliveryStatus,
      messageType: messageType,
      serverSeq: serverSeq,
    );
  }
}
