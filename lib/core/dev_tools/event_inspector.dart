import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Lightweight in-app analytics-event inspector — DEV flavor only.
///
/// Mirrors [NetworkInspectorStore]'s design (in-memory ring buffer + a
/// `ValueNotifier` the UI listens to), but captures every analytics event the
/// app fires so a tester can tap through a screen and immediately see which
/// events went out and with which parameters — without a console, Firebase
/// DebugView, or a rebuild.
///
/// Fed from the single choke point every event passes through:
/// `BaseTrackingService.trackEvent` / `.trackScreenView` (all the
/// `AppTrackingService.track*` helpers delegate there). See
/// `config/services/tracking/base_tracking_service.dart`.

enum InspectedEventKind { event, screen }

/// One captured analytics event.
class InspectedEvent {
  InspectedEvent({
    required this.name,
    required this.time,
    required this.kind,
    this.parameters,
  });

  final String name;
  final DateTime time;
  final InspectedEventKind kind;
  final Map<String, dynamic>? parameters;

  bool get hasParams => parameters != null && parameters!.isNotEmpty;

  /// Single-line `k=v · k=v` preview for the compact list row.
  String get paramPreview {
    if (!hasParams) return '';
    return parameters!.entries.map((e) => '${e.key}=${e.value}').join(' · ');
  }

  String get prettyParams {
    if (!hasParams) return '';
    try {
      return const JsonEncoder.withIndent('  ').convert(parameters);
    } catch (_) {
      // Non-encodable values (entities, enums) — fall back to toString.
      return parameters!.entries.map((e) => '${e.key}: ${e.value}').join('\n');
    }
  }

  String asLogLine() {
    final buffer = StringBuffer()
      ..write(_hhmmss(time))
      ..write(' [')
      ..write(kind == InspectedEventKind.screen ? 'SCR' : 'EVT')
      ..write('] ')
      ..write(name);
    if (hasParams) buffer.write(' · $paramPreview');
    return buffer.toString();
  }
}

/// In-memory store of the most recent [_maxEntries] analytics events.
class EventInspectorStore {
  EventInspectorStore._();
  static final EventInspectorStore instance = EventInspectorStore._();

  static const int _maxEntries = 300;

  /// Newest first. UI listens to this.
  final ValueNotifier<List<InspectedEvent>> events =
      ValueNotifier<List<InspectedEvent>>(<InspectedEvent>[]);

  void add(InspectedEvent event) {
    final next = <InspectedEvent>[event, ...events.value];
    if (next.length > _maxEntries) {
      next.removeRange(_maxEntries, next.length);
    }
    events.value = next;
  }

  void clear() => events.value = <InspectedEvent>[];

  /// Whole buffer as plain text — for copy-to-clipboard into a bug report or
  /// for diffing against the "[MeUp] Event Tracking" spec sheet.
  String exportAsText() =>
      events.value.reversed.map((e) => e.asLogLine()).join('\n');
}

/// Full-screen list of captured events, newest first, with a name filter.
class EventInspectorPage extends StatefulWidget {
  const EventInspectorPage({super.key});

  @override
  State<EventInspectorPage> createState() => _EventInspectorPageState();
}

class _EventInspectorPageState extends State<EventInspectorPage> {
  final TextEditingController _search = TextEditingController();
  InspectedEventKind? _kindFilter;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<InspectedEvent> _apply(List<InspectedEvent> all) {
    final query = _search.text.trim().toLowerCase();
    return all.where((e) {
      if (_kindFilter != null && e.kind != _kindFilter) return false;
      if (query.isEmpty) return true;
      return e.name.toLowerCase().contains(query) ||
          e.paramPreview.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final store = EventInspectorStore.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Inspector'),
        actions: [
          IconButton(
            tooltip: 'Copy all',
            icon: const Icon(Icons.copy_all_outlined),
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: store.exportAsText()),
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Events copied'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Clear',
            icon: const Icon(Icons.delete_outline),
            onPressed: store.clear,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Filter by event name or param…',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(_search.clear),
                      ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _kindFilter == null,
                  onTap: () => setState(() => _kindFilter = null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Events',
                  selected: _kindFilter == InspectedEventKind.event,
                  onTap: () =>
                      setState(() => _kindFilter = InspectedEventKind.event),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Screens',
                  selected: _kindFilter == InspectedEventKind.screen,
                  onTap: () =>
                      setState(() => _kindFilter = InspectedEventKind.screen),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ValueListenableBuilder<List<InspectedEvent>>(
              valueListenable: store.events,
              builder: (context, all, _) {
                final events = _apply(all);
                if (all.isEmpty) {
                  return const Center(
                    child: Text('No events captured yet — tap around the app'),
                  );
                }
                if (events.isEmpty) {
                  return const Center(child: Text('No events match the filter'));
                }
                return ListView.separated(
                  itemCount: events.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return ListTile(
                      dense: true,
                      leading: _KindChip(kind: event.kind),
                      title: Text(
                        event.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        event.hasParams
                            ? '${_hhmmss(event.time)} · ${event.paramPreview}'
                            : _hhmmss(event.time),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: event.hasParams
                          ? const Icon(Icons.chevron_right, size: 18)
                          : null,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => _EventDetailPage(event: event),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EventDetailPage extends StatelessWidget {
  const _EventDetailPage({required this.event});

  final InspectedEvent event;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event'),
        actions: [
          IconButton(
            tooltip: 'Copy',
            icon: const Icon(Icons.copy),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: event.asLogLine()));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Copied'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _section('Name', event.name),
          _section(
            'Kind',
            event.kind == InspectedEventKind.screen ? 'screen_view' : 'event',
          ),
          _section('Time', event.time.toIso8601String()),
          _section('Parameters', event.prettyParams),
        ],
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

class _KindChip extends StatelessWidget {
  const _KindChip({required this.kind});

  final InspectedEventKind kind;

  @override
  Widget build(BuildContext context) {
    final isScreen = kind == InspectedEventKind.screen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isScreen ? const Color(0xFF1F5FA6) : const Color(0xFF3A2E5C),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isScreen ? 'SCR' : 'EVT',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => onTap(),
      visualDensity: VisualDensity.compact,
    );
  }
}

String _hhmmss(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
