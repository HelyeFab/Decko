import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../app/decko_app.dart';
import '../../core/constants/decko_spacing.dart';
import '../../core/widgets/decko_app_bar.dart';
import '../../core/widgets/decko_confirm_dialog.dart';
import '../../domain/repositories/study_options_repository.dart';
import '../../domain/study_options/study_options.dart';
import 'widgets/study_options_form.dart';

/// Edit a single user study profile (MVP_012): rename, tune its options, delete.
class ProfileEditorScreen extends StatefulWidget {
  const ProfileEditorScreen({super.key, required this.profileId});

  final String profileId;

  @override
  State<ProfileEditorScreen> createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends State<ProfileEditorScreen> {
  StudyOptionsRepository? _repo;
  StudyOptionProfile? _profile;
  final TextEditingController _name = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repo ??= DeckoApp.studyOptionsOf(context);
    if (_profile == null) _load();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final StudyOptionProfile? p = await _repo!.getProfile(widget.profileId);
    if (!mounted || p == null) return;
    setState(() {
      _profile = p;
      _name.text = p.name;
    });
  }

  void _save(StudyOptionProfile next) {
    setState(() => _profile = next);
    _repo!.saveProfile(next);
  }

  Future<void> _delete() async {
    final bool ok = await DeckoConfirmDialog.show(
      context,
      icon: FontAwesomeIcons.trashCan,
      title: 'Delete “${_profile!.name}”?',
      message: 'Decks using this profile fall back to the global defaults.',
      confirmLabel: 'Delete profile',
      destructive: true,
    );
    if (!ok) return;
    await _repo!.deleteProfile(widget.profileId);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final StudyOptionProfile? p = _profile;
    return Scaffold(
      appBar: const DeckoAppBar(title: 'Edit profile'),
      body: SafeArea(
        child: p == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  DeckoSpacing.pagePadding,
                  DeckoSpacing.lg,
                  DeckoSpacing.pagePadding,
                  DeckoSpacing.xxxl,
                ),
                children: <Widget>[
                  TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Profile name',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (String v) =>
                        _save(p.copyWith(name: v.trim().isEmpty ? 'Profile' : v)),
                  ),
                  const SizedBox(height: DeckoSpacing.xl),
                  StudyOptionsForm(
                    options: p.options,
                    onChanged: (StudyOptions o) => _save(p.copyWith(options: o)),
                  ),
                  const SizedBox(height: DeckoSpacing.xl),
                  OutlinedButton.icon(
                    onPressed: _delete,
                    icon: const FaIcon(FontAwesomeIcons.trashCan, size: 14),
                    label: const Text('Delete profile'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
