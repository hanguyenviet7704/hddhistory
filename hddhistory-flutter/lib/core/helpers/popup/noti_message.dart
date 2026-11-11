part of '../helpers.dart';

mixin DNotiMessage {
  static void featureInDevelopment() {
    DMessage.showMessage(
      message: 'featureInDevelopment',
      type: MessageType.info,
    );
  }
}
