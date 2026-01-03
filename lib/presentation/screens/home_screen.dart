// lib/presentation/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:street/presentation/providers/auth_provider.dart';
import 'package:street/presentation/widgets/authenticated_screen.dart';
import 'package:street/presentation/widgets/gamecards.dart';
import 'package:street/presentation/widgets/statscard.dart';

class HomeScreen extends AuthenticatedScreen {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends AuthenticatedScreenState<HomeScreen> {
  int _selectedIndex = 0; // bottom navigation index

  // -----------------------------------------------------------------------
  // Re-usable card builder – avoids copy-paste and guarantees correct args
  // -----------------------------------------------------------------------
  Widget _gameCard({
    required String image,
    required String title,
    required String subtitle,
    required Color buttonColor,
    required String gameRoute, // e.g. "Ludo" or "Snooker"
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GameCard(
        image: image,
        title: title,
        subtitle: subtitle,
        buttonColor: buttonColor,
        live: true,
        buttons: [
          {
            'text': 'Quick Match',
            // ← pass context + game name
            'onPressed': () => _onGameTap(context, gameRoute),
          },
        ],
        onSettingsTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title settings opened')),
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Navigation + balance check
  // -----------------------------------------------------------------------
  void _onGameTap(BuildContext ctx, String game) {
    final auth = Provider.of<AuthProvider>(ctx, listen: false);
    final balance = auth.walletBalance;

   if (balance < 10) {
      // Minimum 10 tokens to play
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('You need at least 10 STR Tokens to play!'),
          backgroundColor: Colors.orange,
        ),
      );
      ctx.go('/wallet');
      return;
    }

    // → /lobby/Ludo  or  /lobby/Snooker
    ctx.go('/lobby/$game');
  }

  // -----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
   final balance = (auth.walletBalance).toStringAsFixed(0);

    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomRight,
              end: Alignment.topLeft,
              colors: [
                Color.fromARGB(255, 1, 48, 72),
                Color.fromARGB(255, 0, 0, 0),
              ],
            ),
          ),
          child: Column(
            children: [
              // ────── TOP BAR ──────
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo
                    Image.asset(
                      'assets/images/logo.png',
                      height: 24,
                      width: 80,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.error, color: Colors.white, size: 24),
                    ),
                    // Balance
                   GestureDetector(
                      onTap: () => context.go('/wallet'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        // decoration: BoxDecoration(
                        //   gradient: const LinearGradient(
                        //     colors: [Color(0xFF00D4AA), Color(0xFF00A38D)],
                        //   ),
                        //   borderRadius: BorderRadius.circular(10),
                        //   boxShadow: [
                        //     BoxShadow(
                        //       color: Colors.green.withOpacity(0.4),
                        //       blurRadius: 10,
                        //       offset: const Offset(0, 8),
                        //     ),
                        //   ],
                        // ),
                        child: Row(
                          children: [
                            const Icon(Icons.token, color: Colors.orangeAccent, size: 28),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // const Text(
                                //   'STR Tokens',
                                //   style: TextStyle(color: Colors.white70, fontSize: 12),
                                // ),
                                Text(
                                  balance,
                                  style: const TextStyle(
                                    color: Colors.orangeAccent,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ────── STATS ──────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    StatCard(
                        value: '1,247',
                        label: 'Players Online',
                        icon: Icons.people,
                        valueColor: Colors.white),
                    SizedBox(width: 16),
                    StatCard(
                        value: r'$50K',
                        label: 'Total Won',
                        icon: Icons.monetization_on,
                        valueColor: Colors.green),
                    SizedBox(width: 16),
                    StatCard(
                        value: '24',
                        label: 'Live Games',
                        icon: Icons.videogame_asset,
                        valueColor: Colors.cyan),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ────── GAMES LIST ──────
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Ludo
                      _gameCard(
                        image: 'assets/images/ludo.png',
                        title: 'Ludo',
                        subtitle: 'Classic Board Game',
                        buttonColor: Colors.green,
                        gameRoute: 'Ludo',
                      ),
                      const SizedBox(height: 20),

                      // Snooker (keep only one – remove duplicates)
                      _gameCard(
                        image: 'assets/images/snooker.png',
                        title: 'Snooker',
                        subtitle: 'Pool & Precision',
                        buttonColor: Colors.blue,
                        gameRoute: 'Snooker',
                      ),
                      // add more cards here if needed
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // ────── BOTTOM NAV ──────
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (i) {
          if (i == _selectedIndex) return;
          setState(() => _selectedIndex = i);
          switch (i) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/wallet');
              break;
            case 2:
              context.go('/profile');
              break;
          }
        },
        backgroundColor: const Color(0xFF16213E),
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: _selectedIndex == 0 ? Colors.orange : Colors.grey),
            label: 'Home'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wallet, color: _selectedIndex == 1 ? Colors.green : Colors.grey),
            label: 'Wallet'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, color: _selectedIndex == 2 ? Colors.purple : Colors.grey),
            label: 'Profile'
          ),
        ],
      ),
    );
  }
}