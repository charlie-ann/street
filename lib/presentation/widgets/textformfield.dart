import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final bool obscureText;
  final VoidCallback? onToggleVisibility;
  final bool filled;
  final Color? fillColor;
  final InputBorder? border;
  final TextStyle? labelStyle;
  final TextStyle? textStyle;
  final IconData? prefixIcon; // New parameter for prefix icon (e.g., email)

  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.obscureText = false,
    this.onToggleVisibility,
    this.filled = true,
    this.fillColor = Colors.transparent, // Default to transparent
    this.border,
    this.labelStyle,
    this.textStyle = const TextStyle(color: Colors.white),
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    const defaultBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: Colors.white70, width: 0.5), // Added outlined border with width 1
    );

    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: labelText,
        filled: filled,
        fillColor: fillColor,
        border: border ?? defaultBorder,
        enabledBorder: border ?? defaultBorder, // Ensure consistent border when enabled
        focusedBorder: border ?? defaultBorder.copyWith(borderSide: const BorderSide(color: Colors.blue, width: 1.0)), // Optional: Change color on focus
        labelStyle: labelStyle ?? const TextStyle(color: Colors.white70, fontSize: 14), // Reduced fontSize for label
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.white70) : null,
        suffixIcon: onToggleVisibility != null
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white70,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
      ),
      style: textStyle,
    );
  }
}