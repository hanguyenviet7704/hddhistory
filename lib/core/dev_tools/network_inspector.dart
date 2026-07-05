import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Lightweight in-app network inspector — DEV flavor only.
///
/// Unlike a disk-backed inspector (e.g. chucker), captured calls live only in
/// memory in a small ring buffer, so there is NO per-request serialization /
/// disk write and therefore no UI jank. JSON is pretty-printed lazily, only
/// when a request's detail screen is opened.

/// One captured request/response pair.
class ApiLog {
  ApiLog({
    required this.method,
    required this.url,
    required this.time,
    required this.duration,
    required this.requestHeaders,
    required this.requestBody,
    this.statusCode,
    this.responseBody,
    this.error,
  });

  final String method;
  final String url;
  final DateTime time;
  final Duration duration;
  final Map<String, dynamic> requestHeaders;
  final Object? requestBody;
  final int? statusCode;
  final Object? responseBody;
  final String? error;

  bool get isSuccess =>
      error == null &&
      statusCode != null &&
      statusCode! >= 200 &&
      statusCode! < 400;

  /// Path (+ query) only, for the compact list row.
  String get shortPath {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    return uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;
  }

  String get host => Uri.tryParse(url)?.host ?? '';
}

/// In-memory store of the most recent [_maxEntries] API calls.
class NetworkInspectorStore {
  NetworkInspectorStore._();
  static final NetworkInspectorStore instance = NetworkInspectorStore._();

  static const int _maxEntries = 50;

  /// Newest first. UI listens to this.
  final ValueNotifier<List<ApiLog>> logs = ValueNotifier<List<ApiLog>>(<ApiLog>[]);

  void add(ApiLog log) {
    final next = <ApiLog>[log, ...logs.value];
    if (next.length > _maxEntries) {
      next.removeRange(_maxEntries, next.length);
    }
    logs.value = next;
  }

  void clear() => logs.value = <ApiLog>[];
}

/// Dio interceptor that records requests into [NetworkInspectorStore].
/// Attach on the DEV flavor only (see network_di.dart).
class NetworkInspectorInterceptor extends Interceptor {
  static const String _startKey = '_networkInspectorStart';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startKey] = DateTime.now();
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    _record(response.requestOptions, response.statusCode, response.data, null);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _record(
      err.requestOptions,
      err.response?.statusCode,
      err.response?.data,
      err.message ?? err.type.name,
    );
    handler.next(err);
  }

  void _record(RequestOptions o, int? status, Object? body, String? error) {
    final start = o.extra[_startKey];
    final duration =
        start is DateTime ? DateTime.now().difference(start) : Duration.zero;
    NetworkInspectorStore.instance.add(
      ApiLog(
        method: o.method,
        url: o.uri.toString(),
        time: DateTime.now(),
        duration: duration,
        requestHeaders: Map<String, dynamic>.from(o.headers),
        requestBody: o.data,
        statusCode: status,
        responseBody: body,
        error: error,
      ),
    );
  }
}

String _pretty(Object? value) {
  if (value == null) return '';
  try {
    if (value is String) {
      // Try to pretty-print JSON strings; otherwise show as-is.
      final decoded = jsonDecode(value);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    }
    return const JsonEncoder.withIndent('  ').convert(value);
  } catch (_) {
    return value.toString();
  }
}

Color _statusColor(ApiLog log) {
  if (!log.isSuccess) return const Color(0xFFD64545); // red
  return const Color(0xFF2E7D32); // green
}

/// Full-screen list of captured API calls.
class NetworkInspectorPage extends StatelessWidget {
  const NetworkInspectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = NetworkInspectorStore.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Inspector'),
        actions: [
          IconButton(
            tooltip: 'Clear',
            icon: const Icon(Icons.delete_outline),
            onPressed: store.clear,
          ),
        ],
      ),
      body: ValueListenableBuilder<List<ApiLog>>(
        valueListenable: store.logs,
        builder: (context, logs, _) {
          if (logs.isEmpty) {
            return const Center(child: Text('No API calls captured yet'));
          }
          return ListView.separated(
            itemCount: logs.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final log = logs[index];
              return ListTile(
                dense: true,
                leading: _MethodChip(method: log.method),
                title: Text(
                  log.shortPath,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${log.host} · ${log.duration.inMilliseconds} ms · ${_hhmmss(log.time)}',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: Text(
                  log.error != null ? 'ERR' : '${log.statusCode ?? '-'}',
                  style: TextStyle(
                    color: _statusColor(log),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _ApiLogDetailPage(log: log),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ApiLogDetailPage extends StatelessWidget {
  const _ApiLogDetailPage({required this.log});

  final ApiLog log;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${log.method}  ${log.statusCode ?? log.error ?? ''}'),
          bottom: const TabBar(tabs: [Tab(text: 'REQUEST'), Tab(text: 'RESPONSE')]),
        ),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _section('URL', log.url),
                _section('Duration', '${log.duration.inMilliseconds} ms'),
                _section('Headers', _pretty(log.requestHeaders)),
                _section('Body', _pretty(log.requestBody)),
              ],
            ),
            ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (log.error != null) _section('Error', log.error!),
                _section('Status', '${log.statusCode ?? '-'}'),
                _section('Body', _pretty(log.responseBody)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        SelectableText(
          value.isEmpty ? '—' : value,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
      ],
    );
  }
}

class _MethodChip extends StatelessWidget {
  const _MethodChip({required this.method});

  final String method;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF3A2E5C),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        method,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

String _hhmmss(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
