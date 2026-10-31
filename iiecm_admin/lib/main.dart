import 'dart:developer' as developer;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/network/supabase_client.dart';
import 'diagnostic_render_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Isolated diagnostic mode switch (activated via --dart-define=DIAGNOSTIC_MODE=true)
  const bool isDiagnosticMode = bool.fromEnvironment('DIAGNOSTIC_MODE', defaultValue: false);
  if (isDiagnosticMode) {
    runApp(const IIECMRenderDiagnosticApp());
    return;
  }

  // 1. Framework error reporting for rendering diagnostics in debug console
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    developer.log(
      'FlutterError: ${details.exceptionAsString()}',
      name: 'FlutterFramework',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  // 2. Global asynchronous error handling
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    developer.log(
      'PlatformDispatcher unhandled error: $error',
      name: 'PlatformDispatcher',
      error: error,
      stackTrace: stack,
    );
    return true;
  };

  // 3. Fallback widget builder so any rendering failure displays a visible error banner
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Rendering Error',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F2744),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  details.exceptionAsString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  // Initialize Supabase backend if environment parameters are supplied
  await AppSupabase.initialize();

  // Native Android transparent status & navigation bars
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    const ProviderScope(
      child: IIECMAdminApp(),
    ),
  );
}
