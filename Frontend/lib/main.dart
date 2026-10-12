import 'package:flutter/material.dart';

import 'package:frontend/app.dart';

/// Titik masuk aplikasi; seluruh penyusunan provider, tema, dan rute ada di
/// `app.dart`.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AgronomaApp());
}
