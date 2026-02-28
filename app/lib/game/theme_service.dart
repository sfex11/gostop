import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 테마 모드 관리 (Riverpod)
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    _load();
    return ThemeMode.dark; // 기본값: 다크 모드
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value != null) {
      final mode = ThemeMode.values.firstWhere(
        (m) => m.name == value,
        orElse: () => ThemeMode.dark,
      );
      state = mode;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }

  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(next);
  }
}

/// 테마 모드 Provider
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

/// 게임 보드 색상 (테마 인식)
class GameColors {
  /// 게임 보드 배경색
  static Color boardBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1B3A1B)
        : const Color(0xFF4CAF50);
  }

  /// 로비 배경색
  static Color lobbyBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0D1F0D)
        : const Color(0xFFF5F5F5);
  }

  /// 메시지 바 텍스트 색상
  static Color messageText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.amber
        : Colors.orange.shade800;
  }

  /// 섹션 라벨 색상
  static Color sectionLabel(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white38
        : Colors.black38;
  }
}
