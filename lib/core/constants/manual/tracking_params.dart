part of '../constants.dart';

mixin TrackingParams {
  static const String clickBack = 'click_back';
  static const String outApp = 'out_app';
  static const String keepDrawing = 'keep_drawing';
  static const String exit = 'exit';

  static Map<String, dynamic> withDrawTopic() {
    return {
      'draw_topic': '',
    };
  }

  static Map<String, dynamic> withDrawTopicContext(BuildContext context) {
    return {
      'draw_topic': '',
    };
  }

  static Map<String, dynamic> withLessonId() {
    return {
      'lesson_id': '',
    };
  }

  static Map<String, dynamic> withTimeSpent(BuildContext context) {
    return {
      'time_spent': '',
    };
  }

  static Map<String, dynamic> withPaywallSource(BuildContext context) {
    String source = context.read<PaywallCubit>().state.paywallSource;
    return {
      'paywall_source': source,
    };
  }

  static Map<String, dynamic> withDrawTopicLessonId() {
    return {
      ...withDrawTopic(),
      ...withLessonId(),
    };
  }

  static Map<String, dynamic> withDrawTopicLessonIdTimeSpent(BuildContext context) {
    return {
      ...withDrawTopicLessonId(),
      ...withTimeSpent(context),
    };
  }

  static Map<String, dynamic> trackingUserState(BuildContext context) {
    String isPremium = context.read<PaywallCubit>().state.isPremiumUser ? 'premium' : 'non_premium';
    return {
      'user_state': isPremium,
    };
  }
}
