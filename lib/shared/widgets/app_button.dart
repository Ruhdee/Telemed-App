import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';

/// App-wide button widget matching the React `Button.tsx` component.
///
/// Supports 4 variants: primary (gold gradient), secondary (outlined white),
/// outline (transparent with gold border), glass (glassmorphism).
enum AppButtonVariant { primary, secondary, outline, glass }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final Widget? icon;
  final bool isLoading;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.width,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: _buildButton(context),
    )
        .animate()
        .fadeIn(duration: 200.ms)
        .then()
        .custom(
          duration: 100.ms,
          builder: (context, value, child) => child,
        );
  }

  Widget _buildButton(BuildContext context) {
    switch (variant) {
      case AppButtonVariant.primary:
        return _PrimaryButton(
          label: label,
          onPressed: onPressed,
          icon: icon,
          isLoading: isLoading,
          padding: padding,
        );
      case AppButtonVariant.secondary:
        return _SecondaryButton(
          label: label,
          onPressed: onPressed,
          icon: icon,
          isLoading: isLoading,
          padding: padding,
        );
      case AppButtonVariant.outline:
        return _OutlineButton(
          label: label,
          onPressed: onPressed,
          icon: icon,
          isLoading: isLoading,
          padding: padding,
        );
      case AppButtonVariant.glass:
        return _GlassButton(
          label: label,
          onPressed: onPressed,
          icon: icon,
          isLoading: isLoading,
          padding: padding,
        );
    }
  }
}

// ── Primary: Gold gradient button ──────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;

  const _PrimaryButton({
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      shadowColor: AppColors.goldPrimary.withValues(alpha: 0.3),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppColors.goldGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: _ButtonContent(
            label: label,
            icon: icon,
            isLoading: isLoading,
            textColor: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ── Secondary: White bg with gold border ───────────────────────

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;

  const _SecondaryButton({
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.goldDark,
        side: const BorderSide(color: AppColors.goldPrimary),
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _ButtonContent(
        label: label,
        icon: icon,
        isLoading: isLoading,
        textColor: AppColors.goldDark,
      ),
    );
  }
}

// ── Outline: Transparent with gold border ──────────────────────

class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;

  const _OutlineButton({
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.goldPrimary,
        side: const BorderSide(color: AppColors.goldPrimary, width: 2),
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _ButtonContent(
        label: label,
        icon: icon,
        isLoading: isLoading,
        textColor: AppColors.goldPrimary,
      ),
    );
  }
}

// ── Glass: Glassmorphism button ────────────────────────────────

class _GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;

  const _GlassButton({
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.glassBg,
        foregroundColor: AppColors.textPrimary,
        side: BorderSide(color: AppColors.glassBorder),
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _ButtonContent(
        label: label,
        icon: icon,
        isLoading: isLoading,
        textColor: AppColors.textPrimary,
      ),
    );
  }
}

// ── Shared button content ──────────────────────────────────────

class _ButtonContent extends StatelessWidget {
  final String label;
  final Widget? icon;
  final bool isLoading;
  final Color textColor;

  const _ButtonContent({
    required this.label,
    this.icon,
    required this.isLoading,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: textColor,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        if (icon != null) ...[
          const SizedBox(width: 8),
          icon!,
        ],
      ],
    );
  }
}
