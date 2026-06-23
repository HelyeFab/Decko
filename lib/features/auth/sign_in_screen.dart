import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../app/decko_app.dart';
import '../../core/constants/decko_spacing.dart';
import '../../core/constants/decko_strings.dart';
import '../../domain/auth/auth_repository.dart';

/// The auth gate (MVP_020.1): Decko now requires a signed-in account before the
/// app. Branded, full-screen — email/password or Google. A successful sign-in
/// lets the router redirect through to Home; sync then runs in the background.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _busy = false;
  bool _createMode = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function(AuthRepository auth) action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final AuthRepository auth = DeckoApp.authOf(context);
    try {
      await action(auth);
      // The router's redirect navigates to Home once signed in; kick off sync.
      if (mounted) DeckoApp.syncOf(context).syncNow();
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DeckoSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: DeckoSpacing.xl),
                  Center(
                    child: Container(
                      height: 64,
                      width: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(DeckoRadii.lg),
                      ),
                      child: FaIcon(FontAwesomeIcons.layerGroup,
                          color: scheme.onPrimary, size: 28),
                    ),
                  ),
                  const SizedBox(height: DeckoSpacing.lg),
                  Text(DeckoStrings.wordmark,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800, color: scheme.primary)),
                  const SizedBox(height: DeckoSpacing.xs),
                  Text(
                    _createMode
                        ? 'Create your account to start learning.'
                        : 'Sign in to continue learning.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: DeckoSpacing.xxl),
                  TextField(
                    controller: _email,
                    enabled: !_busy,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.alternate_email, size: 18),
                    ),
                  ),
                  const SizedBox(height: DeckoSpacing.md),
                  TextField(
                    controller: _password,
                    enabled: !_busy,
                    obscureText: true,
                    onSubmitted: (_) => _busy ? null : _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline, size: 18),
                    ),
                  ),
                  if (_error != null) ...<Widget>[
                    const SizedBox(height: DeckoSpacing.md),
                    Text(_error!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.error)),
                  ],
                  const SizedBox(height: DeckoSpacing.lg),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2))
                        : Text(_createMode ? 'Create account' : 'Sign in'),
                  ),
                  const SizedBox(height: DeckoSpacing.sm),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                              _createMode = !_createMode;
                              _error = null;
                            }),
                    child: Text(_createMode
                        ? 'Already have an account? Sign in'
                        : 'New to Decko? Create an account'),
                  ),
                  const SizedBox(height: DeckoSpacing.md),
                  Row(
                    children: <Widget>[
                      Expanded(child: Divider(color: scheme.outlineVariant)),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: DeckoSpacing.md),
                        child: Text('or',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: scheme.onSurfaceVariant)),
                      ),
                      Expanded(child: Divider(color: scheme.outlineVariant)),
                    ],
                  ),
                  const SizedBox(height: DeckoSpacing.md),
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _run((AuthRepository a) => a.signInWithGoogle()),
                    icon: const FaIcon(FontAwesomeIcons.google, size: 16),
                    label: const Text('Continue with Google'),
                  ),
                  const SizedBox(height: DeckoSpacing.xl),
                  Text(
                    'Your XP, streaks, and history sync securely to your '
                    'account. Imported decks and review schedules stay on your '
                    'device.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_createMode) {
      _run((AuthRepository a) =>
          a.createAccountWithEmail(_email.text, _password.text));
    } else {
      _run((AuthRepository a) =>
          a.signInWithEmail(_email.text, _password.text));
    }
  }
}
