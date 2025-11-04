import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../utils/constants.dart';

enum ButtonType { primary, secondary, outlined, text }

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isLoading;
  final Widget? icon;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;

    Widget buttonChild = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        else if (icon != null) ...[
          icon!,
          const SizedBox(width: 8),
        ],
        if (!isLoading)
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
      ],
    );

    Widget button;

    switch (type) {
      case ButtonType.primary:
        button = ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            disabledBackgroundColor: AppTheme.primaryBlue.withOpacity(0.5),
            foregroundColor: Colors.white,
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            minimumSize: Size(width ?? 0, height ?? 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: buttonChild,
        );
        break;

      case ButtonType.secondary:
        button = ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.cardDark,
            disabledBackgroundColor: AppTheme.cardDark.withOpacity(0.5),
            foregroundColor: AppTheme.textPrimary,
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            minimumSize: Size(width ?? 0, height ?? 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: buttonChild,
        );
        break;

      case ButtonType.outlined:
        button = OutlinedButton(
          onPressed: isDisabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryBlue,
            disabledForegroundColor: AppTheme.primaryBlue.withOpacity(0.5),
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            minimumSize: Size(width ?? 0, height ?? 48),
            side: BorderSide(
              color: isDisabled
                  ? AppTheme.primaryBlue.withOpacity(0.5)
                  : AppTheme.primaryBlue,
              width: 2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: buttonChild,
        );
        break;

      case ButtonType.text:
        button = TextButton(
          onPressed: isDisabled ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primaryBlue,
            disabledForegroundColor: AppTheme.primaryBlue.withOpacity(0.5),
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            minimumSize: Size(width ?? 0, height ?? 40),
          ),
          child: buttonChild,
        );
        break;
    }

    if (width != null) {
      button = SizedBox(
        width: width,
        child: button,
      );
    }

    return button
        .animate()
        .fadeIn(duration: AppConstants.mediumAnimation)
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: AppConstants.mediumAnimation,
        );
  }
}