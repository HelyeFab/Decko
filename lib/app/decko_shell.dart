import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/decko_bottom_nav.dart';

/// The top-level shell: the four primary destinations behind a persistent
/// floating nav bar (MVP_008.5b). Deck detail and review sessions are pushed
/// over this shell on the root navigator, so they appear full-screen without
/// the bar.
class DeckoShell extends StatelessWidget {
  const DeckoShell({super.key, required this.navigationShell});

  /// The branch container from [StatefulShellRoute.indexedStack]; keeps each
  /// tab's navigation state alive as the user switches.
  final StatefulNavigationShell navigationShell;

  static const List<DeckoNavItem> _items = <DeckoNavItem>[
    DeckoNavItem(icon: FontAwesomeIcons.house, label: 'Home'),
    DeckoNavItem(icon: FontAwesomeIcons.fileImport, label: 'Import'),
    DeckoNavItem(icon: FontAwesomeIcons.chartLine, label: 'Progress'),
    DeckoNavItem(icon: FontAwesomeIcons.gear, label: 'Settings'),
  ];

  void _go(int index) {
    // Re-tapping the active tab pops it back to that branch's root.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DeckoBottomNav(
        items: _items,
        currentIndex: navigationShell.currentIndex,
        onSelect: _go,
      ),
    );
  }
}
