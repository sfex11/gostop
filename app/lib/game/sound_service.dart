import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 효과음 종류
enum SoundEffect {
  /// 카드 내기
  cardPlay('sounds/card_play.mp3'),

  /// 카드 획득 (매칭)
  cardCapture('sounds/card_capture.mp3'),

  /// 쓸 (싹쓸이)
  sweep('sounds/sweep.mp3'),

  /// 고 선택
  go('sounds/go.mp3'),

  /// 스톱 선택
  stop('sounds/stop.mp3'),

  /// 승리
  win('sounds/win.mp3'),

  /// 패배
  lose('sounds/lose.mp3'),

  /// 버튼 클릭
  tap('sounds/tap.mp3');

  final String assetPath;
  const SoundEffect(this.assetPath);
}

/// 효과음 서비스 (싱글턴)
class SoundService {
  SoundService._();
  static final instance = SoundService._();

  final _player = AudioPlayer();
  bool _soundEnabled = true;
  double _volume = 0.7;

  bool get soundEnabled => _soundEnabled;
  double get volume => _volume;

  /// 설정 로드
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('sound_enabled') ?? true;
    _volume = prefs.getDouble('sound_volume') ?? 0.7;
    await _player.setVolume(_volume);
  }

  /// 효과음 재생
  Future<void> play(SoundEffect effect) async {
    if (!_soundEnabled) return;
    try {
      await _player.stop();
      await _player.setSource(AssetSource(effect.assetPath));
      await _player.resume();
    } catch (_) {
      // 에셋 없을 때 무시 (개발 중)
    }
  }

  /// 사운드 ON/OFF 토글
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', enabled);
  }

  /// 볼륨 설정 (0.0 ~ 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _player.setVolume(_volume);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sound_volume', _volume);
  }

  void dispose() {
    _player.dispose();
  }
}
