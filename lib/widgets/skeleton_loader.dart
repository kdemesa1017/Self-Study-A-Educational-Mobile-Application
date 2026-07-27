import 'package:flutter/material.dart';

/// A lightweight, dependency-free placeholder shown while screen data loads.
class SkeletonLoader extends StatefulWidget {
  final Widget child;

  const SkeletonLoader({super.key, required this.child});

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder:
          (context, child) => Opacity(
            opacity: 0.45 + (_controller.value * 0.4),
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(
                  context,
                ).colorScheme.copyWith(surface: base),
              ),
              child: child!,
            ),
          ),
    );
  }
}

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: borderRadius ?? BorderRadius.circular(12),
    ),
  );
}

class PageSkeleton extends StatelessWidget {
  final bool list;

  const PageSkeleton({super.key, this.list = false});

  @override
  Widget build(BuildContext context) => SkeletonLoader(
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SkeletonBox(
          height: 112,
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        const SizedBox(height: 24),
        SkeletonBox(width: 160, height: 22),
        const SizedBox(height: 12),
        ...List.generate(
          list ? 5 : 3,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: SkeletonBox(height: 88),
          ),
        ),
      ],
    ),
  );
}

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) => SkeletonLoader(
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Center(
          child: SkeletonBox(
            width: 120,
            height: 120,
            borderRadius: BorderRadius.all(Radius.circular(60)),
          ),
        ),
        const SizedBox(height: 20),
        Center(child: SkeletonBox(width: 140, height: 22)),
        const SizedBox(height: 10),
        Center(child: SkeletonBox(width: 200, height: 16)),
        const SizedBox(height: 28),
        ...List.generate(
          4,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: SkeletonBox(height: 56),
          ),
        ),
      ],
    ),
  );
}
