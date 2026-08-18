import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Staggered fade+slide entrance wrapper. Wrap any list item or section in
/// this with an increasing `index` to get a cascading reveal.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration baseDelay;
  const FadeSlideIn({super.key, required this.child, this.index = 0, this.baseDelay = const Duration(milliseconds: 45)});
  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  late final Animation<double> _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
  late final Animation<Offset> _slide =
      Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    final delay = widget.baseDelay * widget.index;
    Future.delayed(delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _fade, child: SlideTransition(position: _slide, child: widget.child));
  }
}

/// Animates numeric text counting up to `value` whenever it changes.
class AnimatedCounterText extends StatelessWidget {
  final double value;
  final TextStyle? style;
  final int decimals;
  final String suffix;
  const AnimatedCounterText({super.key, required this.value, this.style, this.decimals = 0, this.suffix = ''});
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text('${v.toStringAsFixed(decimals)}$suffix', style: style),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String durum;
  final String label;
  const StatusChip({super.key, required this.durum, required this.label});
  @override
  Widget build(BuildContext context) {
    final c = AppTheme.statusColor(durum);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
    );
  }
}

/// Rounded, hairline-bordered, softly-shadowed content card — the base
/// surface used throughout the redesign in place of the old flat white boxes.
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const SoftCard({super.key, required this.child, this.padding = const EdgeInsets.all(18)});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.035), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: child,
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(text.toUpperCase(),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.inkMuted)),
    );
  }
}

/// Animated horizontal gauge (0..1 fill ratio) used for limit thresholds.
class AnimatedGauge extends StatelessWidget {
  final double ratio;
  final Color color;
  const AnimatedGauge({super.key, required this.ratio, required this.color});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: ratio.clamp(0, 1)),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => Stack(children: [
          Container(height: 8, color: AppColors.line),
          FractionallySizedBox(widthFactor: v, child: Container(height: 8, color: color)),
        ]),
      ),
    );
  }
}
