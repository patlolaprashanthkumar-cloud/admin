import 'package:flutter/material.dart';
import 'diagnostic_render_app.dart';

/// Temporary diagnostic entry point to isolate the Flutter Android rendering pipeline
/// Bypasses all asynchronous Supabase initialization, Riverpod, and GoRouter routing.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IIECMRenderDiagnosticApp());
}

