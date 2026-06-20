import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/repositories/study_options_repository.dart';
import '../domain/study_options/study_options.dart';

/// [StudyOptionsRepository] backed by `shared_preferences`.
///
/// Global defaults live under one key; each deck's overrides live under a
/// per-deck key, so they're loaded only when needed and removed with the deck.
class SharedPrefsStudyOptionsRepository implements StudyOptionsRepository {
  const SharedPrefsStudyOptionsRepository();

  static const String _globalKey = 'decko.studyOptions.global';
  static String _deckKey(String deckId) => 'decko.studyOptions.deck.$deckId';

  @override
  Future<StudyOptions> getGlobalOptions() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_globalKey);
    if (raw == null) return StudyOptions.defaults;
    try {
      return StudyOptions.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return StudyOptions.defaults;
    }
  }

  @override
  Future<void> saveGlobalOptions(StudyOptions options) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_globalKey, jsonEncode(options.toMap()));
  }

  @override
  Future<DeckStudyOptions?> getDeckOptions(String deckId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_deckKey(deckId));
    if (raw == null) return null;
    try {
      return DeckStudyOptions.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveDeckOptions(String deckId, DeckStudyOptions options) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deckKey(deckId), jsonEncode(options.toMap()));
  }

  @override
  Future<void> deleteDeckOptions(String deckId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deckKey(deckId));
  }

  @override
  Future<EffectiveStudyOptions> getEffectiveOptions(String deckId) async {
    final StudyOptions global = await getGlobalOptions();
    final DeckStudyOptions? deck = await getDeckOptions(deckId);
    return EffectiveStudyOptions.resolve(global, deck);
  }
}
