import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flame/game.dart';
import 'package:street/auth.dart';
import 'package:street/presentation/game/ludogame/ludo.dart';

import 'package:street/presentation/providers/auth_provider.dart';
import 'package:street/presentation/screens/forgotpassword_screen.dart';
import 'package:street/presentation/screens/game_screen.dart';
import 'package:street/presentation/screens/home_screen.dart';
import 'package:street/presentation/screens/lobby_screen.dart';
import 'package:street/presentation/screens/matchmaking_screen.dart';
import 'package:street/presentation/screens/otp.dart';
import 'package:street/presentation/screens/profile.dart';
import 'package:street/presentation/screens/onboarding_screen.dart';
import 'package:street/presentation/screens/avatar_settings_screen.dart';
import 'package:street/presentation/wallet/wallet.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
    GoRoute(path: '/auth', builder: (context, state) => const AuthenticationScreen()),
    GoRoute(path: '/forgotpassword', builder: (context, state) => const ForgotPasswordScreen()),

    GoRoute(
      path: '/otp',
      builder: (context, state) {
        final phone = state.extra as String? ?? '';
        return OtpScreen(phoneNumber: phone);
      },
    ),

    GoRoute(
      path: '/ludo/:roomId/:hostId',
      name: 'ludo',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final roomId = state.pathParameters['roomId'] ?? '';
        final hostId = state.pathParameters['hostId'] ?? '';
        final players = List<Map<String, dynamic>>.from(extra?['players'] ?? []);
        final isHost = extra?['isHost'] ?? false;
        final gameName = extra?['gameName'] ?? 'Ludo';
        
        if (roomId.isEmpty || hostId.isEmpty) {
          return const Scaffold(
            body: Center(
              child: Text('Error: Missing room ID or host ID', 
                style: TextStyle(color: Colors.red, fontSize: 18)),
            ),
          );
        }
        
        return Scaffold(
          backgroundColor: const Color(0xFF1B5E20),
          body: SafeArea(
            child: Column(
              children: [
                // Player Info Header
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Player 1
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue, width: 2),
                          ),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.blue,
                                backgroundImage: players.isNotEmpty && players[0]['avatar'] != null 
                                    ? NetworkImage(players[0]['avatar']) 
                                    : null,
                                child: players.isEmpty || players[0]['avatar'] == null
                                    ? Text(
                                        players.isNotEmpty ? players[0]['username']?.toString().substring(0, 1).toUpperCase() ?? 'P1' : 'P1',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                players.isNotEmpty ? players[0]['username']?.toString() ?? 'Player 1' : 'Player 1',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // VS
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'VS',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Player 2
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green, width: 2),
                          ),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.green,
                                backgroundImage: players.length > 1 && players[1]['avatar'] != null 
                                    ? NetworkImage(players[1]['avatar']) 
                                    : null,
                                child: players.length <= 1 || players[1]['avatar'] == null
                                    ? Text(
                                        players.length > 1 ? players[1]['username']?.toString().substring(0, 1).toUpperCase() ?? 'P2' : 'P2',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                players.length > 1 ? players[1]['username']?.toString() ?? 'Player 2' : 'Player 2',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Game Widget
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    child: GameWidget(
                      game: Ludo(players.length == 2 ? ['BP', 'GP'] : ['BP', 'GP', 'RP', 'YP'], context, 
                          roomId: roomId, gameName: gameName, players: players, isHost: isHost),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),

    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),

    GoRoute(
      path: '/game',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final roomId = extra?['gameId']?.toString() ?? 'unknown';
        final gameName = extra?['gameName'] ?? 'Game';
        return GameScreen(roomId: roomId, gameName: gameName);
      },
    ),

    GoRoute(
      path: '/lobby/:game',
      builder: (context, state) {
        final game = state.pathParameters['game'] ?? 'Unknown';
        return LobbyScreen(gameName: game);
      },
    ),

    GoRoute(
  path: '/matchmaking',
  name: 'matchmaking',
  builder: (context, state) {
    final extra = state.extra;

    // Safety check: if no extra or wrong type
    if (extra == null || extra is! Map<String, dynamic>) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error, color: Colors.red, size: 60),
              SizedBox(height: 16),
              Text(
                'Error: Invalid room data',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    // Safe extraction with null-safety
    final String roomId = (extra['roomId']?.toString() ?? '').trim();
    final String gameName = (extra['gameName']?.toString() ?? 'Game').trim();
    final bool isPrivate = extra['isPrivate'] == true;
    final String? roomCodeValue = extra['roomCode']?.toString().trim();
    final String? roomCode = (roomCodeValue?.isNotEmpty == true) ? roomCodeValue : null;
    final int? entryFee = extra['entryFee'] as int?;
    
    debugPrint('=== APP ROUTER MATCHMAKING ===');
    debugPrint('Received extra: $extra');
    debugPrint('Extracted roomId: $roomId');
    debugPrint('Extracted roomCode: $roomCode');
    debugPrint('Extracted isPrivate: $isPrivate');
    debugPrint('Extracted entryFee: $entryFee');
    debugPrint('==============================');

    // Critical validation
    if (roomId.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 60),
              SizedBox(height: 16),
              Text(
                'Error: Missing room ID',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    return MatchmakingScreen(
      roomId: roomId,
      gameName: gameName,
      isPrivate: isPrivate,
      roomCode: roomCode,
      entryFee: entryFee,
      initialRoomData: extra['initialRoomData'] as Map<String, dynamic>?,
    );
  },
),

    GoRoute(
  path: '/wallet',
  builder: (context, state) => const WalletScreen(),
),

    GoRoute(
  path: '/avatar-settings',
  builder: (context, state) => const AvatarSettingsScreen(),
),
  ],

  redirect: (context, state) {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final token = authProvider.token;
  final isLoggedIn = token != null && token.isNotEmpty && token.length > 10; // Basic token validation

  final authRoutes = ['/onboarding', '/auth', '/forgotpassword', '/otp'];
  final isAuthRoute = authRoutes.contains(state.matchedLocation) || state.matchedLocation.startsWith('/otp');

  if (!isLoggedIn && !isAuthRoute) {
    return '/auth';
  }

  if (isLoggedIn && isAuthRoute) {
    return '/home';
  }

  return null;
},
  errorBuilder: (context, state) => Scaffold(
  body: Center(
    child: Text('Page not found: ${state.matchedLocation}'),
  ),
),
);