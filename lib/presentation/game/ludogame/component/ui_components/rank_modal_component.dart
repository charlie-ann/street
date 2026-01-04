import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../state/player.dart';

class RankModalComponent extends PositionComponent with TapCallbacks {
  final List<Player> players;
  final BuildContext context;
  final String roomId;
  final String gameName;
  late PositionComponent _rematchButton;
  late PositionComponent _leaveButton;

  RankModalComponent({
    required this.players,
    required this.context,
    required this.roomId,
    required this.gameName,
    super.position,
    super.size,
  }) : super();

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Add the background rectangle
    add(
      RectangleComponent(
        size: size,
        paint: Paint()..color = const Color(0xff002fa7), // Background color
        position: Vector2.zero(),
      ),
    );

    // Center the text content
    _createPlayerList();

    // Add confetti animation for winner
    _addConfetti();

    // Add buttons at the bottom
    _addButtons();
  }

  void _createPlayerList() {
    // Group players by actual player (Player 1: BP/RP, Player 2: GP/YP)
    final Map<String, List<Player>> playerGroups = {};
    for (var player in players) {
      String actualPlayer = _getPlayerName(player.playerId);
      playerGroups.putIfAbsent(actualPlayer, () => []).add(player);
    }
    
    // Sort groups by best rank in each group
    final sortedGroups = playerGroups.entries.toList()
      ..sort((a, b) {
        final aMinRank = a.value.map((p) => p.rank).reduce((a, b) => a < b ? a : b);
        final bMinRank = b.value.map((p) => p.rank).reduce((a, b) => a < b ? a : b);
        return aMinRank.compareTo(bMinRank);
      });
    
    double yOffset = 20.0;

    for (var entry in sortedGroups.asMap().entries) {
      final index = entry.key;
      final playerName = entry.value.key;
      final playerHouses = entry.value.value;
      final bestRank = playerHouses.map((p) => p.rank).reduce((a, b) => a < b ? a : b);

      final rectangleWidth = size.x * 0.8;
      const rectangleHeight = 60.0;

      final backgroundColor = index == 0 ? const Color(0xff08C2FF) : const Color(0xff006BFF);

      var playerRectangle = RectangleComponent(
        size: Vector2(rectangleWidth, rectangleHeight),
        paint: Paint()..color = backgroundColor,
        position: Vector2((size.x - rectangleWidth) / 2, yOffset),
      );

      // Single avatar per actual player
      final avatarSize = 40.0;
      final avatarCircle = CircleComponent(
        radius: avatarSize / 2,
        paint: Paint()..color = _getPlayerAvatarColor(playerName),
        position: Vector2(10, (rectangleHeight - avatarSize) / 2),
      );
      
      final rankText = TextComponent(
        text: '$bestRank',
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      final suffixText = TextComponent(
        text: getOrdinalSuffix(bestRank),
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      rankText.position = Vector2(
        avatarSize + 20,
        (rectangleHeight - rankText.height) / 2 - 10,
      );

      suffixText.position = Vector2(
        rankText.position.x + rankText.width,
        (rectangleHeight - suffixText.height) / 2 - 10,
      );

      final playerNameText = TextComponent(
        text: playerName,
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      playerNameText.position = Vector2(
        avatarSize + 20,
        (rectangleHeight - playerNameText.height) / 2 + 10,
      );

      final usernameText = TextComponent(
        text: playerName == 'Player 1' ? 'Username1' : 'Username2',
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.normal,
          ),
        ),
      );

      usernameText.position = Vector2(
        rectangleWidth - usernameText.width - 10,
        (rectangleHeight - usernameText.height) / 2,
      );

      playerRectangle.addAll([avatarCircle, rankText, suffixText, playerNameText, usernameText]);
      add(playerRectangle);

      yOffset += rectangleHeight + 10;
    }
  }
  
  Color _getPlayerAvatarColor(String playerName) {
    return playerName == 'Player 1' ? Colors.blue : Colors.green;
  }
  
  String _getPlayerName(String playerId) {
    // Determine which actual player this house belongs to
    if (playerId == 'BP' || playerId == 'RP') {
      return 'Player 1';
    } else if (playerId == 'GP' || playerId == 'YP') {
      return 'Player 2';
    }
    return playerId;
  }

  void _addConfetti() {
    final random = Random();
    final colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.orange, Colors.purple];
    
    for (int i = 0; i < 30; i++) {
      final confetti = RectangleComponent(
        size: Vector2(6, 6),
        paint: Paint()..color = colors[random.nextInt(colors.length)],
        position: Vector2(
          random.nextDouble() * size.x,
          -10,
        ),
      );
      
      confetti.add(
        MoveByEffect(
          Vector2(random.nextDouble() * 100 - 50, size.y + 50),
          EffectController(
            duration: 2.0 + random.nextDouble() * 2.0,
            curve: Curves.easeOut,
          ),
        ),
      );
      
      confetti.add(
        RotateEffect.by(
          random.nextDouble() * 4 * pi,
          EffectController(
            duration: 2.0 + random.nextDouble() * 2.0,
          ),
        ),
      );
      
      add(confetti);
    }
  }

  String getOrdinalSuffix(int number) {
    if (number == 1) {
      return 'st';
    } else if (number == 2) {
      return 'nd';
    } else if (number == 3) {
      return 'rd';
    } else {
      return 'th';
    }
  }

  void _addButtons() {
    // Calculate button size and position
    final buttonWidth = size.x * 0.4;
    const buttonHeight = 50.0;
    final buttonY = size.y - buttonHeight - 20;
    
    // Rematch button
    _rematchButton = PositionComponent(
      size: Vector2(buttonWidth, buttonHeight),
      position: Vector2(size.x * 0.05, buttonY),
    );

    _rematchButton.add(
      RectangleComponent(
        size: Vector2(buttonWidth, buttonHeight),
        paint: Paint()..color = Colors.green,
      ),
    );

    final rematchText = TextComponent(
      text: 'Rematch',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 18,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    rematchText.position = Vector2(
      buttonWidth / 2 - rematchText.width / 2,
      buttonHeight / 2 - rematchText.height / 2,
    );

    _rematchButton.add(rematchText);
    add(_rematchButton);
    
    // Leave room button
    _leaveButton = PositionComponent(
      size: Vector2(buttonWidth, buttonHeight),
      position: Vector2(size.x * 0.55, buttonY),
    );

    _leaveButton.add(
      RectangleComponent(
        size: Vector2(buttonWidth, buttonHeight),
        paint: Paint()..color = Colors.red,
      ),
    );

    final leaveText = TextComponent(
      text: 'Leave Room',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 18,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    leaveText.position = Vector2(
      buttonWidth / 2 - leaveText.width / 2,
      buttonHeight / 2 - leaveText.height / 2,
    );

    _leaveButton.add(leaveText);
    add(_leaveButton);
  }

  @override
  void onTapDown(TapDownEvent event) {
    Offset tapPosition = Offset(event.localPosition.x, event.localPosition.y);

    // Check if the tap is within the rematch button's bounds
    if (_rematchButton.toRect().contains(tapPosition)) {
      context.go('/matchmaking', extra: {
        'roomId': roomId,
        'gameName': gameName,
        'isPrivate': false,
        'rematch': true,
      });
    }
    // Check if the tap is within the leave button's bounds
    else if (_leaveButton.toRect().contains(tapPosition)) {
      context.go('/lobby/${gameName.toLowerCase()}');
    }
  }

  void closeModal() {
    removeFromParent();
  }
}