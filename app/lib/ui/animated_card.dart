import 'dart:math' as math;

import 'package:engine/engine.dart';
import 'package:flutter/material.dart';

import 'card_painter.dart';

/// 카드 뒤집기 애니메이션 위젯
class FlipCard extends StatefulWidget {
  final HwatooCard card;
  final double width;
  final double height;
  final bool showFront;
  final Duration duration;
  final VoidCallback? onFlipComplete;

  const FlipCard({
    super.key,
    required this.card,
    this.width = 52,
    this.height = 72,
    this.showFront = false,
    this.duration = const Duration(milliseconds: 400),
    this.onFlipComplete,
  });

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showFront = false;

  @override
  void initState() {
    super.initState();
    _showFront = widget.showFront;
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showFront != oldWidget.showFront) {
      if (widget.showFront) {
        _controller.forward().then((_) => widget.onFlipComplete?.call());
      } else {
        _controller.reverse().then((_) => widget.onFlipComplete?.call());
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final angle = _animation.value * math.pi;
        final isFront = angle > math.pi / 2;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // 원근감
            ..rotateY(angle),
          child: isFront
              ? HwatooCardFace(
                  card: widget.card,
                  width: widget.width,
                  height: widget.height,
                )
              : HwatooCardBack(
                  width: widget.width,
                  height: widget.height,
                ),
        );
      },
    );
  }
}

/// 쓸(sweep) 시각 효과 오버레이
class SweepEffectOverlay extends StatefulWidget {
  final VoidCallback? onComplete;

  const SweepEffectOverlay({super.key, this.onComplete});

  @override
  State<SweepEffectOverlay> createState() => _SweepEffectOverlayState();
}

class _SweepEffectOverlayState extends State<SweepEffectOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );
    _controller.forward().then((_) => widget.onComplete?.call());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade900.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber, width: 2),
              ),
              child: const Text(
                '쓸!',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 고/스톱 결정 텍스트 애니메이션
class GoStopBanner extends StatefulWidget {
  final bool isGo;
  final int goCount;
  final VoidCallback? onComplete;

  const GoStopBanner({
    super.key,
    required this.isGo,
    this.goCount = 1,
    this.onComplete,
  });

  @override
  State<GoStopBanner> createState() => _GoStopBannerState();
}

class _GoStopBannerState extends State<GoStopBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
      ),
    );
    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
      ),
    );
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );
    _controller.forward().then((_) => widget.onComplete?.call());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.isGo
                        ? [Colors.orange.shade800, Colors.orange.shade600]
                        : [Colors.red.shade800, Colors.red.shade600],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (widget.isGo ? Colors.orange : Colors.red)
                          .withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  widget.isGo ? '${widget.goCount}고!' : '스톱!',
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
