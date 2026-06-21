import 'package:flutter/material.dart';

import '../../app/decko_app.dart';
import '../../core/constants/decko_spacing.dart';
import '../../core/widgets/decko_app_bar.dart';
import '../../domain/repositories/study_options_repository.dart';
import '../../domain/study_options/study_options.dart';
import 'widgets/study_options_form.dart';

/// Global study defaults for every deck (MVP_011). Changes persist immediately.
class GlobalStudyOptionsScreen extends StatefulWidget {
  const GlobalStudyOptionsScreen({super.key});

  @override
  State<GlobalStudyOptionsScreen> createState() =>
      _GlobalStudyOptionsScreenState();
}

class _GlobalStudyOptionsScreenState extends State<GlobalStudyOptionsScreen> {
  StudyOptionsRepository? _repo;
  StudyOptions? _options;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repo ??= DeckoApp.studyOptionsOf(context);
    if (_options == null) _load();
  }

  Future<void> _load() async {
    final StudyOptions o = await _repo!.getGlobalOptions();
    if (mounted) setState(() => _options = o);
  }

  void _update(StudyOptions next) {
    setState(() => _options = next);
    _repo!.saveGlobalOptions(next);
  }

  @override
  Widget build(BuildContext context) {
    final StudyOptions? o = _options;
    return Scaffold(
      appBar: const DeckoAppBar(title: 'Study defaults'),
      body: SafeArea(
        child: o == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  DeckoSpacing.pagePadding,
                  DeckoSpacing.lg,
                  DeckoSpacing.pagePadding,
                  DeckoSpacing.xxxl,
                ),
                children: <Widget>[
                  StudyOptionsForm(options: o, onChanged: _update),
                ],
              ),
      ),
    );
  }
}
