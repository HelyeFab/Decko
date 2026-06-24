import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../app/decko_app.dart';
import '../../core/constants/decko_spacing.dart';

/// First-run onboarding (MVP_024, DEC-033): a short, skippable, beautiful intro
/// that explains import, progress safety, and the honest sync boundary. Finishing
/// or skipping marks onboarding complete and the router moves on (sign-in/home).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const List<_OnboardingPage> _pages = <_OnboardingPage>[
    _OnboardingPage(
      icon: FontAwesomeIcons.fileArrowUp,
      title: 'Import your deck',
      body: 'Decko studies real Anki .apkg decks. Import yours and Decko '
          'detects your existing progress when it’s there.',
    ),
    _OnboardingPage(
      icon: FontAwesomeIcons.wandMagicSparkles,
      title: 'Study beautifully',
      body: 'Cards, audio, furigana, and practice games — all in Decko’s own '
          'modern design, not a stock flashcard app.',
    ),
    _OnboardingPage(
      icon: FontAwesomeIcons.shieldHeart,
      title: 'Your progress is safe',
      body: 'Decko never silently resets imported progress. When there’s a '
          'choice to keep or start fresh, it’s always yours to make.',
    ),
    _OnboardingPage(
      icon: FontAwesomeIcons.cloudArrowUp,
      title: 'Sync across devices',
      body: 'Your account, XP, streaks, and review progress for matching decks '
          'sync across devices. Deck files and media stay on each device — to '
          'continue a deck elsewhere, import the same deck there too.',
    ),
  ];

  bool get _isLast => _page == _pages.length - 1;

  Future<void> _finish() async {
    await DeckoApp.onboardingOf(context).complete();
    // The router's redirect takes over once onboarding is complete.
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(
          duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(DeckoSpacing.sm),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (int i) => setState(() => _page = i),
                itemBuilder: (BuildContext context, int i) =>
                    _PageView(page: _pages[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(DeckoSpacing.pagePadding),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      for (int i = 0; i < _pages.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin:
                              const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: i == _page ? 22 : 8,
                          decoration: BoxDecoration(
                            color: i == _page
                                ? scheme.primary
                                : scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(DeckoRadii.pill),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: DeckoSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _next,
                      child: Text(_isLast ? 'Get started' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
  });
  final FaIconData icon;
  final String title;
  final String body;
}

class _PageView extends StatelessWidget {
  const _PageView({required this.page});
  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DeckoSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            height: 112,
            width: 112,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(DeckoRadii.lg),
            ),
            child: FaIcon(page.icon,
                size: 44, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(height: DeckoSpacing.xxl),
          Text(page.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: DeckoSpacing.md),
          Text(page.body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
