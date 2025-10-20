import 'package:flutter/material.dart';

/// Khung input
/// Dùng để bọc `TextField`, `TextFormField`,...
class InputFieldBox extends StatelessWidget {
  final Widget child;
  final double height;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final BorderRadiusGeometry borderRadius;
  final Color borderColor;

  const InputFieldBox({
    super.key,
    required this.child,
    this.height = 52,
    this.padding = const EdgeInsets.symmetric(horizontal: 14),
    this.backgroundColor = const Color(0x22000000),
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.borderColor = const Color(0x40FFFFFF),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Center(child: child),
    );
  }
}
