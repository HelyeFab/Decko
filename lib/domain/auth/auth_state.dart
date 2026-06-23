import 'decko_user.dart';

/// How Decko is currently identified for sync (MVP_020).
enum AuthMode { localOnly, anonymous, signedIn }

/// The current auth state — a null [user] means local-only (no cloud identity).
class AuthState {
  const AuthState(this.user);

  /// No cloud identity; Decko is fully usable this way.
  static const AuthState localOnly = AuthState(null);

  final DeckoUser? user;

  bool get isLocalOnly => user == null;
  bool get isAnonymous => user?.isAnonymous ?? false;
  bool get isSignedIn => user != null && !user!.isAnonymous;

  AuthMode get mode {
    if (user == null) return AuthMode.localOnly;
    return user!.isAnonymous ? AuthMode.anonymous : AuthMode.signedIn;
  }
}
