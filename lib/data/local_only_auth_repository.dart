import '../domain/auth/auth_repository.dart';
import '../domain/auth/auth_state.dart';
import '../domain/auth/decko_user.dart';

/// The safe default when Firebase isn't wired (e.g. config missing or init
/// failed): Decko stays fully usable, just local-only. Sign-in is unavailable.
class LocalOnlyAuthRepository implements AuthRepository {
  const LocalOnlyAuthRepository();

  static const AuthException _unavailable =
      AuthException('Cloud sync isn’t available right now.');

  @override
  Stream<AuthState> authStateChanges() =>
      Stream<AuthState>.value(AuthState.localOnly);

  @override
  DeckoUser? get currentUser => null;

  @override
  Future<DeckoUser> signInAnonymously() => throw _unavailable;

  @override
  Future<DeckoUser> signInWithEmail(String email, String password) =>
      throw _unavailable;

  @override
  Future<DeckoUser> createAccountWithEmail(String email, String password) =>
      throw _unavailable;

  @override
  Future<DeckoUser> signInWithGoogle() => throw _unavailable;

  @override
  Future<void> signOut() async {}
}
