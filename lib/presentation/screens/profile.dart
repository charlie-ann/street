import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:street/presentation/providers/auth_provider.dart';
import 'package:street/presentation/providers/game_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedIndex = 2; // Profile is the third tab (index 2)

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Container(
           decoration:const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomRight ,
            end: Alignment.topLeft,
            colors: [Color.fromARGB(255, 1, 48, 72), Color.fromARGB(255, 0, 0, 0)], // Dark to deep purple
          ),
        ),
          child: Column(
            children: [
              // Profile header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Avatar
                    GestureDetector(
                      onTap: () => context.go('/avatar-settings'),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[800],
                        backgroundImage: NetworkImage(
                          Provider.of<AuthProvider>(context).avatar ?? 
                          'https://api.dicebear.com/7.x/avataaars/png?seed=${Provider.of<AuthProvider>(context).userId}&size=150'
                        ),
                        onBackgroundImageError: (_, __) {},
                        child: null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Username
                    Text(
                      Provider.of<AuthProvider>(context).username ?? 'Player',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Stats row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard('1,247', 'Games Played', Icons.videogame_asset, Colors.blue),
                     const SizedBox(width: 16),
                    _buildStatCard('78%', 'Win Rate', Icons.emoji_events, Colors.green),
                     const SizedBox(width: 16),
                    _buildStatCard('2.4M', 'Chips Earned', Icons.monetization_on, Colors.orange),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Action cards
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Edit Profile Card
                      _buildActionCard(
                        icon: Icons.edit,
                        color: Colors.blue,
                        title: 'Edit Profile',
                        subtitle: 'Update your info',
                        onTap: () => _onActionTap(context, 'Edit Profile'),
                      ),
                      const SizedBox(height: 12),
                      // Settings Card
                      _buildActionCard(
                        icon: Icons.settings,
                        color: Colors.green,
                        title: 'Settings',
                        subtitle: 'Manage your settings',
                        onTap: () => _onActionTap(context, 'Settings'),
                      ),
                      const SizedBox(height: 12),
                      // Match History Card
                      _buildActionCard(
                        icon: Icons.history,
                        color: Colors.purple,
                        title: 'Match History',
                        subtitle: 'View past games',
                        onTap: () => _onActionTap(context, 'Match History'),
                      ),
                      const SizedBox(height: 12),
                      // Logout Card
                      _buildActionCard(
                        icon: Icons.logout,
                        color: Colors.red,
                        title: 'Logout',
                        subtitle: 'Sign out of your account',
                        onTap: () => _logout(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/wallet');
              break;
            case 2:
              // Already on profile
              break;
          }
        },
        backgroundColor: const Color(0xFF16213E),
        selectedItemColor: Colors.purple,
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

  Widget _buildStatCard(String value, String label, IconData icon, Color valueColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[700] ?? Colors.grey, width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: valueColor, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[700] ?? Colors.grey, width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2, blue: 0.2, red: 0.2, green: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onActionTap(BuildContext context, String action) {
    // TODO: Handle action taps (e.g., navigate to respective screens)
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$action tapped')));
  }

  void _logout(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.logout();
    context.go('/auth');
  }
}