import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// NexusClip - حاوية Glassmorphism
/// Glassmorphic Container
///
/// حاوية بتأثير الزجاج الضبابي المميز
/// Container with distinctive frosted glass effect
class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double blurAmount;
  final double opacity;

  const GlassmorphicContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.backgroundColor,
    this.borderColor,
    this.blurAmount = 10,
    this.opacity = 0.15,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurAmount,
            sigmaY: blurAmount,
          ),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor ?? AppColors.cardBackground.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? AppColors.border.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// حاوية Glassmorphism متدرجة
/// Gradient Glassmorphic Container
class GradientGlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Gradient? gradient;
  final double blurAmount;

  const GradientGlassmorphicContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.gradient,
    this.blurAmount = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurAmount,
            sigmaY: blurAmount,
          ),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: gradient ?? AppColors.glassGradient,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// حاوية Glassmorphism متوهجة
/// Glowing Glassmorphic Container
class GlowingGlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color glowColor;
  final double glowIntensity;
  final double blurAmount;

  const GlowingGlassmorphicContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.glowColor = AppColors.primary,
    this.glowIntensity = 0.3,
    this.blurAmount = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: glowIntensity),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurAmount,
            sigmaY: blurAmount,
          ),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: glowColor.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// حاوية Glassmorphism متحركة
/// Animated Glassmorphic Container
class AnimatedGlassmorphicContainer extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Duration animationDuration;

  const AnimatedGlassmorphicContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<AnimatedGlassmorphicContainer> createState() =>
      _AnimatedGlassmorphicContainerState();
}

class _AnimatedGlassmorphicContainerState
    extends State<AnimatedGlassmorphicContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
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
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: child,
          ),
        );
      },
      child: GlassmorphicContainer(
        padding: widget.padding,
        margin: widget.margin,
        borderRadius: widget.borderRadius,
        child: widget.child,
      ),
    );
  }
}
