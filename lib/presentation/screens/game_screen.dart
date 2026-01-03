import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:street/core/constants.dart';
import 'package:street/game/street_game.dart';


class GameScreen extends StatelessWidget {
  const GameScreen({super.key, required String roomId, required gameName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppConstants.backgroundImage),
            fit: BoxFit.cover,
            opacity: 0.5,
          ),
        ),
        child: Stack(
          children: [
            GameWidget(game: Street()),
            Positioned(
              top: 40,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Health: 100', style: Theme.of(context).textTheme.bodyLarge),
                  Text('Score: 0', style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(onPressed: () {}, child: const Text('Left')),
                  ElevatedButton(onPressed: () {}, child: const Text('Attack')),
                  ElevatedButton(onPressed: () {}, child: const Text('Right')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}