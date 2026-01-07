import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/platform_service.dart';

/// NexusClip - لوحة الأسهم الافتراضية
/// Virtual D-Pad Widget
///
/// أزرار تحكم بالمؤشر (↑ ↓ ← →)
/// Cursor control buttons (↑ ↓ ← →)
class VirtualDPad extends StatelessWidget {
  final Function(CursorDirection)? onDirectionPressed;
  final double buttonSize;
  final Color? buttonColor;

  const VirtualDPad({
    super.key,
    this.onDirectionPressed,
    this.buttonSize = 56,
    this.buttonColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: buttonSize * 3 + 16,
      height: buttonSize * 3 + 16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // الزر العلوي / Up Button
          Positioned(
            top: 0,
            child: _DPadButton(
              icon: Icons.keyboard_arrow_up_rounded,
              direction: CursorDirection.up,
              onPressed: onDirectionPressed,
              size: buttonSize,
              color: buttonColor,
            ),
          ),
          
          // الزر السفلي / Down Button
          Positioned(
            bottom: 0,
            child: _DPadButton(
              icon: Icons.keyboard_arrow_down_rounded,
              direction: CursorDirection.down,
              onPressed: onDirectionPressed,
              size: buttonSize,
              color: buttonColor,
            ),
          ),
          
          // الزر الأيسر / Left Button
          Positioned(
            left: 0,
            child: _DPadButton(
              icon: Icons.keyboard_arrow_left_rounded,
              direction: CursorDirection.left,
              onPressed: onDirectionPressed,
              size: buttonSize,
              color: buttonColor,
            ),
          ),
          
          // الزر الأيمن / Right Button
          Positioned(
            right: 0,
            child: _DPadButton(
              icon: Icons.keyboard_arrow_right_rounded,
              direction: CursorDirection.right,
              onPressed: onDirectionPressed,
              size: buttonSize,
              color: buttonColor,
            ),
          ),
          
          // الزر المركزي / Center Button
          _CenterButton(
            size: buttonSize * 0.8,
            color: buttonColor,
          ),
        ],
      ),
    );
  }
}

/// زر اتجاه واحد
/// Single Direction Button
class _DPadButton extends StatefulWidget {
  final IconData icon;
  final CursorDirection direction;
  final Function(CursorDirection)? onPressed;
  final double size;
  final Color? color;

  const _DPadButton({
    required this.icon,
    required this.direction,
    this.onPressed,
    this.size = 56,
    this.color,
  });

  @override
  State<_DPadButton> createState() => _DPadButtonState();
}

class _DPadButtonState extends State<_DPadButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onPressed?.call(widget.direction);
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.primary;
    
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: _isPressed
                ? color.withValues(alpha: 0.3)
                : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isPressed
                  ? color
                  : AppColors.border.withValues(alpha: 0.5),
              width: _isPressed ? 2 : 1,
            ),
            boxShadow: _isPressed
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Icon(
            widget.icon,
            size: widget.size * 0.6,
            color: _isPressed ? color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// الزر المركزي
/// Center Button
class _CenterButton extends StatelessWidget {
  final double size;
  final Color? color;

  const _CenterButton({
    this.size = 44,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundLight,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.gamepad_rounded,
        size: size * 0.5,
        color: AppColors.textTertiary.withValues(alpha: 0.5),
      ),
    );
  }
}

/// لوحة D-Pad مصغرة (للشريط الجانبي)
/// Mini D-Pad (for side panel)
class MiniDPad extends StatelessWidget {
  final Function(CursorDirection)? onDirectionPressed;

  const MiniDPad({
    super.key,
    this.onDirectionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return VirtualDPad(
      onDirectionPressed: onDirectionPressed,
      buttonSize: 40,
    );
  }
}

/// لوحة D-Pad أفقية (للعرض الأفقي)
/// Horizontal D-Pad
class HorizontalDPad extends StatelessWidget {
  final Function(CursorDirection)? onDirectionPressed;
  final double buttonSize;

  const HorizontalDPad({
    super.key,
    this.onDirectionPressed,
    this.buttonSize = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DPadButton(
          icon: Icons.keyboard_arrow_left_rounded,
          direction: CursorDirection.left,
          onPressed: onDirectionPressed,
          size: buttonSize,
        ),
        const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DPadButton(
              icon: Icons.keyboard_arrow_up_rounded,
              direction: CursorDirection.up,
              onPressed: onDirectionPressed,
              size: buttonSize,
            ),
            const SizedBox(height: 8),
            _DPadButton(
              icon: Icons.keyboard_arrow_down_rounded,
              direction: CursorDirection.down,
              onPressed: onDirectionPressed,
              size: buttonSize,
            ),
          ],
        ),
        const SizedBox(width: 8),
        _DPadButton(
          icon: Icons.keyboard_arrow_right_rounded,
          direction: CursorDirection.right,
          onPressed: onDirectionPressed,
          size: buttonSize,
        ),
      ],
    );
  }
}
