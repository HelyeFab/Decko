import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/auth/auth_repository.dart';
import '../../domain/auth/auth_state.dart';
import '../../domain/auth/decko_user.dart';

/// Firebase-backed [AuthRepository] (MVP_020). Maps Firebase users + errors to
/// Decko's domain types so the UI never sees Firebase. Anonymous, email/
/// password, and Google sign-in.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _auth = auth ?? FirebaseAuth.instance,
        _google = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _google;
  bool _googleReady = false;

  @override
  Stream<AuthState> authStateChanges() => _auth.authStateChanges().map(
      (User? u) => AuthState(u == null ? null : _map(u)));

  @override
  DeckoUser? get currentUser {
    final User? u = _auth.currentUser;
    return u == null ? null : _map(u);
  }

  @override
  Future<DeckoUser> signInAnonymously() =>
      _guard(() => _auth.signInAnonymously());

  @override
  Future<DeckoUser> signInWithEmail(String email, String password) =>
      _guard(() => _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password));

  @override
  Future<DeckoUser> createAccountWithEmail(String email, String password) =>
      _guard(() => _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password));

  @override
  Future<DeckoUser> signInWithGoogle() async {
    try {
      if (!_googleReady) {
        await _google.initialize();
        _googleReady = true;
      }
      if (!_google.supportsAuthenticate()) {
        throw const AuthException('Google sign-in isn’t supported here.');
      }
      final GoogleSignInAccount account = await _google.authenticate();
      final String? idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthException('Google sign-in failed — please try again.');
      }
      final OAuthCredential credential =
          GoogleAuthProvider.credential(idToken: idToken);
      final UserCredential cred = await _auth.signInWithCredential(credential);
      return _map(cred.user!);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthException('Google sign-in cancelled.');
      }
      throw const AuthException('Google sign-in failed — please try again.');
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendly(e));
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _google.signOut();
    } catch (_) {/* best-effort */}
    await _auth.signOut();
  }

  Future<DeckoUser> _guard(Future<UserCredential> Function() op) async {
    try {
      final UserCredential cred = await op();
      return _map(cred.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendly(e));
    }
  }

  DeckoUser _map(User u) => DeckoUser(
        uid: u.uid,
        email: u.email,
        displayName: u.displayName,
        photoUrl: u.photoURL,
        isAnonymous: u.isAnonymous,
        createdAt: u.metadata.creationTime,
      );

  String _friendly(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'email-already-in-use':
        return 'That email already has an account — try signing in.';
      case 'weak-password':
        return 'Choose a stronger password (at least 6 characters).';
      case 'network-request-failed':
        return 'You appear to be offline. Check your connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'operation-not-allowed':
        return 'This sign-in method isn’t enabled yet.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
