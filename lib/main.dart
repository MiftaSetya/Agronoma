import 'package:flutter/material.dart';

import 'package:frontend/app.dart';

/// Titik masuk aplikasi.
///
/// Sengaja hanya satu baris: seluruh penyusunan provider, tema, dan rute ada di
/// `app.dart`. Berkas ini tidak perlu disentuh lagi saat fitur bertambah.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AgronomaApp());
}
