import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 효과음 종류
enum SoundEffect {
  cardPlay,
  cardCapture,
  sweep,
  go,
  stop,
  win,
  lose,
  tap,
}

/// 효과음 서비스 (싱글턴)
///
/// HapticFeedback 기반 — 외부 에셋 불필요, 웹/모바일 모두 동작.
/// 추후 실제 MP3 파일 추가 시 audioplayers로 전환 가능.
class SoundService {
  SoundService._();
  static final instance = SoundService._();

  bool _soundEnabled = true;

  bool get soundEnabled => _soundEnabled;

  /// 설정 로드
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
    } catch (_) {
      _soundEnabled = true;
    }
  }

  /// 효과음 재생 (햅틱 피드백)
  Future<void> play(SoundEffect effect) async {
    if (!_soundEnabled) return;
    try {
      switch (effect) {
        case SoundEffect.cardPlay:
        case SoundEffect.tap:
          await HapticFeedback.lightImpact();
        case SoundEffect.cardCapture:
          await HapticFeedback.mediumImpact();
        case SoundEffect.sweep:
        case SoundEffect.go:
          await HapticFeedback.heavyImpact();
        case SoundEffect.stop:
        case SoundEffect.win:
        case SoundEffect.lose:
          await HapticFeedback.vibrate();
      }
    } catch (e) {
      debugPrint('SoundService: haptic error: $e');
    }
  }

  /// 사운드 ON/OFF 토글
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sound_enabled', enabled);
    } catch (_) {}
  }

  void dispose() {}
}
