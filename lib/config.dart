/// Build-time configuration. Secrets come in via `--dart-define-from-file=.env`
/// (the `.env` file is gitignored) — never hard-coded in source.
///
/// Run/build with: `flutter run --dart-define-from-file=.env`.
library;

/// Base URL of the Bunburu Japanese tokenizer micro-service (kuromoji).
const String kBunburuApiUrl = String.fromEnvironment(
  'BUNBURU_API_URL',
  defaultValue: 'https://bunburu.appsparkle.org',
);

/// App key for the tokenizer service. Empty when not provided — the sentence
/// builder surfaces a clear "tokenizer unavailable" state rather than crashing.
const String kBunburuAppKey = String.fromEnvironment('BUNBURU_APP_KEY');

/// Whether the tokenizer service is configured (a key was supplied).
bool get kTokenizerConfigured => kBunburuAppKey.isNotEmpty;
