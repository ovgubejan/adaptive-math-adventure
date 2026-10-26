import 'package:flutter/material.dart';

import 'mascot_artwork.dart';
import 'mascot_state.dart';

class MascotWidget extends StatefulWidget {
  const MascotWidget({
    super.key,
    required this.state,
    this.celebrationId = 0,
    this.size = 220,
  });

  final MascotState state;
  final int celebrationId;
  final double size;

  @override
  State<MascotWidget> createState() => _MascotWidgetState();
}

class _MascotWidgetState extends State<MascotWidget>
    with TickerProviderStateMixin {
  late final AnimationController _idleController;
  late final AnimationController _celebrationController;
  late final Animation<double> _idleOffset;
  late final Animation<double> _celebrationScale;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _idleOffset = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOut),
    );
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _celebrationScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 1.18,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.18,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 55,
      ),
    ]).animate(_celebrationController);
    _syncIdleAnimation();
    _playCelebrationIfAllowed();
  }

  @override
  void didUpdateWidget(covariant MascotWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) _syncIdleAnimation();
    if (widget.state == MascotState.sleeping) {
      _celebrationController.reset();
    } else if (oldWidget.celebrationId != widget.celebrationId) {
      _playCelebrationIfAllowed();
    }
  }

  void _syncIdleAnimation() {
    if (widget.state == MascotState.sleeping) {
      _idleController.stop();
    } else {
      _idleController.repeat(reverse: true);
    }
  }

  void _playCelebrationIfAllowed() {
    if (widget.state == MascotState.happy) {
      _celebrationController.forward(from: 0);
    } else {
      _celebrationController.reset();
    }
  }

  @override
  void dispose() {
    _idleController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = switch (widget.state) {
      MascotState.idle => 'Mascot is idle',
      MascotState.happy => 'Mascot is happy',
      MascotState.encouraging => 'Mascot is encouraging',
      MascotState.sleeping => 'Mascot is sleeping',
    };
    return Semantics(
      label: label,
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _idleController,
          child: AnimatedBuilder(
            animation: _celebrationController,
            builder: (context, child) => Transform.scale(
              scale: _celebrationScale.value,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  child!,
                  if (_celebrationController.isAnimating &&
                      widget.state == MascotState.happy)
                    const Positioned(
                      right: 14,
                      top: 12,
                      child: Icon(
                        Icons.auto_awesome,
                        key: ValueKey('celebration-sparkle'),
                        color: Color(0xFFFFB938),
                        size: 38,
                      ),
                    ),
                ],
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: MascotArtwork(
                key: ValueKey<MascotState>(widget.state),
                state: widget.state,
              ),
            ),
          ),
          builder: (context, child) => Transform.translate(
            offset: Offset(0, _idleOffset.value),
            child: child,
          ),
        ),
      ),
    );
  }
}
