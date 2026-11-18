import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/network/supabase_client.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure native Android system overlays to match institutional branding
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Supabase in background without blocking first frame draw
  AppSupabase.initialize().catchError((e, stack) {
    developer.log(
      'Supabase initialization error: $e',
      name: 'main',
      error: e,
      stackTrace: stack,
    );
    return false;
  });

  // Present first frame immediately to satisfy Android 15 SurfaceSyncGroup
  runApp(const ProviderScope(child: IIECMAdminApp()));
}

