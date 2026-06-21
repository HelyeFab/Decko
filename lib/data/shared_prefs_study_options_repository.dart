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
  static const String _profilesKey = 'decko.studyOptions.profiles';
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

  // --- profiles (MVP_012) ---------------------------------------------------

  StudyOptionProfile _defaultProfile(StudyOptions global) => StudyOptionProfile(
        id: StudyOptionProfile.defaultId,
        name: 'Default',
        options: global,
        isDefault: true,
      );

  Future<List<StudyOptionProfile>> _userProfiles() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_profilesKey);
    if (raw == null) return <StudyOptionProfile>[];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map((dynamic e) =>
              StudyOptionProfile.fromMap((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return <StudyOptionProfile>[];
    }
  }

  Future<void> _saveUserProfiles(List<StudyOptionProfile> profiles) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _profilesKey,
        jsonEncode(profiles
            .map((StudyOptionProfile p) => p.toMap())
            .toList()));
  }

  @override
  Future<List<StudyOptionProfile>> listProfiles() async {
    final StudyOptions global = await getGlobalOptions();
    return <StudyOptionProfile>[
      _defaultProfile(global),
      ...await _userProfiles(),
    ];
  }

  @override
  Future<StudyOptionProfile?> getProfile(String id) async {
    if (id == StudyOptionProfile.defaultId) {
      return _defaultProfile(await getGlobalOptions());
    }
    for (final StudyOptionProfile p in await _userProfiles()) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  Future<void> saveProfile(StudyOptionProfile profile) async {
    if (profile.id == StudyOptionProfile.defaultId || profile.isDefault) {
      return; // the default profile is edited via global options
    }
    final List<StudyOptionProfile> profiles = await _userProfiles();
    final int i =
        profiles.indexWhere((StudyOptionProfile p) => p.id == profile.id);
    if (i >= 0) {
      profiles[i] = profile;
    } else {
      profiles.add(profile);
    }
    await _saveUserProfiles(profiles);
  }

  @override
  Future<void> deleteProfile(String id) async {
    if (id == StudyOptionProfile.defaultId) return; // never delete default
    final List<StudyOptionProfile> profiles = await _userProfiles()
      ..removeWhere((StudyOptionProfile p) => p.id == id);
    await _saveUserProfiles(profiles);
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
    final DeckStudyOptions? deck = await getDeckOptions(deckId);
    // Base layer: the assigned profile's options, else the global defaults.
    // A dangling profile id (deleted profile) falls back to global.
    StudyOptions base = await getGlobalOptions();
    final String? pid = deck?.profileId;
    if (pid != null && pid != StudyOptionProfile.defaultId) {
      final StudyOptionProfile? profile = await getProfile(pid);
      if (profile != null) base = profile.options;
    }
    return EffectiveStudyOptions.resolve(base, deck);
  }
}
