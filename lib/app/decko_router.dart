import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/auth/auth_repository.dart';
import '../domain/deck.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/deck_detail/deck_detail_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/deck_library/deck_library_screen.dart';
import '../features/deck_options/deck_options_screen.dart';
import '../features/import/import_report_screen.dart';
import '../features/import/import_screen.dart';
import '../features/imported_source/imported_source_screen.dart';
import '../features/progress/progress_screen.dart';
import '../features/settings/global_study_options_screen.dart';
import '../features/settings/profile_editor_screen.dart';
import '../features/settings/settings_hub_screen.dart';
import '../features/settings/study_profiles_screen.dart';
import '../features/review/review_session_screen.dart';
import '../features/account/account_screen.dart';
import '../features/themes/theme_gallery_screen.dart';
import 'decko_app.dart';
import 'decko_shell.dart';
import 'onboarding_controller.dart';

/// Centralised route helpers so navigation calls stay typo-proof.
abstract final class DeckoRoutes {
  static const String home = '/';
  static const String import = '/import';
  static const String progress = '/progress';

  /// The auth gate — Decko requires a signed-in account (MVP_020.1, DEC-029).
  static const String signIn = '/signin';

  /// First-run onboarding (MVP_024).
  static const String onboarding = '/onboarding';

  /// The Settings tab (a hub).
  static const String settings = '/settings';

  /// Global study defaults, under Settings.
  static const String studyDefaults = '/settings/study';

  /// Study profiles list, under Settings.
  static const String studyProfiles = '/settings/profiles';

  /// Editor for the user profile with [id].
  static String profileEditor(String id) => '/settings/profiles/$id';

  /// Theme gallery, under Settings.
  static const String themes = '/settings/themes';

  static const String account = '/settings/account';

  /// Deck detail for the deck with [id].
  static String deck(String id) => '/deck/$id';

  /// Review session for the deck with [id].
  static String deckReview(String id) => '/deck/$id/review';

  /// Imported-source inspector for the deck with [id].
  static String deckSource(String id) => '/deck/$id/source';

  /// Per-deck study options for the deck with [id].
  static String deckOptions(String id) => '/deck/$id/options';

  /// Saved import report for the deck with [id].
  static String deckReport(String id) => '/deck/$id/report';
}

/// Root navigator key — deck/review routes attach here so they cover the shell.
final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

/// The app's GoRouter configuration.
///
/// The four primary destinations (Home, Import, Progress, Settings) live in a
/// [StatefulShellRoute.indexedStack] behind the floating [DeckoShell] nav bar,
/// each keeping its own navigation state. Deck detail is pushed inside the Home
/// branch (so the bar stays and Back returns to Home); the review session is
/// pushed on the **root** navigator so it plays full-screen over the bar.
/// Deck-scoped routes resolve the [Deck] from the [DeckRepository]; an unknown
/// id falls back gracefully.
GoRouter buildDeckoRouter(
    AuthRepository auth, OnboardingController onboarding) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: DeckoRoutes.home,
    refreshListenable: Listenable.merge(<Listenable>[
      GoRouterRefreshStream(auth.authStateChanges()),
      onboarding,
    ]),
    redirect: (BuildContext context, GoRouterState state) {
      final String loc = state.matchedLocation;
      // 1) First-run onboarding precedes everything (MVP_024).
      if (!onboarding.isComplete) {
        return loc == DeckoRoutes.onboarding ? null : DeckoRoutes.onboarding;
      }
      // A real (non-anonymous) account is required to reach the app.
      final bool signedIn =
          auth.currentUser != null && !auth.currentUser!.isAnonymous;
      if (!signedIn) {
        return loc == DeckoRoutes.signIn ? null : DeckoRoutes.signIn;
      }
      // Onboarded + signed in → leave the gate/onboarding routes.
      if (loc == DeckoRoutes.signIn || loc == DeckoRoutes.onboarding) {
        return DeckoRoutes.home;
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: DeckoRoutes.onboarding,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: DeckoRoutes.signIn,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const SignInScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (BuildContext context, GoRouterState state,
                StatefulNavigationShell navigationShell) =>
            DeckoShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(routes: <RouteBase>[
            GoRoute(
              path: DeckoRoutes.home,
              builder: (_, _) => const DeckLibraryScreen(),
              routes: <RouteBase>[
                GoRoute(
                  path: 'deck/:deckId',
                  builder: (BuildContext context, GoRouterState state) {
                    final Deck? deck = _resolveDeck(context, state);
                    return deck == null
                        ? const _DeckNotFound()
                        : DeckDetailScreen(deck: deck);
                  },
                  routes: <RouteBase>[
                    GoRoute(
                      path: 'review',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (BuildContext context, GoRouterState state) {
                        final Deck? deck = _resolveDeck(context, state);
                        return deck == null
                            ? const _DeckNotFound()
                            : ReviewSessionScreen(deck: deck);
                      },
                    ),
                    GoRoute(
                      path: 'source',
                      builder: (BuildContext context, GoRouterState state) {
                        final Deck? deck = _resolveDeck(context, state);
                        return deck == null
                            ? const _DeckNotFound()
                            : ImportedSourceScreen(
                                deckId: deck.id, deckName: deck.name);
                      },
                    ),
                    GoRoute(
                      path: 'options',
                      builder: (BuildContext context, GoRouterState state) {
                        final Deck? deck = _resolveDeck(context, state);
                        return deck == null
                            ? const _DeckNotFound()
                            : DeckOptionsScreen(
                                deckId: deck.id, deckName: deck.name);
                      },
                    ),
                    GoRoute(
                      path: 'report',
                      builder: (BuildContext context, GoRouterState state) {
                        final String? id = state.pathParameters['deckId'];
                        return id == null
                            ? const _DeckNotFound()
                            : ImportReportScreen(deckId: id);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: <RouteBase>[
            GoRoute(
              path: DeckoRoutes.import,
              builder: (_, _) => const ImportScreen(),
            ),
          ]),
          StatefulShellBranch(routes: <RouteBase>[
            GoRoute(
              path: DeckoRoutes.progress,
              builder: (_, _) => const ProgressScreen(),
            ),
          ]),
          StatefulShellBranch(routes: <RouteBase>[
            GoRoute(
              path: DeckoRoutes.settings,
              builder: (_, _) => const SettingsHubScreen(),
              routes: <RouteBase>[
                GoRoute(
                  path: 'study',
                  builder: (_, _) => const GlobalStudyOptionsScreen(),
                ),
                GoRoute(
                  path: 'profiles',
                  builder: (_, _) => const StudyProfilesScreen(),
                  routes: <RouteBase>[
                    GoRoute(
                      path: ':profileId',
                      builder: (BuildContext context, GoRouterState state) =>
                          ProfileEditorScreen(
                              profileId: state.pathParameters['profileId']!),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'themes',
                  builder: (_, _) => const ThemeGalleryScreen(),
                ),
                GoRoute(
                  path: 'account',
                  builder: (_, _) => const AccountScreen(),
                ),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
}

Deck? _resolveDeck(BuildContext context, GoRouterState state) {
  final String? id = state.pathParameters['deckId'];
  if (id == null) return null;
  return DeckoApp.repositoryOf(context).getDeckById(id);
}

/// Bridges a [Stream] (auth state) to a [Listenable] so GoRouter re-evaluates
/// its redirect whenever sign-in state changes (MVP_020.1).
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription =
        stream.asBroadcastStream().listen((dynamic _) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Shown when a deck id in the URL doesn't match a known deck.
class _DeckNotFound extends StatelessWidget {
  const _DeckNotFound();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deck not found')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'We couldn’t find that deck. It may have been removed.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
