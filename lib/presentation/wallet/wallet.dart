import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:street/presentation/providers/auth_provider.dart';
import 'package:street/presentation/wallet/deposit_screen.dart';
import 'package:street/presentation/wallet/withdraw_screen.dart';
import 'package:street/presentation/wallet/buy_tokens_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final double strBalance = auth.walletBalance ;
    final double usdBalance = strBalance * 0.25; // $0.25 per STR

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D2B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Street Wallet',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Token & Fiat Balance Cards
            Row(
              children: [
                Expanded(
                  child: _BalanceCard(
                    title: 'Token Balance',
                    amount: strBalance.toStringAsFixed(0),
                    subtitle: 'STR Tokens',
                    color: Colors.green,
                    icon: Icons.token,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _BalanceCard(
                    title: 'Fiat Balance',
                    amount: '\$${usdBalance.toStringAsFixed(2)}',
                    subtitle: 'USD',
                    color: Colors.blue,
                    icon: Icons.account_balance_wallet,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.arrow_downward,
                    label: 'Deposit',
                    color: Colors.green,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DepositScreen())),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.arrow_upward,
                    label: 'Withdraw',
                    color: Colors.orange,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WithdrawScreen())),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.shopping_cart,
                    label: 'Buy Tokens',
                    color: Colors.purple,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BuyTokensScreen())),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Recent Transactions Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All', style: TextStyle(color: Colors.cyan)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Transactions List
            ..._buildTransactions(),
          ],
        ),
      ),

      // Bottom Navigation


      


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
        selectedItemColor: Colors.green,
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

  List<Widget> _buildTransactions() {
    final List<Map<String, dynamic>> transactions = [
      {
        'icon': Icons.arrow_downward,
        'title': 'Deposit from Bank',
        'amount': '+500 USDT',
        'color': Colors.green,
        'status': 'Completed',
        'time': '2 hours ago',
      },
      {
        'icon': Icons.shopping_cart,
        'title': 'Token Purchase',
        'amount': '+1,250 STR',
        'color': Colors.green,
        'status': 'Completed',
        'time': '5 hours ago',
      },
      {
        'icon': Icons.gamepad,
        'title': 'Transfer to Gaming',
        'amount': '-300 STR',
        'color': Colors.red,
        'status': 'Completed',
        'time': '1 day ago',
      },
      {
        'icon': Icons.arrow_upward,
        'title': 'Withdraw to Wallet',
        'amount': '-150 USDT',
        'color': Colors.orange,
        'status': 'Pending',
        'time': '2 days ago',
      },
      {
        'icon': Icons.shopping_cart,
        'title': 'Token Purchase',
        'amount': '+800 STR',
        'color': Colors.green,
        'status': 'Completed',
        'time': '3 days ago',
      },
    ];

    return transactions.map((tx) => _TransactionItem(
          icon: tx['icon'],
          title: tx['title'],
          amount: tx['amount'],
          color: tx['color'],
          status: tx['status'],
          time: tx['time'],
        )).toList();
  }
}

// Reusable Balance Card
class _BalanceCard extends StatelessWidget {
  final String title;
  final String amount;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _BalanceCard({
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.3), color.withOpacity(0.1)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const Spacer(),
              Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            amount,
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          Text(subtitle, style: const TextStyle(color: Colors.white60)),
        ],
      ),
    );
  }
}

// Reusable Action Button
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    this.label = '',
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label!, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// Transaction Item
class _TransactionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String amount;
  final Color color;
  final String status;
  final String time;

  const _TransactionItem({
    required this.icon,
    required this.title,
    required this.amount,
    required this.color,
    required this.status,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(time, style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
              Row(
                children: [
                  Icon(Icons.circle, size: 10, color: status == 'Completed' ? Colors.green : Colors.orange),
                  const SizedBox(width: 4),
                  Text(status, style: TextStyle(color: status == 'Completed' ? Colors.green : Colors.orange, fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}