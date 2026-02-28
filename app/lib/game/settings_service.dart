import 'package:engine/engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences 기반 설정 저장/로드
class SettingsService {
  static const _keyScoreThreshold = 'scoreThreshold';
  static const _keySsangpi = 'useSsangpi';
  static const _keyBomb = 'useBomb';
  static const _keySwing = 'useSwing';
  static const _keyChongtong = 'useChongtong';
  static const _keyPiSteal = 'usePiSteal';
  static const _keySweep = 'useSweep';
  static const _keyGwangBak = 'useGwangBak';
  static const _keyPiBak = 'usePiBak';
  static const _keyGoBak = 'useGoBak';
  static const _keyMungTung = 'useMungTung';
  static const _keyGodori = 'useGodori';

  static Future<GameConfig> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return GameConfig(
      scoreThreshold: prefs.getInt(_keyScoreThreshold) ?? 3,
      useSsangpi: prefs.getBool(_keySsangpi) ?? true,
      useBomb: prefs.getBool(_keyBomb) ?? true,
      useSwing: prefs.getBool(_keySwing) ?? true,
      useChongtong: prefs.getBool(_keyChongtong) ?? true,
      usePiSteal: prefs.getBool(_keyPiSteal) ?? true,
      useSweep: prefs.getBool(_keySweep) ?? true,
      useGwangBak: prefs.getBool(_keyGwangBak) ?? true,
      usePiBak: prefs.getBool(_keyPiBak) ?? true,
      useGoBak: prefs.getBool(_keyGoBak) ?? true,
      useMungTung: prefs.getBool(_keyMungTung) ?? true,
      useGodori: prefs.getBool(_keyGodori) ?? true,
    );
  }

  static Future<void> saveConfig(GameConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyScoreThreshold, config.scoreThreshold);
    await prefs.setBool(_keySsangpi, config.useSsangpi);
    await prefs.setBool(_keyBomb, config.useBomb);
    await prefs.setBool(_keySwing, config.useSwing);
    await prefs.setBool(_keyChongtong, config.useChongtong);
    await prefs.setBool(_keyPiSteal, config.usePiSteal);
    await prefs.setBool(_keySweep, config.useSweep);
    await prefs.setBool(_keyGwangBak, config.useGwangBak);
    await prefs.setBool(_keyPiBak, config.usePiBak);
    await prefs.setBool(_keyGoBak, config.useGoBak);
    await prefs.setBool(_keyMungTung, config.useMungTung);
    await prefs.setBool(_keyGodori, config.useGodori);
  }
}
