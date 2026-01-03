import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:street/core/constants.dart';

class Player extends SpriteAnimationComponent with HasGameRef, CollisionCallbacks {
  Player({required Vector2 position}) : super(position: position, size: Vector2(50, 80));

  @override
  Future<void> onLoad() async {
    animation = await gameRef.loadSpriteAnimation(
      AppConstants.playerSprite,
      SpriteAnimationData.sequenced(amount: 4, stepTime: 0.1, textureSize: Vector2(50, 80)),
    );
    add(RectangleHitbox());
  }

  void attack() {
    animationTicker?.reset();
    // TODO: Implement attack logic
  }
}