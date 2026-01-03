import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:street/presentation/providers/auth_provider.dart';
import 'package:street/presentation/providers/otp_provider.dart';
import 'package:street/presentation/providers/rooms_provider.dart';
import 'package:street/presentation/game/ludogame/ludo.dart';
import 'package:street/presentation/screens/matchmaking_screen.dart';
import 'core/themes.dart';
import 'routes/app_router.dart';
import 'presentation/providers/game_provider.dart';
import 'package:street/core/sound_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SoundManager().init();
  final authProvider = AuthProvider();
  await authProvider.loadUserData();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => OtpProvider()),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => RoomsProvider()),
        Provider(create: (_) => SoundManager()),
      ],
      child: const StreetGameApp(),
    ),
  );
}

class StreetGameApp extends StatelessWidget {
  const StreetGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Street Game',
      theme: streetTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}

class GameApp extends StatefulWidget {
  final List<String> selectedTeams;

  const GameApp({super.key, required this.selectedTeams});

  @override
  State<GameApp> createState() => _GameAppState();
}

class _GameAppState extends State<GameApp> {
  Ludo? game;

  @override
  void initState() {
    super.initState();
    game = Ludo(widget.selectedTeams, context, roomId: 'local');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, dynamic) {
        _showExitConfirmationDialog();
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xff1E3E62), Color(0xff1E3E62)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: FittedBox(
                    child: SizedBox(
                        width: screenWidth,
                        height: screenWidth + screenWidth * 0.70,
                        child: GameWidget(game: game!)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showExitConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Exit Game'),
          content: const Text('Do you really want to exit the game?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MatchmakingScreen(
                      roomId: '',
                      gameName: 'Ludo',
                      isPrivate: false,
                    ),
                  ),
                );
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }
}

class TokenDisplay extends StatelessWidget {
  final Color color;

  const TokenDisplay({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(30, 30),
      painter: TokenPainter(
        fillPaint: Paint()..color = color,
        borderPaint: Paint()
          ..color = Colors.black
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke,
      ),
    );
  }
}

class TokenPainter extends CustomPainter {
  final Paint fillPaint;
  final Paint borderPaint;

  TokenPainter({
    required this.fillPaint,
    required this.borderPaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final outerRadius = size.width / 2;
    final smallerCircleRadius = outerRadius / 1.7;
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(center, outerRadius, Paint()..color = Colors.white);
    canvas.drawCircle(center, outerRadius, borderPaint);
    canvas.drawCircle(center, smallerCircleRadius, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PlayArea extends RectangleComponent with HasGameReference<Ludo> {
  PlayArea() : super(children: [RectangleHitbox()]);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    size = Vector2(game.width, game.height);
  }
}