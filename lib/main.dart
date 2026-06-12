import 'package:flutter/material.dart';

import 'app/decko_app.dart';

void main() {
  // Required before any plugin (shared_preferences) is touched during startup.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DeckoApp());
}
