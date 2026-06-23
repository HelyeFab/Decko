import 'auth_state.dart';
import 'decko_user.dart';

/// A friendly, recoverable auth error (never leaks Firebase internals to UI).
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The auth seam (MVP_020, DEC-029). Screens depend on this, never on Firebase.
/// Decko is fully usable while [currentUser] is null (local-only).
abstract class AuthRepository {
  /// Emits the current [AuthState] and every change (starts with the current).
  Stream<AuthState> authStateChanges();

  DeckoUser? get currentUser;

  /// An anonymous cloud identity — instant, no credentials.
  Future<DeckoUser> signInAnonymously();

  Future<DeckoUser> signInWithEmail(String email, String password);

  Future<DeckoUser> createAccountWithEmail(String email, String password);

  /// Google sign-in; throws [AuthException] if cancelled or unavailable.
  Future<DeckoUser> signInWithGoogle();

  Future<void> signOut();
}
