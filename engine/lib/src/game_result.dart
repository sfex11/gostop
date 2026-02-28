import 'card.dart';
import 'game_config.dart';
import 'game_state.dart';
import 'multiplier.dart';
import 'scoring.dart';

/// 게임 최종 정산 결과
class GameResult {
  /// 승자 인덱스 (null이면 무승부 — 덱 소진)
  final int? winner;

  /// 각 플레이어의 기본 점수
  final List<int> baseScores;

  /// 각 플레이어의 점수 상세
  final List<List<ScoringResult>> scoreDetails;

  /// 승자의 고 보너스
  final int goBonus;

  /// 배수 결과 (승자 기준)
  final MultiplierResult? multiplierResult;

  /// 최종 점수 (승자만 양수, 패자는 0)
  final List<int> finalScores;

  const GameResult({
    required this.winner,
    required this.baseScores,
    required this.scoreDetails,
    required this.goBonus,
    required this.multiplierResult,
    required this.finalScores,
  });

  /// GameState에서 최종 정산 수행
  factory GameResult.fromState(GameState state) {
    assert(state.phase == GamePhase.end);

    final config = state.config;
    final playerCount = state.playerCount;

    // 각 플레이어 기본 점수 계산
    final baseScores = <int>[];
    final scoreDetails = <List<ScoringResult>>[];
    for (var p = 0; p < playerCount; p++) {
      final details = Scoring.calculate(state.capturedCards[p], config: config);
      scoreDetails.add(details);
      baseScores.add(details.fold(0, (sum, r) => sum + r.points));
    }

    final winner = state.winner;
    final finalScores = List<int>.filled(playerCount, 0);
    MultiplierResult? multiplierResult;
    var goBonus = 0;

    if (winner != null) {
      goBonus = Multiplier.goBonus(state.goCount[winner]);

      // 2인 게임: 패자는 상대
      // 다인 게임: 최고 점수 패자 기준으로 배수 계산
      final loserIdx = winner == 0 ? 1 : 0;

      multiplierResult = Multiplier.calculate(
        winnerCaptured: state.capturedCards[winner],
        loserCaptured: state.capturedCards[loserIdx],
        winnerGoCount: state.goCount[winner],
        loserGoCount: state.goCount[loserIdx],
        winnerHadSwing: false, // TODO: 흔들기 상태 추적 추가 시 연동
        config: config,
      );

      final multiplier = multiplierResult.multiplier;
      finalScores[winner] = (baseScores[winner] + goBonus) * multiplier;
    } else {
      // 덱 소진 무승부: 각자 기본 점수만
      for (var p = 0; p < playerCount; p++) {
        finalScores[p] = baseScores[p];
      }
    }

    return GameResult(
      winner: winner,
      baseScores: baseScores,
      scoreDetails: scoreDetails,
      goBonus: goBonus,
      multiplierResult: multiplierResult,
      finalScores: finalScores,
    );
  }
}
