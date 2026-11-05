import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A record that spins while music plays. With artwork, the cover becomes
/// the record label.
class VinylDisc extends StatefulWidget {
  final bool spinning;
  final String? artworkPath;
  final double size;

  const VinylDisc({
    super.key,
    required this.spinning,
    required this.size,
    this.artworkPath,
  });

  @override
  State<VinylDisc> createState() => _VinylDiscState();
}

class _VinylDiscState extends State<VinylDisc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  );

  @override
  void initState() {
    super.initState();
    if (widget.spinning) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant VinylDisc oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.spinning && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.spinning && _controller.isAnimating) {
      // Stop where it is, like lifting the needle.
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final labelSize = size * 0.36;
    final artwork = widget.artworkPath;

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: RotationTransition(
          turns: _controller,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(size: Size.square(size), painter: _VinylPainter()),
              ClipOval(
                child: SizedBox(
                  width: labelSize,
                  height: labelSize,
                  child: artwork != null && artwork.isNotEmpty
                      ? Image.file(
                          File(artwork),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const _RedLabel(),
                        )
                      : const _RedLabel(),
                ),
              ),
              // Spindle hole.
              Container(
                width: size * 0.028,
                height: size * 0.028,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Colors.white, Color(0xFF9E9E9E)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RedLabel extends StatelessWidget {
  const _RedLabel();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: Color(0xFFE53228)),
    );
  }
}

class _VinylPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    // Body.
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFF1C1C1C));

    // Fine grooves.
    final groove = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = Colors.white.withValues(alpha: 0.045);

    for (var r = radius * 0.42; r < radius * 0.97; r += radius * 0.018) {
      canvas.drawCircle(center, r, groove);
    }

    // Two soft light reflections, which make the rotation visible.
    final sheen = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.10),
          Colors.transparent,
          Colors.transparent,
          Colors.white.withValues(alpha: 0.10),
          Colors.transparent,
        ],
        stops: const [0.05, 0.13, 0.22, 0.55, 0.63, 0.72],
        transform: const GradientRotation(-math.pi / 4),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, sheen);

    // Dark ring around the label.
    canvas.drawCircle(
      center,
      radius * 0.235,
      Paint()..color = const Color(0xFF111111),
    );
  }

  @override
  bool shouldRepaint(covariant _VinylPainter oldDelegate) => false;
}
