import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:street/presentation/game/ludogame/component/ui_components/token.dart';
import 'package:street/presentation/game/ludogame/state/game_state.dart';

class TurnTimer extends TextComponent {
  Timer? _timer;
  int _timeLeft = 10;
  final String playerId;
  
  TurnTimer({required this.playerId, required Vector2 position}) : super(
    text: '10',
    position: position,
    textRenderer: TextPaint(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  void startTimer() {
    _timeLeft = 10;
    text = _timeLeft.toString();
    
    _timer?.stop();
    _timer = Timer(
      1.0,
      onTick: () {
        _timeLeft--;
        text = _timeLeft.toString();
        
        if (_timeLeft <= 0) {
          _timer?.stop();
          // Check if player has movable tokens
          final currentPlayer = GameState().currentPlayer;
          bool hasMovableTokens = false;
          
          // Check if any tokens can move
          for (var token in currentPlayer.tokens) {
            if (token.state == TokenState.inBase && GameState().diceNumber == 6) {
              hasMovableTokens = true;
              break;
            } else if (token.state == TokenState.onBoard && token.spaceToMove()) {
              hasMovableTokens = true;
              break;
            }
          }
          
          // If player has movable tokens, switch to next player
          // If no movable tokens, reset and allow dice roll
          if (hasMovableTokens) {
            Future.delayed(const Duration(milliseconds: 1500), () {
              GameState().switchToNextPlayer();
            });
          } else {
            // Reset timer and enable dice for same player
            currentPlayer.enableDice = true;
            startTimer();
          }
        }
      },
      repeat: true,
    );
    _timer?.start();
  }

  void stopTimer() {
    _timer?.stop();
    text = '';
    // Stop timer and automatically switch to next player after 1.5 seconds
    Future.delayed(const Duration(milliseconds: 1500), () {
      GameState().switchToNextPlayer();
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer?.update(dt);
  }

  @override
  void onRemove() {
    _timer?.stop();
    super.onRemove();
  }
}