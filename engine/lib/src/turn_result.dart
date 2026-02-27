import 'game_config.dart';

/// 턴 결과 (피 뺏기, 쓸 판정 등)
class TurnResult {
  /// 이번 턴에 획득한 카드 수
  final int capturedCount;

  /// 쓸(싹쓸이) 여부: 테이블에서 해당 월 카드를 전부 가져감
  final bool wasSweep;

  /// 게임 설정
  final GameConfig config;

  const TurnResult({
    required this.capturedCount,
    required this.wasSweep,
    required this.config,
  });

  /// 피 뺏기 수: 쓸이면 상대에게서 피 1장씩 빼앗음
  int get piStealCount {
    if (!config.usePiSteal) return 0;
    if (wasSweep) return 1;
    return 0;
  }
}
