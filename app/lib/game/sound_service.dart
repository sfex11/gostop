import 'package:audioplayers/audioplayers.dart';
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

/// 효과음 스타일
enum SoundStyle {
  casual, // 캐주얼 게임 사운드
  traditional, // 전통 한국 사운드
  haptic, // 진동만 (에셋 불필요)
}

/// 효과음 서비스 (싱글턴)
///
/// audioplayers 기반 — MP3 에셋 재생 + 스타일 전환 지원.
/// haptic 모드 선택 시 HapticFeedback 으로 폴백.
class SoundService {
  SoundService._();
  static final instance = SoundService._();

  bool _soundEnabled = true;
  SoundStyle _style = SoundStyle.casual;
  final _players = <SoundEffect, AudioPlayer>{};

  bool get soundEnabled => _soundEnabled;
  SoundStyle get style => _style;

  /// 설정 로드
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      final styleIdx = prefs.getInt('sound_style') ?? 0;
      _style = SoundStyle.values[styleIdx.clamp(0, SoundStyle.values.length - 1)];
    } catch (_) {
      _soundEnabled = true;
      _style = SoundStyle.casual;
    }
  }

  /// 효과음 파일명 매핑
  static const _fileNames = <SoundEffect, String>{
    SoundEffect.cardPlay: 'card_play.mp3',
    SoundEffect.cardCapture: 'card_capture.mp3',
    SoundEffect.sweep: 'sweep.mp3',
    SoundEffect.go: 'go.mp3',
    SoundEffect.stop: 'stop.mp3',
    SoundEffect.win: 'win.mp3',
    SoundEffect.lose: 'lose.mp3',
    SoundEffect.tap: 'tap.mp3',
  };

  /// 효과음 재생
  Future<void> play(SoundEffect effect) async {
    if (!_soundEnabled) return;

    if (_style == SoundStyle.haptic) {
      await _playHaptic(effect);
      return;
    }

    try {
      final fileName = _fileNames[effect]!;
      final styleName = _style == SoundStyle.traditional ? 'traditional' : 'casual';
      final path = 'sounds/$styleName/$fileName';

      var player = _players[effect];
      if (player == null) {
        player = AudioPlayer();
        _players[effect] = player;
      }
      await player.stop();
      await player.play(AssetSource(path));
    } catch (e) {
      debugPrint('SoundService: audio error: $e');
      // 폴백: 진동
      await _playHaptic(effect);
    }
  }

  /// 햅틱 피드백 (폴백)
  Future<void> _playHaptic(SoundEffect effect) async {
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

  /// 사운드 스타일 변경
  Future<void> setStyle(SoundStyle style) async {
    _style = style;
    // 기존 플레이어 해제 (스타일 바뀌면 에셋 경로 변경)
    for (final p in _players.values) {
      p.dispose();
    }
    _players.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('sound_style', style.index);
    } catch (_) {}
  }

  void dispose() {
    for (final p in _players.values) {
      p.dispose();
    }
    _players.clear();
  }
}
