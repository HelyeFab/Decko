// Auth & sync foundation (MVP_020, DEC-029). A Decko cloud identity — kept
// behind a repository seam so screens never touch Firebase directly.

/// A signed-in Decko user (anonymous or full). Framework-light.
class DeckoUser {
  const DeckoUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.isAnonymous = false,
    this.createdAt,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool isAnonymous;
  final DateTime? createdAt;

  /// A user object always represents a signed-in identity (anon or full).
  bool get isSignedIn => true;

  /// A short greeting name: the display name's first word, else the email's
  /// local part, else a friendly default.
  String get greetingName {
    final String? dn = displayName?.trim();
    if (dn != null && dn.isNotEmpty) return dn.split(' ').first;
    final String? e = email;
    if (e != null && e.contains('@')) return e.split('@').first;
    return 'there';
  }

  /// The avatar initial (uppercased) for the no-photo fallback.
  String get initial {
    final String n = greetingName;
    return n.isEmpty ? '?' : n.substring(0, 1).toUpperCase();
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'uid': uid,
        if (email != null) 'email': email,
        if (displayName != null) 'displayName': displayName,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'isAnonymous': isAnonymous,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };
}
