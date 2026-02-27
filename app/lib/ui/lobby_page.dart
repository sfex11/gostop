import 'package:engine/engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_notifier.dart';
import '../game/settings_service.dart';
import '../game/stats_service.dart';
import 'game_page.dart';
import 'online_lobby_page.dart';
import 'settings_page.dart';

/// 로비 (시작 화면)
class LobbyPage extends ConsumerStatefulWidget {
  const LobbyPage({super.key});

  @override
  ConsumerState<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends ConsumerState<LobbyPage> {
  GameStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadStats();
  }

  Future<void> _loadSettings() async {
    final config = await SettingsService.loadConfig();
    ref.read(gameProvider.notifier).setConfig(config);
  }

  Future<void> _loadStats() async {
    final stats = await StatsService.load();
    if (mounted) setState(() => _stats = stats);
  }

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(gameProvider);
    final difficulty = uiState.difficulty;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1F0D),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 타이틀
            const Text(
              '고스톱',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '2인 맞고',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),

            // 전적 표시
            if (_stats != null && _stats!.totalGames > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _LobbyStatChip(
                        '${_stats!.wins}', '승', Colors.greenAccent),
                    const SizedBox(width: 16),
                    _LobbyStatChip(
                        '${_stats!.losses}', '패', Colors.red.shade300),
                    const SizedBox(width: 16),
                    _LobbyStatChip(
                        '${_stats!.draws}', '무', Colors.white54),
                    const SizedBox(width: 20),
                    Text(
                      '승률 ${_stats!.winRate.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    if (_stats!.bestStreak > 0) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade900,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '최고 ${_stats!.bestStreak}연승',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 40),

            // 난이도 선택
            Text(
              'AI 난이도',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<AiDifficulty>(
              segments: const [
                ButtonSegment(
                  value: AiDifficulty.easy,
                  label: Text('쉬움'),
                  icon: Icon(Icons.sentiment_satisfied, size: 18),
                ),
                ButtonSegment(
                  value: AiDifficulty.normal,
                  label: Text('보통'),
                  icon: Icon(Icons.sentiment_neutral, size: 18),
                ),
                ButtonSegment(
                  value: AiDifficulty.hard,
                  label: Text('어려움'),
                  icon: Icon(Icons.sentiment_very_dissatisfied, size: 18),
                ),
              ],
              selected: {difficulty},
              onSelectionChanged: (selected) {
                ref.read(gameProvider.notifier).setDifficulty(selected.first);
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color(0xFF2E7D32);
                  }
                  return Colors.transparent;
                }),
              ),
            ),

            const SizedBox(height: 32),

            // AI 대전 버튼
            SizedBox(
              width: 220,
              child: ElevatedButton(
                onPressed: () async {
                  ref.read(gameProvider.notifier).newGame();
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const GamePage()),
                  );
                  _loadStats(); // 게임 후 전적 갱신
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.smart_toy, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'AI 대전',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 온라인 대전
            SizedBox(
              width: 220,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const OnlineLobbyPage()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi, size: 24, color: Colors.amber),
                    SizedBox(width: 10),
                    Text(
                      'P2P 대전',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 설정 버튼
            SizedBox(
              width: 220,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.settings, size: 24, color: Colors.white54),
                    SizedBox(width: 10),
                    Text(
                      '규칙 설정',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 60),

            Text(
              'v0.5.0 — Assets & Polish',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LobbyStatChip extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _LobbyStatChip(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
