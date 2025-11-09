import 'package:flutter/material.dart';


class AppGradients {
  static const LinearGradient primary = LinearGradient(
    colors: [Color(0xFF5B6CF3), Color(0xFF8B6CF3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient soft = LinearGradient(
    colors: [Color(0xFFFFC4EB), Color(0xFFD7C4FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Nút primary
class ButtonPrimary extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Widget? leading;
  final Widget? trailing;
  final double? width;
  final double? height;

  const ButtonPrimary({
    super.key,
    required this.text,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.borderRadius = 12,
    this.leading,
    this.trailing,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return _GradientButtonBase(
      text: text,
      onTap: onTap,
      gradient: AppGradients.primary,
      padding: padding,
      borderRadius: borderRadius,
      leading: leading,
      trailing: trailing,
      width: width,
      height: height,
      textStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
    );
  }
}

/// Nút soft
class ButtonSoft extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Widget? leading;
  final Widget? trailing;

  const ButtonSoft({
    super.key,
    required this.text,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.borderRadius = 12,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return _GradientButtonBase(
      text: text,
      onTap: onTap,
      gradient: AppGradients.soft,
      padding: padding,
      borderRadius: borderRadius,
      leading: leading,
      trailing: trailing,
      textStyle: const TextStyle(
        color: Color(0xFF2B2B2B),
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    );
  }
}

/// Base cho các loại nút
class _GradientButtonBase extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final LinearGradient gradient;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Widget? leading;
  final Widget? trailing;
  final TextStyle textStyle;
  final double? width;
  final double? height;

  const _GradientButtonBase({
    required this.text,
    required this.onTap,
    required this.gradient,
    required this.padding,
    required this.borderRadius,
    required this.textStyle,
    this.leading,
    this.trailing,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 8)],
        Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: textStyle)),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );

    final child = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(child: row),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, child: child),
      ),
    );
  }
}

// === Nút chọn nhanh số tiền (chip) ===
class QuickAmountButton extends StatelessWidget {
  final int amount;
  final ValueChanged<int> onTap;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool dense;

  const QuickAmountButton({
    super.key,
    required this.amount,
    required this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    this.borderRadius = 10,
    this.dense = true,
  });

  static String _fmt(int v) {
    final s = v.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
    );
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(borderRadius),
      onTap: () => onTap(amount),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: Colors.white24, width: 1),
          color: const Color(0x10FFFFFF),
        ),
        child: Text(
          _fmt(amount),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: dense ? 14 : 16,
          ),
        ),
      ),
    );
  }
}
