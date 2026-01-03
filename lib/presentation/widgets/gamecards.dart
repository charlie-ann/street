import 'package:flutter/material.dart';

class GameCard extends StatelessWidget {
  final String image;
  final String title;
  final String subtitle;
  final Color buttonColor;
  final List<Map<String, dynamic>> buttons;
  final bool live;
  final VoidCallback? onSettingsTap; // Optional callback for settings icon

  const GameCard({
    super.key,
    required this.image,
    required this.title,
    required this.subtitle,
    required this.buttonColor,
    required this.buttons,
    required this.live,
    this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[700] ?? Colors.grey, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Game Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.asset(
              image,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 150,
                color: Colors.grey[800],
                child: const Icon(Icons.image_not_supported, size: 50, color: Colors.white),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    if (live) Row(
                      children: [
                        Icon(Icons.circle, color: buttonColor, size: 8),
                        const SizedBox(width: 4),
                        Text('LIVE', style: TextStyle(color: buttonColor, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: buttons.first['onPressed'] != null
                          ? Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [buttonColor, buttonColor.withValues(alpha: 0.7,blue: 0.5, red: 0.2, green: 0.5)],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: buttons.first['onPressed'],
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                                    child: Center(
                                      child: Text(
                                        buttons.first['text'],
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox(),
                    ),
                    IconButton(
                      onPressed: onSettingsTap ?? () {
                        // Default handling if no callback provided
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Game settings opened')));
                      },
                      icon: const Icon(Icons.settings_outlined, color: Colors.white70, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}