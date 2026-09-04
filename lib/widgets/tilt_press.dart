import 'package:flutter/material.dart';

/// Wraps [child] with a drag-responsive 3D "holographic card" tilt: the
/// card leans away from wherever the finger is, and springs back flat on
/// release. Falls back to a simple tap if the user doesn't drag.
class TiltPress extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const TiltPress({super.key, required this.child, this.onTap, this.borderRadius});

  @override
  State<TiltPress> createState() => _TiltPressState();
}

class _TiltPressState extends State<TiltPress> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  Offset _dragFraction = Offset.zero; // -1..1 in each axis
  Offset _targetFraction = Offset.zero;
  bool _pressed = false;
  Size _size = Size.zero;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateFromLocalPosition(Offset local) {
    if (_size.isEmpty) return;
    final dx = ((local.dx / _size.width) * 2 - 1).clamp(-1.0, 1.0);
    final dy = ((local.dy / _size.height) * 2 - 1).clamp(-1.0, 1.0);
    setState(() => _dragFraction = Offset(dx, dy));
  }

  void _springBack() {
    _targetFraction = _dragFraction;
    _controller
      ..value = 0
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (details) {
        _pressed = true;
        _size = (context.findRenderObject() as RenderBox?)?.size ?? Size.zero;
        _updateFromLocalPosition(details.localPosition);
      },
      onTapUp: (_) {
        _pressed = false;
        _springBack();
      },
      onTapCancel: () {
        _pressed = false;
        _springBack();
      },
      onPanStart: (details) {
        _pressed = true;
        _size = (context.findRenderObject() as RenderBox?)?.size ?? Size.zero;
        _updateFromLocalPosition(details.localPosition);
      },
      onPanUpdate: (details) => _updateFromLocalPosition(details.localPosition),
      onPanEnd: (_) {
        _pressed = false;
        _springBack();
      },
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) {
          final fraction = _pressed
              ? _dragFraction
              : Offset.lerp(_targetFraction, Offset.zero, Curves.elasticOut.transform(_controller.value))!;
          final scale = _pressed ? 0.97 : 0.97 + 0.03 * Curves.easeOut.transform(_controller.value.clamp(0, 1));
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.0014)
            ..rotateX(fraction.dy * -0.18)
            ..rotateY(fraction.dx * 0.18)
            ..scaleByDouble(scale, scale, scale, 1);
          return Transform(
            alignment: Alignment.center,
            transform: transform,
            child: child,
          );
        },
      ),
    );
  }
}
