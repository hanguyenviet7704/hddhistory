import 'dart:convert';

import '../constants/notification_constants.dart';
import '../notification_core_config.dart';

class NotificationMessageRouter {
  const NotificationMessageRouter();

  NotificationPayload fromRemoteMessage(
    TransportRemoteMessage message, {
    required NotificationCoreConfig config,
  }) {
    final raw = Map<String, dynamic>.from(message.data);

    if (message.title?.trim().isNotEmpty ?? false) {
      raw.putIfAbsent(NotificationConstants.payloadTitleKey, () => message.title);
    }
    if (message.body?.trim().isNotEmpty ?? false) {
      raw.putIfAbsent(NotificationConstants.payloadBodyKey, () => message.body);
    }
    if (message.messageId?.isNotEmpty ?? false) {
      raw.putIfAbsent(NotificationConstants.payloadMessageIdKey, () => message.messageId);
    }

    return _buildPayload(
      raw: _normalizeRawPayload(raw),
      source: NotificationPayloadSource.remote,
      config: config,
      sourceId: message.messageId,
    );
  }

  NotificationPayload fromLocalAction(
    TransportLocalAction action, {
    required NotificationCoreConfig config,
  }) {
    final raw = action.payload.map((key, value) => MapEntry(key, value));

    if (action.title?.trim().isNotEmpty ?? false) {
      raw.putIfAbsent(NotificationConstants.payloadTitleKey, () => action.title!);
    }
    if (action.body?.trim().isNotEmpty ?? false) {
      raw.putIfAbsent(NotificationConstants.payloadBodyKey, () => action.body!);
    }

    return _buildPayload(
      raw: _normalizeRawPayload(raw),
      source: NotificationPayloadSource.local,
      config: config,
      sourceId: action.id.toString(),
    );
  }

  NotificationRequest toLocalRequest(NotificationPayload payload, {int? id}) {
    final requestPayload = <String, String>{};
    for (final entry in payload.raw.entries) {
      if (entry.value != null) {
        requestPayload[entry.key] = entry.value.toString();
      }
    }

    if ((payload.type?.trim().isNotEmpty ?? false)) {
      requestPayload[NotificationConstants.payloadTypeKey] = payload.type!;
    }
    if (payload.title.trim().isNotEmpty) {
      requestPayload[NotificationConstants.payloadTitleKey] = payload.title;
    }
    if (payload.body.trim().isNotEmpty) {
      requestPayload[NotificationConstants.payloadBodyKey] = payload.body;
    }
    if ((payload.deeplink?.trim().isNotEmpty ?? false)) {
      requestPayload[NotificationConstants.payloadDeeplinkKey] = payload.deeplink!;
    }
    if ((payload.entityId?.trim().isNotEmpty ?? false)) {
      requestPayload[NotificationConstants.payloadEntityIdKey] = payload.entityId!;
    }
    if ((payload.imageUrl?.trim().isNotEmpty ?? false)) {
      requestPayload[NotificationConstants.payloadImageUrlKey] = payload.imageUrl!;
    }
    if ((payload.sourceId?.trim().isNotEmpty ?? false)) {
      requestPayload[NotificationConstants.payloadMessageIdKey] = payload.sourceId!;
    }
    requestPayload[NotificationConstants.payloadSourceKey] = payload.source.name;

    return NotificationRequest(
      id: id ?? _tryParseInt(payload.sourceId),
      title: payload.title.isNotEmpty ? payload.title : NotificationConstants.defaultTitle,
      body: payload.body.isNotEmpty ? payload.body : NotificationConstants.defaultBody,
      imageUrl: payload.imageUrl,
      payload: requestPayload,
    );
  }

  NotificationPayload _buildPayload({
    required Map<String, dynamic> raw,
    required NotificationPayloadSource source,
    required NotificationCoreConfig config,
    required String? sourceId,
  }) {
    final defaultPayload = NotificationPayload(
      source: source,
      raw: raw,
      sourceId: sourceId,
      type: _readFirstString(raw, <String>[NotificationConstants.payloadTypeKey]),
      title: _readFirstString(raw, <String>[NotificationConstants.payloadTitleKey]) ?? '',
      body: _readFirstString(raw, <String>[NotificationConstants.payloadBodyKey]) ?? '',
      deeplink: _readFirstString(
        raw,
        <String>[
          NotificationConstants.payloadDeeplinkKey,
          NotificationConstants.payloadDeepLinkKey,
          NotificationConstants.payloadNavigateKey,
        ],
      ),
      entityId: _readFirstString(raw, <String>[NotificationConstants.payloadEntityIdKey]),
      imageUrl: _readFirstString(raw, <String>[NotificationConstants.payloadImageUrlKey]),
    );

    final decodedPayload = config.payloadDecoder?.call(raw) ?? defaultPayload;

    return decodedPayload.copyWith(
      source: source,
      raw: raw,
      sourceId: decodedPayload.sourceId ?? sourceId,
      type: decodedPayload.type ?? defaultPayload.type,
      title: decodedPayload.title.isNotEmpty ? decodedPayload.title : defaultPayload.title,
      body: decodedPayload.body.isNotEmpty ? decodedPayload.body : defaultPayload.body,
      deeplink: decodedPayload.deeplink ?? defaultPayload.deeplink,
      entityId: decodedPayload.entityId ?? defaultPayload.entityId,
      imageUrl: decodedPayload.imageUrl ?? defaultPayload.imageUrl,
    );
  }

  Map<String, dynamic> _normalizeRawPayload(Map<String, dynamic> raw) {
    final normalizedRaw = Map<String, dynamic>.from(raw);
    final nestedPayload = normalizedRaw[NotificationConstants.payloadNestedMessageKey];

    if (nestedPayload is Map) {
      normalizedRaw.addAll(nestedPayload.map((key, value) => MapEntry('$key', value)));
      return normalizedRaw;
    }

    if (nestedPayload is String && nestedPayload.trim().startsWith('{')) {
      try {
        final decodedPayload = jsonDecode(nestedPayload);
        if (decodedPayload is Map) {
          normalizedRaw.addAll(decodedPayload.map((key, value) => MapEntry('$key', value)));
        }
      } catch (_) {
        // Ignore malformed nested payloads and keep the original payload untouched.
      }
    }

    return normalizedRaw;
  }

  String? _readFirstString(Map<String, dynamic> raw, List<String> keys) {
    for (final key in keys) {
      final value = raw[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  int? _tryParseInt(String? value) {
    if (value == null) {
      return null;
    }
    return int.tryParse(value);
  }
}
