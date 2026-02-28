import 'package:engine/engine.dart';
import 'package:flutter/material.dart';

/// 점수판 위젯
class ScorePanel extends StatelessWidget {
  final List<HwatooCard> playerCaptured;
  final List<HwatooCard> aiCaptured;
  final int playerGoCount;
  final int aiGoCount;
  final int deckSize;
  final int currentPlayer;

  const ScorePanel({
    super.key,
    required this.playerCaptured,
    required this.aiCaptured,
    required this.playerGoCount,
    required this.aiGoCount,
    required this.deckSize,
    required this.currentPlayer,
  });

  @override
  Widget build(BuildContext context) {
    final playerScore = Scoring.totalScore(playerCaptured);
    final aiScore = Scoring.totalScore(aiCaptured);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // AI 점수
          _ScoreChip(
            label: 'AI',
            score: aiScore,
            goCount: aiGoCount,
            isActive: currentPlayer == 1,
          ),
          // 덱 잔여
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '남은 패',
                style: TextStyle(fontSize: 10, color: Colors.white54),
              ),
              Text(
                '$deckSize',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          // 플레이어 점수
          _ScoreChip(
            label: '나',
            score: playerScore,
            goCount: playerGoCount,
            isActive: currentPlayer == 0,
          ),
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final String label;
  final int score;
  final int goCount;
  final bool isActive;

  const _ScoreChip({
    required this.label,
    required this.score,
    required this.goCount,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade900 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isActive
            ? Border.all(color: Colors.greenAccent, width: 1.5)
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? Colors.greenAccent : Colors.white54,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '${score}점',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : Colors.white70,
            ),
          ),
          if (goCount > 0)
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade800, Colors.red.shade700],
                ),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.4),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${goCount}고',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '×${goCount + 1}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.amber,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
