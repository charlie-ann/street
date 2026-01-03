import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:street/presentation/providers/auth_provider.dart';
import 'package:street/core/endpoints.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GameRoomScreen extends StatelessWidget {
  /// When `room` is **null** → we are in *create* mode.
  final Room? room;
  final VoidCallback? onJoinPressed;

  const GameRoomScreen({super.key, this.room, this.onJoinPressed});

  bool get isCreateMode => room == null;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final balance = auth.walletBalance ?? 0.0;

    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isCreateMode ? 'Create Room' : 'Room #${room!.id}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Icon(Icons.circle, color: Colors.orange, size: 16),
                const SizedBox(width: 4),
                Text(
                  balance.toStringAsFixed(2),
                  style: const TextStyle(color: Colors.orange, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
      body: isCreateMode ? _buildCreateForm(context) : _buildRoomDetails(context),
    );
  }

  // ───────────────────── CREATE FORM ─────────────────────
  Widget _buildCreateForm(BuildContext context) {
    final entryCtrl = TextEditingController();
    final maxPlayersCtrl = TextEditingController(text: '2');

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Entry Fee', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          TextField(
            controller: entryCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[800],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Max Players', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          TextField(
            controller: maxPlayersCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[800],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () async {
              final entry = int.tryParse(entryCtrl.text) ?? 0;
              final max = int.tryParse(maxPlayersCtrl.text) ?? 2;
              if (entry <= 0 || max < 2) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid values')),
                );
                return;
              }

              final token = Provider.of<AuthProvider>(context, listen: false).token;
              final resp = await http.post(
                Uri.parse('${Endpoints.baseUrl}/api/rooms/create'),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
                body: json.encode({
                  'game': context.read<GoRouter>().routerDelegate.currentConfiguration.last.matchedLocation.split('/').last,
                  'entry': entry,
                  'maxPlayers': max,
                }),
              );

              if (resp.statusCode == 201) {
                final newRoom = Room.fromJson(json.decode(resp.body));
                context.go('/lobby/${newRoom.gameName}/room/${newRoom.id}');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(json.decode(resp.body)['message'] ?? 'Failed')),
                );
              }
            },
            child: const Text('Create Room', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  // ───────────────────── ROOM DETAILS ─────────────────────
  Widget _buildRoomDetails(BuildContext context) {
    final r = room!;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Table ${r.id}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text(r.difficulty, style: const TextStyle(color: Colors.cyan, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),

          // Stats chips
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _statChip('Entry', r.entry.toString(), Colors.green),
              _statChip('Players', '${r.currentPlayers}/${r.maxPlayers}', Colors.blue),
              _statChip('Pot', r.pot.toString(), Colors.orange),
            ],
          ),
          const SizedBox(height: 16),
          Text(r.status, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const Spacer(),

          // Join button
          ElevatedButton(
            onPressed: r.isFull ? null : onJoinPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: r.isFull ? Colors.grey : Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            ),
            child: Text(r.isFull ? 'Full' : 'Join', style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('$label: $value', style: TextStyle(color: color, fontSize: 13)),
    );
  }
}

// -----------------------------------------------------------------
// ROOM MODEL (duplicate here – you can also export from a shared file)
// -----------------------------------------------------------------
class Room {
  final int id;
  final String difficulty;
  final int entry;
  final int currentPlayers;
  final int maxPlayers;
  final int pot;
  final String status;
  final bool isFull;
  final String gameName;          // NEW – needed for navigation

  Room({
    required this.id,
    required this.difficulty,
    required this.entry,
    required this.currentPlayers,
    required this.maxPlayers,
    required this.pot,
    required this.status,
    required this.isFull,
    required this.gameName,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    final cur = json['currentPlayers'] ?? 0;
    final max = json['maxPlayers'] ?? 2;
    return Room(
      id: json['id'] ?? 0,
      difficulty: (json['difficulty'] ?? 'BEGINNER').toString().toUpperCase(),
      entry: (json['entry'] ?? 0).toInt(),
      currentPlayers: cur,
      maxPlayers: max,
      pot: (json['pot'] ?? 0).toInt(),
      status: json['status'] ?? 'WAITING',
      isFull: cur >= max,
      gameName: json['game']?.toString() ?? '',
    );
  }
}