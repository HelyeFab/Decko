import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/deck.dart';
import '../features/deck_detail/deck_detail_screen.dart';
import '../features/deck_library/deck_library_screen.dart';
import '../features/import/import_screen.dart';
import '../features/progress/progress_screen.dart';
import '../features/review/review_session_screen.dart';
import '../features/themes/theme_gallery_screen.dart';
import 'decko_app.dart';
import 'decko_shell.dart';

/// Centralised route helpers so navigation calls stay typo-proof.
abstract final class DeckoRoutes {
  static const String home = '/';
  static const String import = '/import';
  static const String progress = '/progress';

  /// The Settings tab (currently the theme gallery).
  static const String settings = '/settings';

  /// Deck detail for the deck with [id].
  static String deck(String id) => '/deck/$id';

  /// Review session for the deck with [id].
  static String deckReview(String id) => '/deck/$id/review';
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
GoRouter buildDeckoRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: DeckoRoutes.home,
    routes: <RouteBase>[
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
              builder: (_, _) => const ThemeGalleryScreen(),
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
