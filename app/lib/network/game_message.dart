import 'dart:convert';

import 'package:engine/engine.dart';

/// P2P 게임 메시지 타입
enum GameMessageType {
  /// Host → Client: 게임 초기 상태 (덱 시드, 설정)
  gameInit,

  /// 카드 플레이 (손패 → 바닥)
  playCard,

  /// 2장 매칭 선택
  selectMatch,

  /// 캡처 2장 매칭 선택
  selectCaptureMatch,

  /// 고 선택
  chooseGo,

  /// 스톱 선택
  chooseStop,

  /// 게임 상태 해시 (동기화 검증)
  stateHash,

  /// 연결 유지 확인
  ping,

  /// 핑 응답
  pong,

  /// 에러/재동기화 요청
  syncRequest,

  /// Host → Client: 전체 상태 강제 동기화
  fullSync,
}

/// P2P 게임 메시지 (JSON 직렬화 가능)
class GameMessage {
  final GameMessageType type;
  final int turn;
  final int player;
  final Map<String, dynamic>? data;
  final int timestamp;

  GameMessage({
    required this.type,
    required this.turn,
    required this.player,
    this.data,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  /// 카드 플레이 메시지 생성
  factory GameMessage.playCard({
    required int turn,
    required int player,
    required String cardName,
    String? chosenMatchName,
  }) {
    return GameMessage(
      type: GameMessageType.playCard,
      turn: turn,
      player: player,
      data: {
        'card': cardName,
        if (chosenMatchName != null) 'chosenMatch': chosenMatchName,
      },
    );
  }

  /// 매칭 선택 메시지 생성
  factory GameMessage.selectMatch({
    required int turn,
    required int player,
    required String chosenCardName,
  }) {
    return GameMessage(
      type: GameMessageType.selectMatch,
      turn: turn,
      player: player,
      data: {'chosenMatch': chosenCardName},
    );
  }

  /// 캡처 매칭 선택 메시지 생성
  factory GameMessage.selectCaptureMatch({
    required int turn,
    required int player,
    required String chosenCardName,
  }) {
    return GameMessage(
      type: GameMessageType.selectCaptureMatch,
      turn: turn,
      player: player,
      data: {'chosenMatch': chosenCardName},
    );
  }

  /// 고 선택 메시지 생성
  factory GameMessage.chooseGo({
    required int turn,
    required int player,
  }) {
    return GameMessage(
      type: GameMessageType.chooseGo,
      turn: turn,
      player: player,
    );
  }

  /// 스톱 선택 메시지 생성
  factory GameMessage.chooseStop({
    required int turn,
    required int player,
  }) {
    return GameMessage(
      type: GameMessageType.chooseStop,
      turn: turn,
      player: player,
    );
  }

  /// 게임 초기화 메시지 (Host → Client)
  factory GameMessage.gameInit({
    required int seed,
    required Map<String, dynamic> config,
  }) {
    return GameMessage(
      type: GameMessageType.gameInit,
      turn: 0,
      player: 0,
      data: {
        'seed': seed,
        'config': config,
      },
    );
  }

  /// 상태 해시 검증 메시지
  factory GameMessage.stateHash({
    required int turn,
    required int player,
    required String hash,
  }) {
    return GameMessage(
      type: GameMessageType.stateHash,
      turn: turn,
      player: player,
      data: {'hash': hash},
    );
  }

  factory GameMessage.ping() {
    return GameMessage(
      type: GameMessageType.ping,
      turn: 0,
      player: -1,
    );
  }

  factory GameMessage.pong() {
    return GameMessage(
      type: GameMessageType.pong,
      turn: 0,
      player: -1,
    );
  }

  /// JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'turn': turn,
      'player': player,
      'data': data,
      'ts': timestamp,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  /// JSON 역직렬화
  factory GameMessage.fromJson(Map<String, dynamic> json) {
    return GameMessage(
      type: GameMessageType.values.byName(json['type'] as String),
      turn: json['turn'] as int,
      player: json['player'] as int,
      data: json['data'] as Map<String, dynamic>?,
      timestamp: json['ts'] as int?,
    );
  }

  factory GameMessage.fromJsonString(String jsonStr) {
    return GameMessage.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
  }
}

/// 카드 이름 ↔ HwatooCard 변환 유틸리티
class CardSerializer {
  static final Map<String, HwatooCard> _nameToCard = {
    for (final card in Cards.all) card.name: card,
  };

  /// 카드 이름으로 HwatooCard 검색
  static HwatooCard? fromName(String name) => _nameToCard[name];

  /// HwatooCard를 이름 문자열로 변환
  static String toName(HwatooCard card) => card.name;

  /// 카드 리스트 직렬화
  static List<String> serializeCards(List<HwatooCard> cards) {
    return cards.map(toName).toList();
  }

  /// 카드 리스트 역직렬화
  static List<HwatooCard> deserializeCards(List<dynamic> names) {
    return names
        .map((n) => fromName(n as String))
        .whereType<HwatooCard>()
        .toList();
  }
}

/// GameConfig JSON 변환
extension GameConfigSerialization on GameConfig {
  Map<String, dynamic> toJson() {
    return {
      'scoreThreshold': scoreThreshold,
      'useSsangpi': useSsangpi,
      'useBomb': useBomb,
      'useSwing': useSwing,
      'useChongtong': useChongtong,
      'usePiSteal': usePiSteal,
      'useSweep': useSweep,
      'useGwangBak': useGwangBak,
      'usePiBak': usePiBak,
      'useGoBak': useGoBak,
      'useMungTung': useMungTung,
      'useGodori': useGodori,
    };
  }

  static GameConfig fromJson(Map<String, dynamic> json) {
    return GameConfig(
      scoreThreshold: json['scoreThreshold'] as int? ?? 3,
      useSsangpi: json['useSsangpi'] as bool? ?? true,
      useBomb: json['useBomb'] as bool? ?? true,
      useSwing: json['useSwing'] as bool? ?? true,
      useChongtong: json['useChongtong'] as bool? ?? true,
      usePiSteal: json['usePiSteal'] as bool? ?? true,
      useSweep: json['useSweep'] as bool? ?? true,
      useGwangBak: json['useGwangBak'] as bool? ?? true,
      usePiBak: json['usePiBak'] as bool? ?? true,
      useGoBak: json['useGoBak'] as bool? ?? true,
      useMungTung: json['useMungTung'] as bool? ?? true,
      useGodori: json['useGodori'] as bool? ?? true,
    );
  }
}
