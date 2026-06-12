import 'package:go_router/go_router.dart';

import '../features/deck_library/deck_library_screen.dart';
import '../features/import/import_placeholder_screen.dart';
import '../features/progress/progress_placeholder_screen.dart';
import '../features/review/review_placeholder_screen.dart';
import '../features/themes/theme_gallery_screen.dart';

/// Centralised route names so navigation calls stay typo-proof.
abstract final class DeckoRoutes {
  static const String home = '/';
  static const String import = '/import';
  static const String review = '/review';
  static const String themes = '/themes';
  static const String progress = '/progress';
}

/// The app's GoRouter configuration.
///
/// Sub-screens are pushed on top of home so the system/back button returns to
/// the deck library — the natural hub of the shell.
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
        ],
      ),
    ],
  );
}
