import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A modern background with study-themed image and gradient overlay for auth screens.
/// Uses unfocus-on-tap to help prevent Flutter web input focus errors.
class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  static const String _bgImageUrl =
      'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?w=800&q=75';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF111827) : Colors.white;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          CachedNetworkImage(
            imageUrl: _bgImageUrl,
            fit: BoxFit.cover,
            placeholder:
                (context, imageUrl) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.15),
                        Theme.of(
                          context,
                        ).colorScheme.secondary.withValues(alpha: 0.08),
                      ],
                    ),
                  ),
                ),
            errorWidget:
                (context, imageUrl, error) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.15),
                        Theme.of(
                          context,
                        ).colorScheme.secondary.withValues(alpha: 0.08),
                      ],
                    ),
                  ),
                ),
          ),
          // Gradient overlay for readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  surfaceColor.withValues(alpha: 0.92),
                  surfaceColor.withValues(alpha: 0.96),
                ],
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
