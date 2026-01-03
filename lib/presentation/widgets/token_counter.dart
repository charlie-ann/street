import 'package:flutter/material.dart';
import 'package:street/presentation/game/ludogame/state/token_manager.dart';
import 'package:street/presentation/game/ludogame/component/ui_components/token.dart';

class TokenCounter extends StatefulWidget {
  final String playerId;
  final Color color;
  final String label;

  const TokenCounter({
    super.key,
    required this.playerId,
    required this.color,
    required this.label,
  });

  @override
  State<TokenCounter> createState() => _TokenCounterState();
}

class _TokenCounterState extends State<TokenCounter> {
  int _tokensInBase = 4;
  int _tokensOnBoard = 0;
  int _tokensInHome = 0;

  @override
  void initState() {
    super.initState();
    _updateTokenCounts();
  }

  void _updateTokenCounts() {
    List<Token> tokens = [];
    switch (widget.playerId) {
      case 'BP':
        tokens = TokenManager().getBlueTokens();
        break;
      case 'RP':
        tokens = TokenManager().getRedTokens();
        break;
      case 'GP':
        tokens = TokenManager().getGreenTokens();
        break;
      case 'YP':
        tokens = TokenManager().getYellowTokens();
        break;
    }

    setState(() {
      _tokensInBase = tokens.where((t) => t.state == TokenState.inBase).length;
      _tokensOnBoard = tokens.where((t) => t.state == TokenState.onBoard).length;
      _tokensInHome = tokens.where((t) => t.state == TokenState.inHome).length;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Update counts when widget rebuilds
    _updateTokenCounts();
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: widget.color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: widget.color, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.label,
            style: TextStyle(
              color: widget.color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTokenCount('Base', _tokensInBase, Colors.grey),
              const SizedBox(width: 8),
              _buildTokenCount('Board', _tokensOnBoard, Colors.orange),
              const SizedBox(width: 8),
              _buildTokenCount('Home', _tokensInHome, Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTokenCount(String label, int count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(color: color, fontSize: 10),
        ),
        Text(
          count.toString(),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}