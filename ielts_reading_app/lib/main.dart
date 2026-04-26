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
    logger.i('Firebase Initialized');
  } catch (e) {
    logger.w('Firebase initialization failed (maybe already initialized?): $e');
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
