import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_notifier.dart';
import 'game_page.dart';

/// 로비 (시작 화면)
class LobbyPage extends ConsumerWidget {
  const LobbyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            const SizedBox(height: 60),

            // AI 대전 버튼
            SizedBox(
              width: 220,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(gameProvider.notifier).newGame();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const GamePage()),
                  );
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

            // 온라인 대전 (미구현)
            SizedBox(
              width: 220,
              child: OutlinedButton(
                onPressed: null, // Phase 3에서 구현
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi, size: 24, color: Colors.white38),
                    const SizedBox(width: 10),
                    Text(
                      'P2P 대전',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 80),

            Text(
              'v0.1.0 — Phase 1',
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
