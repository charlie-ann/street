import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BackIconButton extends PositionComponent with TapCallbacks {
  final BuildContext context;
  
  BackIconButton({required this.context}) : super(
    size: Vector2(50, 50),
    position: Vector2(10, 10),
  );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Add background for visibility
    add(RectangleComponent(
      size: size,
      paint: Paint()..color = Colors.black.withOpacity(0.5),
    ));
    
    // iOS-style back arrow icon
    add(TextComponent(
      text: '<',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
      position: Vector2(18, 8),
    ));
  }

  @override
  void onTapDown(TapDownEvent event) {
    context.pop();
  }
}