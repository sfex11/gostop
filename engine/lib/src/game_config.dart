/// 고스톱 게임 규칙 설정 (모든 규칙 Config화)
class GameConfig {
  /// Go/Stop 점수 기준
  final int scoreThreshold;

  /// 쌍피 규칙 사용
  final bool useSsangpi;

  /// 폭탄(뻑) 규칙 사용
  final bool useBomb;

  /// 흔들기 규칙 사용
  final bool useSwing;

  /// 총통 규칙 사용
  final bool useChongtong;

  /// 피 뺏기 규칙 사용 (한 턴에 쓸 시)
  final bool usePiSteal;

  /// 쓸(싹쓸이) 규칙 사용
  final bool useSweep;

  /// 배수: 광박
  final bool useGwangBak;

  /// 배수: 피박
  final bool usePiBak;

  /// 배수: 고박
  final bool useGoBak;

  /// 배수: 멍따
  final bool useMungTung;

  /// 고도리 규칙 사용
  final bool useGodori;

  const GameConfig({
    this.scoreThreshold = 3,
    this.useSsangpi = true,
    this.useBomb = true,
    this.useSwing = true,
    this.useChongtong = true,
    this.usePiSteal = true,
    this.useSweep = true,
    this.useGwangBak = true,
    this.usePiBak = true,
    this.useGoBak = true,
    this.useMungTung = true,
    this.useGodori = true,
  });

  /// 서울 표준룰 (기본값)
  static const standard = GameConfig();

  /// 빠른 게임 (7점제, 특수 규칙 최소화)
  static const fast = GameConfig(
    scoreThreshold: 7,
    useSwing: false,
    useChongtong: false,
    useMungTung: false,
  );
}
