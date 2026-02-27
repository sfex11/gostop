import 'package:engine/engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_notifier.dart';
import '../game/settings_service.dart';
import '../game/sound_service.dart';
import '../game/theme_service.dart';
import 'card_image_service.dart';

/// 게임 규칙 설정 화면
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late int _scoreThreshold;
  late bool _useSsangpi;
  late bool _useBomb;
  late bool _useSwing;
  late bool _useChongtong;
  late bool _usePiSteal;
  late bool _useSweep;
  late bool _useGwangBak;
  late bool _usePiBak;
  late bool _useGoBak;
  late bool _useMungTung;
  late bool _useGodori;

  @override
  void initState() {
    super.initState();
    final config = ref.read(gameProvider.notifier).config;
    _scoreThreshold = config.scoreThreshold;
    _useSsangpi = config.useSsangpi;
    _useBomb = config.useBomb;
    _useSwing = config.useSwing;
    _useChongtong = config.useChongtong;
    _usePiSteal = config.usePiSteal;
    _useSweep = config.useSweep;
    _useGwangBak = config.useGwangBak;
    _usePiBak = config.usePiBak;
    _useGoBak = config.useGoBak;
    _useMungTung = config.useMungTung;
    _useGodori = config.useGodori;
  }

  GameConfig _buildConfig() {
    return GameConfig(
      scoreThreshold: _scoreThreshold,
      useSsangpi: _useSsangpi,
      useBomb: _useBomb,
      useSwing: _useSwing,
      useChongtong: _useChongtong,
      usePiSteal: _usePiSteal,
      useSweep: _useSweep,
      useGwangBak: _useGwangBak,
      usePiBak: _usePiBak,
      useGoBak: _useGoBak,
      useMungTung: _useMungTung,
      useGodori: _useGodori,
    );
  }

  Future<void> _save() async {
    final config = _buildConfig();
    ref.read(gameProvider.notifier).setConfig(config);
    await SettingsService.saveConfig(config);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('설정이 저장되었습니다'),
          duration: Duration(seconds: 1),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  void _resetToStandard() {
    setState(() {
      _scoreThreshold = 3;
      _useSsangpi = true;
      _useBomb = true;
      _useSwing = true;
      _useChongtong = true;
      _usePiSteal = true;
      _useSweep = true;
      _useGwangBak = true;
      _usePiBak = true;
      _useGoBak = true;
      _useMungTung = true;
      _useGodori = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1F0D),
      appBar: AppBar(
        title: const Text('게임 규칙 설정'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _resetToStandard,
            child: const Text('초기화'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // === 점수 기준 ===
          _SectionHeader(title: '점수 기준'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '고/스톱 기준 점수: $_scoreThreshold점',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _scoreThreshold.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: '$_scoreThreshold점',
                  activeColor: Colors.green,
                  onChanged: (v) => setState(() => _scoreThreshold = v.round()),
                ),
                Text(
                  '이 점수에 도달하면 고/스톱을 선택합니다',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // === 특수 규칙 ===
          _SectionHeader(title: '특수 규칙'),
          Container(
            decoration: _cardDecoration(),
            child: Column(
              children: [
                _RuleToggle(
                  title: '쌍피',
                  subtitle: '쌍피 카드는 2피로 계산',
                  value: _useSsangpi,
                  onChanged: (v) => setState(() => _useSsangpi = v),
                ),
                _divider(),
                _RuleToggle(
                  title: '폭탄 (뻑)',
                  subtitle: '같은 월 3장이 바닥에 있을 때 4번째 카드로 전부 획득',
                  value: _useBomb,
                  onChanged: (v) => setState(() => _useBomb = v),
                ),
                _divider(),
                _RuleToggle(
                  title: '흔들기',
                  subtitle: '같은 월 카드 3장을 들고 있을 때 선언',
                  value: _useSwing,
                  onChanged: (v) => setState(() => _useSwing = v),
                ),
                _divider(),
                _RuleToggle(
                  title: '총통',
                  subtitle: '같은 월 카드 4장을 들고 있을 때 자동 승리',
                  value: _useChongtong,
                  onChanged: (v) => setState(() => _useChongtong = v),
                ),
                _divider(),
                _RuleToggle(
                  title: '피 뺏기',
                  subtitle: '쓸 했을 때 상대 피 1장 뺏기',
                  value: _usePiSteal,
                  onChanged: (v) => setState(() => _usePiSteal = v),
                ),
                _divider(),
                _RuleToggle(
                  title: '쓸 (싹쓸이)',
                  subtitle: '바닥 카드를 전부 가져가면 쓸',
                  value: _useSweep,
                  onChanged: (v) => setState(() => _useSweep = v),
                ),
                _divider(),
                _RuleToggle(
                  title: '고도리',
                  subtitle: '2월+4월+8월 동물 3장으로 5점',
                  value: _useGodori,
                  onChanged: (v) => setState(() => _useGodori = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // === 배수 규칙 ===
          _SectionHeader(title: '배수 규칙'),
          Container(
            decoration: _cardDecoration(),
            child: Column(
              children: [
                _RuleToggle(
                  title: '광박',
                  subtitle: '패자가 광을 하나도 못 먹으면 배수',
                  value: _useGwangBak,
                  onChanged: (v) => setState(() => _useGwangBak = v),
                ),
                _divider(),
                _RuleToggle(
                  title: '피박',
                  subtitle: '패자의 피가 기준 이하이면 배수',
                  value: _usePiBak,
                  onChanged: (v) => setState(() => _usePiBak = v),
                ),
                _divider(),
                _RuleToggle(
                  title: '고박',
                  subtitle: '고를 선언한 뒤 상대가 이기면 배수',
                  value: _useGoBak,
                  onChanged: (v) => setState(() => _useGoBak = v),
                ),
                _divider(),
                _RuleToggle(
                  title: '멍따',
                  subtitle: '광을 3장 이상 먹었지만 패배 시 배수',
                  value: _useMungTung,
                  onChanged: (v) => setState(() => _useMungTung = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // === 앱 설정 ===
          _SectionHeader(title: '앱 설정'),
          Container(
            decoration: _cardDecoration(),
            child: Column(
              children: [
                // 효과음 토글
                SwitchListTile(
                  title: const Text(
                    '효과음',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    '카드 효과음 재생',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  value: SoundService.instance.soundEnabled,
                  onChanged: (v) {
                    SoundService.instance.setSoundEnabled(v);
                    setState(() {});
                  },
                  activeColor: Colors.green,
                  dense: true,
                ),
                _divider(),
                // 효과음 스타일
                _OptionTile<SoundStyle>(
                  title: '효과음 스타일',
                  value: SoundService.instance.style,
                  items: const {
                    SoundStyle.casual: '캐주얼',
                    SoundStyle.traditional: '전통',
                    SoundStyle.haptic: '진동만',
                  },
                  onChanged: (v) {
                    SoundService.instance.setStyle(v);
                    setState(() {});
                  },
                ),
                _divider(),
                // 카드 이미지 스타일
                _OptionTile<CardImageStyle>(
                  title: '카드 스타일',
                  value: CardImageService.instance.style,
                  items: const {
                    CardImageStyle.classic: '클래식',
                    CardImageStyle.simple: '심플',
                    CardImageStyle.widget: '위젯',
                  },
                  onChanged: (v) {
                    CardImageService.instance.style = v;
                    setState(() {});
                  },
                ),
                _divider(),
                // 테마 토글
                SwitchListTile(
                  title: const Text(
                    '다크 모드',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    '화면 밝기 전환',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  value: ref.watch(themeModeProvider) == ThemeMode.dark,
                  onChanged: (v) {
                    ref.read(themeModeProvider.notifier).setThemeMode(
                      v ? ThemeMode.dark : ThemeMode.light,
                    );
                  },
                  activeColor: Colors.green,
                  dense: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // === 저장 버튼 ===
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '저장',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      color: Colors.white.withValues(alpha: 0.08),
      indent: 16,
      endIndent: 16,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.green.shade300,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _RuleToggle extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _RuleToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
      value: value,
      onChanged: (v) => onChanged(v),
      activeColor: Colors.green,
      dense: true,
    );
  }
}

/// 선택형 옵션 타일 (SegmentedButton)
class _OptionTile<T> extends StatelessWidget {
  final String title;
  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;

  const _OptionTile({
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          SegmentedButton<T>(
            segments: items.entries
                .map((e) => ButtonSegment<T>(value: e.key, label: Text(e.value)))
                .toList(),
            selected: {value},
            onSelectionChanged: (s) => onChanged(s.first),
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.green.shade700;
                }
                return Colors.white.withValues(alpha: 0.08);
              }),
              foregroundColor: WidgetStateProperty.all(Colors.white),
              textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12)),
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
