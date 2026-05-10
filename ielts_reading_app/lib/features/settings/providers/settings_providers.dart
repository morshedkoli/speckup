import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kThemeModeKey = 'theme_mode';

// ─── Theme Mode Provider ──────────────────────────────────────────────────────

class ThemeModeNotifier extends AsyncNotifier<ThemeMode> {
  final _storage = const FlutterSecureStorage();

  @override
  Future<ThemeMode> build() async {
    final saved = await _storage.read(key: _kThemeModeKey);
    return switch (saved) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };
  }

  Future<void> setMode(ThemeMode mode) async {
    await _storage.write(
      key: _kThemeModeKey,
      value: switch (mode) {
        ThemeMode.dark => 'dark',
        ThemeMode.light => 'light',
        _ => 'system',
      },
    );
    state = AsyncValue.data(mode);
  }

  Future<void> toggle() async {
    final current = state.asData?.value ?? ThemeMode.system;
    final next = current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setMode(next);
  }
}

final themeModeProvider =
    AsyncNotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
