import 'package:shared_preferences/shared_preferences.dart';

/// 게임 전적 데이터
class GameStats {
  final int wins;
  final int losses;
  final int draws;
  final int currentStreak;
  final int bestStreak;

  const GameStats({
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
  });

  int get totalGames => wins + losses + draws;

  double get winRate => totalGames == 0 ? 0 : wins / totalGames * 100;

  GameStats recordWin() {
    final newStreak = currentStreak > 0 ? currentStreak + 1 : 1;
    return GameStats(
      wins: wins + 1,
      losses: losses,
      draws: draws,
      currentStreak: newStreak,
      bestStreak: newStreak > bestStreak ? newStreak : bestStreak,
    );
  }

  GameStats recordLoss() {
    final newStreak = currentStreak < 0 ? currentStreak - 1 : -1;
    return GameStats(
      wins: wins,
      losses: losses + 1,
      draws: draws,
      currentStreak: newStreak,
      bestStreak: bestStreak,
    );
  }

  GameStats recordDraw() {
    return GameStats(
      wins: wins,
      losses: losses,
      draws: draws + 1,
      currentStreak: 0,
      bestStreak: bestStreak,
    );
  }
}

/// SharedPreferences 기반 전적 저장/로드
class StatsService {
  static const _keyWins = 'stats_wins';
  static const _keyLosses = 'stats_losses';
  static const _keyDraws = 'stats_draws';
  static const _keyCurrentStreak = 'stats_currentStreak';
  static const _keyBestStreak = 'stats_bestStreak';

  static Future<GameStats> load() async {
    final prefs = await SharedPreferences.getInstance();
    return GameStats(
      wins: prefs.getInt(_keyWins) ?? 0,
      losses: prefs.getInt(_keyLosses) ?? 0,
      draws: prefs.getInt(_keyDraws) ?? 0,
      currentStreak: prefs.getInt(_keyCurrentStreak) ?? 0,
      bestStreak: prefs.getInt(_keyBestStreak) ?? 0,
    );
  }

  static Future<void> save(GameStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyWins, stats.wins);
    await prefs.setInt(_keyLosses, stats.losses);
    await prefs.setInt(_keyDraws, stats.draws);
    await prefs.setInt(_keyCurrentStreak, stats.currentStreak);
    await prefs.setInt(_keyBestStreak, stats.bestStreak);
  }

  static Future<GameStats> recordResult({required int? winner}) async {
    var stats = await load();
    if (winner == null) {
      stats = stats.recordDraw();
    } else if (winner == 0) {
      stats = stats.recordWin();
    } else {
      stats = stats.recordLoss();
    }
    await save(stats);
    return stats;
  }
}
