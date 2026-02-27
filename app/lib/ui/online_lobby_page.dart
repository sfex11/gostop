import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/online_game_notifier.dart';
import 'online_game_page.dart';

/// 시그널링 서버 URL (배포 시 변경)
const kDefaultSignalingUrl = 'ws://localhost:3000';

/// P2P 대전 로비 화면
class OnlineLobbyPage extends ConsumerStatefulWidget {
  const OnlineLobbyPage({super.key});

  @override
  ConsumerState<OnlineLobbyPage> createState() => _OnlineLobbyPageState();
}

class _OnlineLobbyPageState extends ConsumerState<OnlineLobbyPage> {
  final _roomCodeController = TextEditingController();
  StreamSubscription<void>? _stateSub;

  @override
  void dispose() {
    _roomCodeController.dispose();
    _stateSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onlineGameProvider);
    final notifier = ref.read(onlineGameProvider.notifier);

    // 게임 시작되면 게임 페이지로 이동
    if (state.onlineState == OnlineState.playing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnlineGamePage()),
        );
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D1F0D),
      appBar: AppBar(
        title: const Text('P2P 대전'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 상태 메시지
              if (state.errorMessage != null)
                _ErrorBanner(message: state.errorMessage!),

              const SizedBox(height: 16),

              // 방 코드 표시 (방 생성 후)
              if (state.onlineState == OnlineState.waitingInRoom &&
                  state.roomCode != null)
                _RoomCodeDisplay(roomCode: state.roomCode!),

              // 매칭 대기 중
              if (state.onlineState == OnlineState.matchmaking)
                _WaitingIndicator(
                  message: '상대를 찾고 있습니다...',
                  onCancel: () => notifier.cancelMatchmaking(),
                ),

              // 연결 중
              if (state.onlineState == OnlineState.connecting)
                const _WaitingIndicator(message: 'P2P 연결 중...'),

              // 대기 중 (방 생성)
              if (state.onlineState == OnlineState.waitingInRoom)
                const _WaitingIndicator(message: '상대방 입장 대기 중...'),

              // 초기 상태: 옵션 선택
              if (state.onlineState == OnlineState.disconnected) ...[
                const Icon(
                  Icons.wifi_tethering,
                  size: 64,
                  color: Colors.white24,
                ),
                const SizedBox(height: 24),
                Text(
                  'P2P 온라인 대전',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '서버 없이 직접 연결하여 대전합니다',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),

                const SizedBox(height: 40),

                // === 방 만들기 ===
                SizedBox(
                  width: 280,
                  child: ElevatedButton.icon(
                    onPressed: () => notifier.createRoom(kDefaultSignalingUrl),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text(
                      '방 만들기',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // === 방 코드 입력 & 참가 ===
                SizedBox(
                  width: 280,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _roomCodeController,
                          textCapitalization: TextCapitalization.characters,
                          maxLength: 6,
                          style: const TextStyle(
                            fontSize: 18,
                            letterSpacing: 4,
                            color: Colors.white,
                          ),
                          decoration: InputDecoration(
                            hintText: '방 코드',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[A-Za-z0-9]'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final code = _roomCodeController.text.trim();
                          if (code.length >= 4) {
                            notifier.joinRoom(kDefaultSignalingUrl, code);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade800,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '참가',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 구분선
                SizedBox(
                  width: 280,
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // === 랜덤 매칭 ===
                SizedBox(
                  width: 280,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        notifier.startMatchmaking(kDefaultSignalingUrl),
                    icon: const Icon(Icons.shuffle, color: Colors.amber),
                    label: const Text(
                      '랜덤 매칭',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.amber,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: Colors.amber.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 방 코드 표시 위젯
class _RoomCodeDisplay extends StatelessWidget {
  final String roomCode;

  const _RoomCodeDisplay({required this.roomCode});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '방 코드를 상대에게 알려주세요',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: roomCode));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('방 코드가 복사되었습니다'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.amber.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  roomCode,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                    letterSpacing: 8,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.copy,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// 대기 인디케이터
class _WaitingIndicator extends StatelessWidget {
  final String message;
  final VoidCallback? onCancel;

  const _WaitingIndicator({required this.message, this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        const CircularProgressIndicator(color: Colors.amber),
        const SizedBox(height: 16),
        Text(
          message,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        if (onCancel != null) ...[
          const SizedBox(height: 16),
          TextButton(
            onPressed: onCancel,
            child: const Text(
              '취소',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ],
    );
  }
}

/// 에러 배너
class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
