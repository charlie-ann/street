import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../state/game_state.dart';

class ScoreDisplay extends TextComponent {
  final String playerId;
  
  ScoreDisplay({required this.playerId, required Vector2 position}) : super(
    text: '0',
    position: position,
    textRenderer: TextPaint(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  void updateScore() {
    if (playerId == 'BP') {
      // Player 1 score: BP + RP tokens
      int player1Score = GameState().getPlayerScore('BP') + GameState().getPlayerScore('RP');
      text = player1Score.toString();
    } else if (playerId == 'GP') {
      // Player 2 score: GP + YP tokens  
      int player2Score = GameState().getPlayerScore('GP') + GameState().getPlayerScore('YP');
      text = player2Score.toString();
    } else {
      text = GameState().getPlayerScore(playerId).toString();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    updateScore();
  }
}