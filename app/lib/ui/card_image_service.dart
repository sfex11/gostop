import 'package:engine/engine.dart';

/// 카드 이미지 스타일
enum CardImageStyle {
  classic, // 전통 화투 이미지
  simple, // 간소화 스타일
  widget, // 위젯 기반 렌더링 (이미지 없음)
}

/// 카드 → 이미지 경로 매핑
///
/// shanash/GoStop 레포 기준 파일명: {MM}_{N}.png
/// 각 월별 카드 순서: 0=광/동물, 1=띠(또는 동물), 2=피1, 3=피2(또는 쌍피)
class CardImageService {
  CardImageService._();
  static final instance = CardImageService._();

  CardImageStyle _style = CardImageStyle.classic;
  CardImageStyle get style => _style;
  set style(CardImageStyle s) => _style = s;

  /// 카드 이미지 에셋 경로 (null이면 위젯 렌더링 사용)
  String? imagePath(HwatooCard card) {
    if (_style == CardImageStyle.widget) return null;
    final dir = _style == CardImageStyle.classic ? 'classic' : 'simple';
    final key = _cardFileKey(card);
    if (key == null) return null;
    return 'assets/cards/$dir/$key';
  }

  /// 카드 뒷면 이미지 경로
  String? backImagePath() {
    if (_style == CardImageStyle.widget) return null;
    final dir = _style == CardImageStyle.classic ? 'classic' : 'simple';
    return 'assets/cards/$dir/back.png';
  }

  /// HwatooCard → 파일명 매핑
  static String? _cardFileKey(HwatooCard card) {
    final month = card.month.index + 1;
    final mm = month.toString().padLeft(2, '0');
    final idx = _cardIndex(card);
    if (idx == null) return null;
    return '${mm}_$idx.png';
  }

  /// 월 내 카드 인덱스 (0~3)
  static int? _cardIndex(HwatooCard card) => _indexMap[card.name];

  // 각 카드의 이름 → 월 내 인덱스 매핑
  // 순서: 0=광/동물(최고), 1=띠/동물(차순), 2=피1, 3=피2/쌍피
  static const _indexMap = <String, int>{
    // 1월 소나무
    '학': 0, // bright
    '송학홍단': 1, // ribbon
    '솔피1': 2,
    '솔피2': 3,
    // 2월 매화
    '꾀꼬리': 0, // animal
    '매화홍단': 1, // ribbon
    '매피1': 2,
    '매피2': 3,
    // 3월 벚꽃
    '막': 0, // bright
    '벚꽃홍단': 1, // ribbon
    '벚피1': 2,
    '벚피2': 3,
    // 4월 등나무
    '두견새': 0, // animal
    '등초단': 1, // ribbon
    '등피1': 2,
    '등피2': 3,
    // 5월 난초
    '다리': 0, // animal
    '난초단': 1, // ribbon
    '난피1': 2,
    '난피2': 3,
    // 6월 모란
    '나비': 0, // animal
    '모란청단': 1, // ribbon
    '모피1': 2,
    '모피2': 3,
    // 7월 싸리
    '멧돼지': 0, // animal
    '싸리초단': 1, // ribbon
    '싸리피1': 2,
    '싸리피2': 3,
    // 8월 억새
    '달': 0, // bright
    '기러기': 1, // animal
    '억새피1': 2,
    '억새피2': 3,
    // 9월 국화
    '국진': 0, // animal (cup)
    '국화청단': 1, // ribbon
    '국피1': 2,
    '국피2': 3,
    // 10월 단풍
    '사슴': 0, // animal
    '단풍청단': 1, // ribbon
    '단풍피1': 2,
    '단풍피2': 3,
    // 11월 오동
    '봉황': 0, // bright
    '오동쌍피': 1, // double junk
    '오동피1': 2,
    '오동피2': 3,
    // 12월 버들
    '비': 0, // bright
    '제비': 1, // animal
    '버들띠': 2, // ribbon
    '버들쌍피': 3, // double junk
  };
}
