import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app/app.dart';
import 'core/logging/logger.dart';
import 'core/storage/hive_boxes.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // ── Enable Firestore offline persistence ──────────────────────────────────
    // Docs are persisted to device storage and served from cache on cold starts,
    // making every screen that reads Firestore feel instant on re-open.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    logger.i('Firebase + Firestore persistence initialised');
  } catch (e) {
    logger.w('Firebase init issue: $e');
  }

  try {
    await HiveBoxes.init();
    logger.i('Hive Initialized');
  } catch (e) {
    logger.e('Failed to initialize Hive', error: e);
  }

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
