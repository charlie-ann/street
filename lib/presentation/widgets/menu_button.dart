import 'package:flutter/material.dart';

class MenuButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
   final IconData? suffixIcon;

  const MenuButton({super.key, required this.text, required this.onPressed, this.suffixIcon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Colors.lightBlueAccent, Colors.blueAccent], // Adjusted for visibility (you can tweak colors)
          ),
          borderRadius: BorderRadius.circular(14), // Rounded corners like in the design
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2,blue: 0.2, red: 0.2, green: 0.2),
                  blurRadius: 10,
                  
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent, // Make material transparent to show gradient
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(4), // Match radius for ripple effect
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      text,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.white, // Ensure text is visible on gradient
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (suffixIcon != null) ...[
                      const SizedBox(width: 8),
                      Icon(suffixIcon, color: Colors.white70),
                    ],
                  ],
                ),
              ),
             ),
          ),
        ),
      ),
    );
  }
}