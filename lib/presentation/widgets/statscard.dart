import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color valueColor;

  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8.0), // Smaller padding
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[700] ?? Colors.grey, width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 20), // Slightly smaller icon
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: valueColor, fontSize: 16, fontWeight: FontWeight.bold)), // Colored value
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)), // Smaller label
          ],
        ),
      ),
    );
  }
}