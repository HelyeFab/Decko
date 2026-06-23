import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/activity/activity_event.dart';
import '../domain/repositories/activity_ledger_repository.dart';

/// [ActivityLedgerRepository] backed by a single JSON file on local disk
/// (`<appSupport>/decko_activity/events.json`). Off `shared_preferences` because
/// the history grows over time (MVP_019). [baseDir] is injectable for tests.
class LocalActivityLedgerRepository implements ActivityLedgerRepository {
  // ignore: prefer_initializing_formals
  const LocalActivityLedgerRepository({Directory? baseDir}) : _baseDir = baseDir;

  final Directory? _baseDir;

  static const String _root = 'decko_activity';
  static const String _fileName = 'events.json';

  Future<File> _file({bool create = false}) async {
    final Directory base = _baseDir ?? await getApplicationSupportDirectory();
    final Directory dir = Directory('${base.path}/$_root');
    if (create) await dir.create(recursive: true);
    return File('${dir.path}/$_fileName');
  }

  Future<List<ActivityEvent>> _load() async {
    final File f = await _file();
    if (!f.existsSync()) return <ActivityEvent>[];
    try {
      final List<dynamic> raw = jsonDecode(await f.readAsString()) as List<dynamic>;
      return raw
          .map((dynamic e) =>
              ActivityEvent.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return <ActivityEvent>[];
    }
  }

  Future<void> _save(List<ActivityEvent> events) async {
    final File f = await _file(create: true);
    await f.writeAsString(
        jsonEncode(events.map((ActivityEvent e) => e.toJson()).toList()));
  }

  @override
  Future<void> record(ActivityEvent event) async {
    final List<ActivityEvent> events = await _load()..add(event);
    await _save(events);
  }

  @override
  Future<List<ActivityEvent>> allEvents() => _load();

  @override
  Future<List<ActivityEvent>> eventsBetween(DateTime start, DateTime end) async {
    final List<ActivityEvent> all = await _load();
    return all
        .where((ActivityEvent e) =>
            !e.occurredAt.isBefore(start) && e.occurredAt.isBefore(end))
        .toList();
  }

  @override
  Future<List<ActivityEvent>> recentEvents({int limit = 50}) async {
    final List<ActivityEvent> all = await _load()
      ..sort((ActivityEvent a, ActivityEvent b) =>
          b.occurredAt.compareTo(a.occurredAt));
    return all.take(limit).toList();
  }
}
