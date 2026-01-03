import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:street/core/constants.dart';
import 'components/player.dart';
import 'package:provider/provider.dart';
import '../presentation/providers/game_provider.dart';

class Street extends FlameGame with TapDetector {
  late Player player;

  @override
  Future<void> onLoad() async {
    add(SpriteComponent(sprite: await loadSprite(AppConstants.backgroundImage), size: size));
    player = Player(position: Vector2(100, size.y - 200));
    add(player);
  }

  @override
  void onTapDown(TapDownInfo info) {
    player.attack();
    // Update score via Provider
    buildContext?.read<GameProvider>().updateScore((buildContext!.read<GameProvider>().score + 10));
  }
}