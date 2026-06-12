import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/deck.dart';
import '../features/deck_detail/deck_detail_screen.dart';
import '../features/deck_library/deck_library_screen.dart';
import '../features/import/import_placeholder_screen.dart';
import '../features/progress/progress_placeholder_screen.dart';
import '../features/review/review_placeholder_screen.dart';
import '../features/themes/theme_gallery_screen.dart';
import 'decko_app.dart';

/// Centralised route helpers so navigation calls stay typo-proof.
abstract final class DeckoRoutes {
  static const String home = '/';
  static const String import = '/import';
  static const String themes = '/themes';
  static const String progress = '/progress';

  /// Sample review with no deck context (fallback preview).
  static const String review = '/review';

  /// Deck detail for the deck with [id].
  static String deck(String id) => '/deck/$id';

  /// Review of the first card of the deck with [id].
  static String deckReview(String id) => '/deck/$id/review';
}

/// The app's GoRouter configuration.
///
/// Sub-screens are pushed over the deck library so the system back button
/// returns to the hub. Deck-scoped routes resolve the [Deck] from the
/// [DeckRepository] in the app scope; an unknown id falls back gracefully.
GoRouter buildDeckoRouter() {
  return GoRouter(
    initialLocation: DeckoRoutes.home,
    routes: <RouteBase>[
      GoRoute(
        path: DeckoRoutes.home,
        builder: (_, _) => const DeckLibraryScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: 'import',
            builder: (_, _) => const ImportPlaceholderScreen(),
          ),
          GoRoute(
            path: 'review',
            builder: (_, _) => const ReviewPlaceholderScreen(),
          ),
          GoRoute(
            path: 'themes',
            builder: (_, _) => const ThemeGalleryScreen(),
          ),
          GoRoute(
            path: 'progress',
            builder: (_, _) => const ProgressPlaceholderScreen(),
          ),
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
                builder: (BuildContext context, GoRouterState state) {
                  return ReviewPlaceholderScreen(
                    deck: _resolveDeck(context, state),
                  );
                },
              ),
            ],
          ),
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
