// MVP_024: first-run onboarding flag + controller.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:decko/app/onboarding_controller.dart';
import 'package:decko/data/shared_prefs_settings_repository.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  const SharedPrefsSettingsRepository settings = SharedPrefsSettingsRepository();

  test('onboarding flag defaults to false', () async {
    expect(await settings.getHasCompletedOnboarding(), isFalse);
  });

  test('onboarding completion persists true', () async {
    await settings.saveHasCompletedOnboarding(true);
    expect(await settings.getHasCompletedOnboarding(), isTrue);
    // A fresh repository (e.g. next launch) still reads true.
    expect(
        await const SharedPrefsSettingsRepository().getHasCompletedOnboarding(),
        isTrue);
  });

  test('controller.complete() flips state + persists', () async {
    final OnboardingController c =
        OnboardingController(settings, initial: false);
    expect(c.isComplete, isFalse);

    bool notified = false;
    c.addListener(() => notified = true);
    await c.complete();

    expect(c.isComplete, isTrue);
    expect(notified, isTrue);
    expect(await settings.getHasCompletedOnboarding(), isTrue);
  });

  test('an explicit initial value is honoured (no flash)', () {
    expect(OnboardingController(settings, initial: true).isComplete, isTrue);
    expect(OnboardingController(settings, initial: false).isComplete, isFalse);
  });

  test('completion is independent of auth — there is no reset path', () async {
    // The flag lives only in settings; nothing (including sign-out) clears it.
    await settings.saveHasCompletedOnboarding(true);
    expect(
        OnboardingController(settings, initial: true).isComplete, isTrue);
    // No method exists to set it back to false.
    expect(await settings.getHasCompletedOnboarding(), isTrue);
  });
}
