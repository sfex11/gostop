import 'package:engine/engine.dart';
import 'package:flutter/material.dart';

import '../game/stats_service.dart';

/// 게임 결과 다이얼로그
class ResultDialog extends StatefulWidget {
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
  State<ResultDialog> createState() => _ResultDialogState();
}

class _ResultDialogState extends State<ResultDialog> {
  GameStats? _stats;

  @override
  void initState() {
    super.initState();
    _recordAndLoad();
  }

  Future<void> _recordAndLoad() async {
    final stats =
        await StatsService.recordResult(winner: widget.result.winner);
    if (mounted) setState(() => _stats = stats);
  }

  @override
  Widget build(BuildContext context) {
    final winner = widget.result.winner;
    final isPlayerWin = winner == 0;
    final isDraw = winner == null;

    final playerScore = widget.result.baseScores[0];
    final aiScore = widget.result.baseScores[1];
    final playerDetails = widget.result.scoreDetails[0];
    final aiDetails = widget.result.scoreDetails[1];
    final multiplier = widget.result.multiplierResult;

    final playerFinal = widget.result.finalScores[0];
    final aiFinal = widget.result.finalScores[1];

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
              _ScoreColumn(
                  '나', playerScore, playerFinal, playerDetails, isPlayerWin),
              const Text(
                'vs',
                style: TextStyle(color: Colors.white38, fontSize: 16),
              ),
              _ScoreColumn('AI', aiScore, aiFinal, aiDetails,
                  !isPlayerWin && !isDraw),
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
          if (widget.result.goBonus > 0) ...[
            const SizedBox(height: 8),
            Text(
              '고 보너스: +${widget.result.goBonus}점',
              style: const TextStyle(color: Colors.greenAccent, fontSize: 14),
            ),
          ],
          // 전적 표시
          if (_stats != null) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),
            _StatsBar(stats: _stats!),
          ],
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: widget.onBackToLobby,
          child: const Text('로비로'),
        ),
        ElevatedButton(
          onPressed: widget.onNewGame,
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

  const _ScoreColumn(
      this.label, this.baseScore, this.finalScore, this.details, this.isWinner);

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

/// 전적 요약 바
class _StatsBar extends StatelessWidget {
  final GameStats stats;

  const _StatsBar({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _StatChip('전적', '${stats.wins}승 ${stats.losses}패 ${stats.draws}무'),
        _StatChip('승률', '${stats.winRate.toStringAsFixed(0)}%'),
        if (stats.currentStreak > 0)
          _StatChip('연승', '${stats.currentStreak}연승')
        else if (stats.currentStreak < 0)
          _StatChip('연패', '${stats.currentStreak.abs()}연패')
        else
          _StatChip('최고', '${stats.bestStreak}연승'),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white38),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
