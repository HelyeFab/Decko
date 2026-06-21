import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../app/decko_app.dart';
import '../../app/decko_router.dart';
import '../../core/constants/decko_spacing.dart';
import '../../core/widgets/decko_app_bar.dart';
import '../../domain/repositories/study_options_repository.dart';
import '../../domain/study_options/study_options.dart';

/// Manage reusable study profiles (MVP_012): see, create, edit, delete. One
/// set of settings shared across several decks.
class StudyProfilesScreen extends StatefulWidget {
  const StudyProfilesScreen({super.key});

  @override
  State<StudyProfilesScreen> createState() => _StudyProfilesScreenState();
}

class _StudyProfilesScreenState extends State<StudyProfilesScreen> {
  StudyOptionsRepository? _repo;
  List<StudyOptionProfile>? _profiles;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repo ??= DeckoApp.studyOptionsOf(context);
    _load();
  }

  Future<void> _load() async {
    final List<StudyOptionProfile> p = await _repo!.listProfiles();
    if (mounted) setState(() => _profiles = p);
  }

  Future<void> _create() async {
    final String id = 'p${DateTime.now().microsecondsSinceEpoch}';
    await _repo!.saveProfile(StudyOptionProfile(
      id: id,
      name: 'New profile',
      options: StudyOptions.defaults,
    ));
    if (!mounted) return;
    await context.push(DeckoRoutes.profileEditor(id));
    _load(); // refresh on return
  }

  Future<void> _open(StudyOptionProfile p) async {
    // The default profile *is* the global defaults — edit it there.
    await context.push(
        p.isDefault ? DeckoRoutes.studyDefaults : DeckoRoutes.profileEditor(p.id));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final List<StudyOptionProfile>? profiles = _profiles;
    return Scaffold(
      appBar: const DeckoAppBar(title: 'Study profiles'),
      body: SafeArea(
        child: profiles == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  DeckoSpacing.pagePadding,
                  DeckoSpacing.lg,
                  DeckoSpacing.pagePadding,
                  DeckoSpacing.xxxl,
                ),
                children: <Widget>[
                  Text(
                    'Use one set of study settings across several decks.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: DeckoSpacing.lg),
                  for (final StudyOptionProfile p in profiles) ...<Widget>[
                    _ProfileRow(profile: p, onTap: () => _open(p)),
                    const SizedBox(height: DeckoSpacing.md),
                  ],
                  const SizedBox(height: DeckoSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: _create,
                    icon: const FaIcon(FontAwesomeIcons.plus, size: 14),
                    label: const Text('New profile'),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.profile, required this.onTap});

  final StudyOptionProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(DeckoRadii.lg),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(DeckoSpacing.lg),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(DeckoRadii.lg),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: <Widget>[
              FaIcon(FontAwesomeIcons.solidStar,
                  size: 16,
                  color: profile.isDefault
                      ? scheme.primary
                      : scheme.onSurfaceVariant),
              const SizedBox(width: DeckoSpacing.md),
              Expanded(
                child: Text(
                  profile.name,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (profile.isDefault)
                Text('DEFAULT',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w700,
                    )),
              const SizedBox(width: DeckoSpacing.sm),
              FaIcon(FontAwesomeIcons.chevronRight,
                  size: 14, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
