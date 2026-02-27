import 'package:engine/engine.dart';
import 'package:flutter/material.dart';

/// 게임 결과 다이얼로그
class ResultDialog extends StatelessWidget {
  final GameResult result;
  final VoidCallback onNewGame;
  final VoidCallback onBackToLobby;

  const ResultDialog({
    super.key,
    required this.result,
    required this.onNewGame,
    required this.onBackToLobby,
  });

  @override
  Widget build(BuildContext context) {
    final winner = result.winner;
    final isPlayerWin = winner == 0;
    final isDraw = winner == null;

    final playerScore = result.baseScores[0];
    final aiScore = result.baseScores[1];
    final playerDetails = result.scoreDetails[0];
    final aiDetails = result.scoreDetails[1];
    final multiplier = result.multiplierResult;

    // 최종 점수 (배수 적용)
    final playerFinal = result.finalScores[0];
    final aiFinal = result.finalScores[1];

    return AlertDialog(
      backgroundColor: const Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        isDraw
            ? '무승부'
            : isPlayerWin
                ? '승리!'
                : '패배',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: isDraw
              ? Colors.white70
              : isPlayerWin
                  ? Colors.amber
                  : Colors.red.shade300,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 점수 비교
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ScoreColumn('나', playerScore, playerFinal, playerDetails, isPlayerWin),
              const Text(
                'vs',
                style: TextStyle(color: Colors.white38, fontSize: 16),
              ),
              _ScoreColumn('AI', aiScore, aiFinal, aiDetails, !isPlayerWin && !isDraw),
            ],
          ),
          // 배수 정보
          if (multiplier != null && multiplier.reasons.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),
            Text(
              '배수: x${multiplier.multiplier}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children: multiplier.reasons
                  .map((r) => Chip(
                        label: Text(
                          _multiplierName(r),
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor: Colors.orange.shade900,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ))
                  .toList(),
            ),
          ],
          // 고 보너스
          if (result.goBonus > 0) ...[
            const SizedBox(height: 8),
            Text(
              '고 보너스: +${result.goBonus}점',
              style: const TextStyle(color: Colors.greenAccent, fontSize: 14),
            ),
          ],
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: onBackToLobby,
          child: const Text('로비로'),
        ),
        ElevatedButton(
          onPressed: onNewGame,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
          ),
          child: const Text('다시 하기'),
        ),
      ],
    );
  }

  String _multiplierName(MultiplierType type) {
    return switch (type) {
      MultiplierType.piBak => '피박',
      MultiplierType.gwangBak => '광박',
      MultiplierType.goBak => '고박',
      MultiplierType.swing => '흔들기',
      MultiplierType.mungTung => '멍따',
    };
  }
}

class _ScoreColumn extends StatelessWidget {
  final String label;
  final int baseScore;
  final int finalScore;
  final List<ScoringResult> details;
  final bool isWinner;

  const _ScoreColumn(this.label, this.baseScore, this.finalScore, this.details, this.isWinner);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isWinner ? Colors.amber : Colors.white54,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '${finalScore}점',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isWinner ? Colors.amber : Colors.white70,
          ),
        ),
        if (finalScore != baseScore)
          Text(
            '(기본 ${baseScore}점)',
            style: const TextStyle(fontSize: 11, color: Colors.white38),
          ),
        const SizedBox(height: 4),
        for (final d in details)
          Text(
            '${d.name} ${d.points}점',
            style: const TextStyle(fontSize: 11, color: Colors.white54),
          ),
      ],
    );
  }
}
