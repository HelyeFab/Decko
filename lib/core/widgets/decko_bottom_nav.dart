import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../constants/decko_spacing.dart';

/// One destination in the floating nav bar.
class DeckoNavItem {
  const DeckoNavItem({required this.icon, required this.label});
  final FaIconData icon;
  final String label;
}

/// Decko's floating bottom navigation (MVP_008.5b, DEC-018).
///
/// A rounded, elevated bar that hovers above the content with a margin — never
/// the stock edge-to-edge Material `NavigationBar`. The active destination
/// expands into a labelled primary pill; the rest stay as quiet icons. Every
/// item carries a tooltip so it's reachable by screen readers (and tests).
class DeckoBottomNav extends StatelessWidget {
  const DeckoBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelect,
  });

  final List<DeckoNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DeckoSpacing.pagePadding,
          DeckoSpacing.sm,
          DeckoSpacing.pagePadding,
          DeckoSpacing.md,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DeckoSpacing.sm,
            vertical: DeckoSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(DeckoRadii.pill),
            border: Border.all(color: scheme.outlineVariant),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              for (int i = 0; i < items.length; i++)
                Expanded(
                  // The active pill needs extra room for its label; idle items
                  // are just icons, so give them less.
                  flex: i == currentIndex ? 2 : 1,
                  child: _NavButton(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final DeckoNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color fg =
        selected ? scheme.onPrimary : scheme.onSurfaceVariant;

    return Tooltip(
      message: item.label,
      child: Semantics(
        button: true,
        selected: selected,
        label: item.label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(DeckoRadii.pill),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(
                horizontal: DeckoSpacing.md,
                vertical: DeckoSpacing.md,
              ),
              decoration: BoxDecoration(
                color: selected ? scheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(DeckoRadii.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  FaIcon(item.icon, size: 17, color: fg),
                  if (selected) ...<Widget>[
                    const SizedBox(width: DeckoSpacing.sm),
                    Flexible(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        softWrap: false,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
