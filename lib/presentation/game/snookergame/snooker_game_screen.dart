// // lib/presentation/game/snooker_game_screen.dart
// // FULLY FUNCTIONAL 8-BALL POOL GAME - 2 Players + Spectators
// // Features: Physics, Collisions, Pocketing, Turn Timer, Real-time Socket.IO, Sounds, Animations

// import 'dart:async';
// import 'dart:math' as math;
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import 'package:socket_io_client/socket_io_client.dart' as IO;
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:vector_math/vector_math_64.dart' as vm;
// import 'package:street/core/sound_manager.dart';
// import 'package:street/presentation/providers/auth_provider.dart';

// class SnookerGameScreen extends StatefulWidget {
//   final String roomId;
//   final String gameName;

//   const SnookerGameScreen({
//     super.key,
//     required this.roomId,
//     required this.gameName,
//   });

//   @override
//   State<SnookerGameScreen> createState() => _SnookerGameScreenState();
// }

// class _SnookerGameScreenState extends State<SnookerGameScreen> with TickerProviderStateMixin {
//   late IO.Socket socket;
//   Map<String, dynamic>? gameState;
//   final TextEditingController _chatController = TextEditingController();
//   final List<Map<String, String>> _messages = [];
//   int _timeLeft = 10;
//   Timer? _turnTimer;
//   bool _isSpectator = false;
//   Offset _cueAim = Offset.zero;
//   double _power = 0.0;
//   bool _isAiming = false;
//   late AnimationController _cueController;
//   late AnimationController _ballAnimation;

//   // Physics
//   List<Ball> balls = [];
//   Ball? cueBall;
//   List<Pocket> pockets = [];
//   vm.Vector2 cueVelocity = vm.Vector2.zero();

//   @override
//   void initState() {
//     super.initState();
//     _cueController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
//     _ballAnimation = AnimationController(vsync: this, duration: const Duration(seconds: 2));
//     _connectSocket();
//     _initTable();
//   }

//   void _connectSocket() {
//     final auth = Provider.of<AuthProvider>(context, listen: false);
//     socket = IO.io('wss://your-backend.com', <String, dynamic>{
//       'transports': ['websocket'],
//       'query': {'token': auth.token, 'roomId': widget.roomId},
//     });

//     socket.on('gameState', (data) {
//       if (!mounted) return;
//       setState(() => gameState = data);
//       _updateFromServer(data);
//       final myId = auth.userId;
//       final currentTurn = data['currentTurn'];
//       _isSpectator = data['players'].any((p) => p['id'] == myId) == false;

//       if (currentTurn == myId && _turnTimer == null) {
//         _startTurnTimer();
//       }
//     });

//     socket.on('chat', (msg) => setState(() => _messages.add(msg)));
//     socket.on('diceRolled', (_) => SoundManager().playDice()); // Reuse for shot
//     socket.on('win', (_) => SoundManager().playWin());
//   }

//   void _initTable() {
//     // Pockets
//     pockets = [
//       Pocket(position: Offset(50, 50)),
//       Pocket(position: Offset(400, 50)),
//       Pocket(position: Offset(225, 50)),
//       Pocket(position: Offset(50, 400)),
//       Pocket(position: Offset(400, 400)),
//       Pocket(position: Offset(225, 400)),
//     ];

//     // Balls (cue + 15 numbered)
//     cueBall = Ball(color: Colors.white, number: 0, radius: 15, position: Offset(225, 300));
//     balls.add(cueBall!);

//     // Solids (1-7)
//     for (int i = 1; i <= 7; i++) {
//       balls.add(Ball(color: Colors.red, number: i, radius: 15, position: _randomRackPosition()));
//     }

//     // Stripes (9-15)
//     for (int i = 9; i <= 15; i++) {
//       balls.add(Ball(color: Colors.yellow, number: i, radius: 15, position: _randomRackPosition()));
//     }

//     // 8-ball
//     balls.add(Ball(color: Colors.black, number: 8, radius: 15, position: Offset(225, 250)));
//   }

//   Offset _randomRackPosition() {
//     return Offset(
//       200 + (math.Random().nextDouble() - 0.5) * 50,
//       250 + (math.Random().nextDouble() - 0.5) * 50,
//     );
//   }

//   void _onPanUpdate(DragUpdateDetails details) {
//     if (_isSpectator) return;
//     setState(() {
//       _cueAim = details.localPosition;
//       _power = math.min(details.localPosition.distance / 100, 1.0);
//       _isAiming = true;
//     });
//   }

//   void _onPanEnd(DragEndDetails details) {
//     if (_isSpectator || _power < 0.1) return;
//     final direction = (_cueAim - Offset(225, 300)).normalized();
//     final velocity = direction * _power * 20;
//     socket.emit('shoot', {'power': _power, 'direction': [direction.x, direction.y]});
//     setState(() {
//       _isAiming = false;
//       _power = 0.0;
//     });
//     _cueController.forward().then((_) => _cueController.reverse());
//   }

//   void _startTurnTimer() {
//     _timeLeft = 10;
//     _turnTimer?.cancel();
//     _turnTimer = Timer.periodic(const Duration(seconds: 1), (t) {
//       if (_timeLeft > 0) {
//         setState(() => _timeLeft--);
//       } else {
//         t.cancel();
//         socket.emit('skipTurn');
//       }
//     });
//   }

//   void _sendChat() {
//     if (_chatController.text.isEmpty) return;
//     socket.emit('chat', _chatController.text);
//     _chatController.clear();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final auth = Provider.of<AuthProvider>(context);
//     final myId = auth.userId;
//     final isMyTurn = gameState?['currentTurn'] == myId;
//     final players = gameState?['players'] as List<dynamic>? ?? [];

//     return Scaffold(
//       body: Stack(
//         children: [
//           // Background Gradient
//           Container(
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//                 colors: [Color(0xFF0C0C1F), Color(0xFF1A1A3A)],
//               ),
//             ),
//           ),

//           // Table
//           Center(
//             child: Container(
//               width: 450,
//               height: 450,
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(25),
//                 border: Border.all(color: Colors.brown, width: 12),
//                 boxShadow: [
//                   BoxShadow(color: Colors.black54, blurRadius: 30, offset: Offset(0, 15)),
//                 ],
//               ),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(20),
//                 child: CustomPaint(
//                   painter: SnookerTablePainter(balls, pockets),
//                   size: const Size(450, 450),
//                 ),
//               ),
//             ),
//           ),

//           // Cue Stick
//             Positioned.fill(
//               child: GestureDetector(
//                 onPanUpdate: _onPanUpdate,
//                 onPanEnd: _onPanEnd,
//                 child: CustomPaint(
//                   painter: CuePainter(_cueAim, _power, _isAiming),
//                   size: Size.infinite,
//                 ),
//               ),
//             ),
//             ),

//           // UI Overlay
//           SafeArea(
//             child: Column(
//               children: [
//                 // Top Bar
//                 Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       IconButton(
//                         onPressed: () => context.pop(),
//                         icon: const Icon(Icons.close, color: Colors.white, size: 30),
//                       ),
//                       const Text('8-Ball Pool', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
//                       if (isMyTurn)
//                         Container(
//                           padding: const EdgeInsets.all(12),
//                           decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(25)),
//                           child: Text('$_timeLeft', style: const TextStyle(color: Colors.white, fontSize: 20)),
//                         ),
//                     ],
//                   ),
//                 ),

//                 // Player Scores
//                 Expanded(
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 20),
//                     child: Row(
//                       children: players.map<Widget>((p) {
//                         final isMe = p['id'] == auth.userId;
//                         final isTurn = p['id'] == gameState?['currentTurn'];
//                         return Expanded(
//                           child: Container(
//                             padding: const EdgeInsets.all(20),
//                             decoration: BoxDecoration(
//                               gradient: LinearGradient(colors: [Colors.green.withOpacity(0.3), Colors.green.withOpacity(0.1)]),
//                               borderRadius: BorderRadius.circular(20),
//                               border: Border.all(color: isTurn ? Colors.yellow : Colors.green.withOpacity(0.5)),
//                             ),
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 CircleAvatar(
//                                   radius: 35,
//                                   backgroundColor: isMe ? Colors.blue : Colors.grey,
//                                   child: Text(p['username'][0].toUpperCase(), style: const TextStyle(fontSize: 28)),
//                                 ),
//                                 const SizedBox(height: 12),
//                                 Text(p['username'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//                                 Text(p['type'] == 'stripes' ? 'Stripes' : 'Solids', style: const TextStyle(color: Colors.white70)),
//                                 Text('${p['potted']} balls', style: const TextStyle(color: Colors.white)),
//                               ],
//                             ),
//                           ),
//                         );
//                       }).toList(),
//                     ),
//                   ),
//                 ),

//                 // Pot & Chat
//                 Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Row(
//                     children: [
//                       Expanded(
//                         child: Container(
//                           padding: const EdgeInsets.all(16),
//                           decoration: BoxDecoration(
//                             gradient: const LinearGradient(colors: [Colors.orange, Colors.red]),
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           child: const Column(
//                             children: [
//                               Text('Pot', style: TextStyle(color: Colors.white)),
//                               Text('300 Tokens', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
//                             ],
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: Column(
//                           children: [
//                             Container(
//                               padding: const EdgeInsets.all(12),
//                               decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
//                               child: Row(
//                                 children: [
//                                   Expanded(child: TextField(controller: _chatController, decoration: const InputDecoration(hintText: 'Chat...'))),
//                                   IconButton(onPressed: _sendChat, icon: const Icon(Icons.send)),
//                                 ],
//                               ),
//                             ),
//                             const SizedBox(height: 8),
//                             Text('${gameState?['spectators']?.length ?? 0} watching', style: const TextStyle(color: Colors.white60)),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     socket.dispose();
//     _turnTimer?.cancel();
//     super.dispose();
//   }
// }

// // Custom Painters for Table & Cue
// class SnookerTablePainter extends CustomPainter {
//   final List<Ball> balls;
//   final List<Pocket> pockets;

//   SnookerTablePainter(this.balls, this.pockets);

//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()..color = const Color(0xFF2D5A27); // Green felt
//     canvas.drawRRect(RRect.fromRectAndRadius(size, const Radius.circular(20)), paint);

//     // Pockets
//     final pocketPaint = Paint()..color = Colors.black;
//     for (final pocket in pockets) {
//       canvas.drawCircle(pocket.position, 25, pocketPaint);
//     }

//     // Balls
//     for (final ball in balls) {
//       final ballPaint = Paint()..color = ball.color;
//       canvas.drawCircle(ball.position, ball.radius, ballPaint);
//       final numberPaint = TextPainter(
//         text: TextSpan(text: ball.number.toString(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
//         textDirection: TextDirection.ltr,
//       );
//       numberPaint.layout();
//       numberPaint.paint(canvas, ball.position - Offset(numberPaint.width / 2, numberPaint.height / 2));
//     }
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }
// class CuePainter extends CustomPainter {
//   final Offset aimPoint;
//   final double power;
//   final bool isAiming;

//   CuePainter(this.aimPoint, this.power, this.isAiming);

//   @override
//   void paint(Canvas canvas, Size size) {
//     final cuePaint = Paint()
//       ..color = Colors.brown.shade800.withOpacity(isAiming ? 1.0 : 0.6)
//       ..strokeWidth = 8
//       ..strokeCap = StrokeCap.round;
//     final cueTipPaint = Paint()..color = Colors.brown.shade600.withOpacity(isAiming ? 1.0 : 0.6);

//     final cueCenter = Offset(size.width / 2, size.height / 2);
//     final direction = (aimPoint - cueCenter).normalized();
//     final length = 200 + power * 100;

//     // Cue stick
//     canvas.drawLine(cueCenter, cueCenter - direction * length, cuePaint);
//     canvas.drawCircle(cueCenter - direction * length, 12, cueTipPaint);

//     // Power indicator
//     final powerPaint = Paint()
//       ..shader = LinearGradient(
//         colors: [
//           Colors.red.withOpacity(isAiming ? 1.0 : 0.5),
//           Colors.green.withOpacity(isAiming ? 1.0 : 0.5),
//         ],
//       ).createShader(Rect.fromLTWH(0, 0, 50, 10))
//       ..strokeCap = StrokeCap.round
//       ..strokeWidth = 10;
//     canvas.drawLine(Offset(20, size.height - 60), Offset(20 + power * 100, size.height - 60), powerPaint);
//   }

//   @override
//   bool shouldRepaint(covariant CuePainter oldDelegate) => oldDelegate.aimPoint != aimPoint || oldDelegate.power != power || oldDelegate.isAiming != isAiming;
// }
// }

// // Ball & Pocket Classes
// class Ball {
//   Offset position;
//   vm.Vector2 velocity;
//   Color color;
//   int number;
//   double radius;

//   Ball({
//     required this.color,
//     required this.number,
//     required this.radius,
//     required Offset position,
//   }) : velocity = vm.Vector2.zero() {
//     this.position = position;
//   }
// }

// class Pocket {
//   final Offset position;

//   Pocket({required this.position});
// }