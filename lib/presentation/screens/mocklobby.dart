// lib/presentation/lobby/lobby_screen.dart (Mock Data Version - API Calls Commented Out)
// Use this for UI testing while endpoints are not ready. Uncomment API when ready.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:street/presentation/providers/game_provider.dart'; // For balance
// For token (mocked here)

class LobbyScreen1 extends StatefulWidget {
  final String gameName; // e.g., 'Snooker', 'Ludo'

  const LobbyScreen1({super.key, required this.gameName});

  @override
  State<LobbyScreen1> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen1> {
  int _selectedFilter = 0; // 0: All, 1: Beginner, 2: Intermediate
  int _selectedSort = 0; // 0: Stake, 1: Players, 2: Pot
  final List<Room> _rooms = _generateMockRooms(); // Use mock data for now
  final bool _isLoading = false; // No loading for mocks
  Timer? _pollTimer; // Disabled for mocks

  @override
  void initState() {
    super.initState();
    // _fetchRooms(); // Commented out - using mocks
    // _pollTimer = Timer.periodic(const Duration(seconds: 5), (timer) => _fetchRooms()); // Disabled
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // Mock data generation (replace with API when ready)
  static List<Room> _generateMockRooms() {
    return [
      Room(id: 1, difficulty: 'BEGINNER', entry: 50, currentPlayers: 1, maxPlayers: 2, pot: 100, status: 'Active'),
      Room(id: 2, difficulty: 'INTERMEDIATE', entry: 100, currentPlayers: 2, maxPlayers: 2, pot: 200, status: 'Active', isFull: true),
      Room(id: 3, difficulty: 'BEGINNER', entry: 25, currentPlayers: 0, maxPlayers: 2, pot: 50, status: 'Waiting for players'),
      Room(id: 4, difficulty: 'BEGINNER', entry: 25, currentPlayers: 0, maxPlayers: 2, pot: 50, status: 'Waiting for players'),
      Room(id: 5, difficulty: 'INTERMEDIATE', entry: 75, currentPlayers: 1, maxPlayers: 2, pot: 150, status: 'Active'),
      Room(id: 6, difficulty: 'INTERMEDIATE', entry: 75, currentPlayers: 1, maxPlayers: 2, pot: 150, status: 'Active'),
      Room(id: 7, difficulty: 'BEGINNER', entry: 50, currentPlayers: 1, maxPlayers: 2, pot: 100, status: 'Active'),
      Room(id: 8, difficulty: 'INTERMEDIATE', entry: 100, currentPlayers: 2, maxPlayers: 2, pot: 200, status: 'Active', isFull: true),
    ];
  }

  // Commented out - real API call
  /*
  Future<void> _fetchRooms() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('https://your-api.com/api/rooms/${widget.gameName.toLowerCase()}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        setState(() {
          _rooms = data.map((json) => Room.fromJson(json)).toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  */

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final double balance = gameProvider.balance;

    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          widget.gameName,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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
                Text(balance.toStringAsFixed(3), style: const TextStyle(color: Colors.orange, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Match and Create Room buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Quick match logic (mock for now)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Joining Quick Match for ${widget.gameName}')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Quick Match', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Navigate to Create Room screen (mock for now)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Creating Room for ${widget.gameName}')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Create Room', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
          // Filters and Sort
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _getFilterLabel(),
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: ['All', 'Beginner', 'Intermediate']
                        .map((filter) => DropdownMenuItem(value: filter, child: Text(filter)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFilter = ['All', 'Beginner', 'Intermediate'].indexOf(value!);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<String>(
                    value: _getSortLabel(),
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: ['Stake', 'Players', 'Pot']
                        .map((sort) => DropdownMenuItem(value: sort, child: Text(sort)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSort = ['Stake', 'Players', 'Pot'].indexOf(value!);
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Rooms List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
                : _rooms.isEmpty
                    ? const Center(child: Text('No rooms available', style: TextStyle(color: Colors.white70)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: _getFilteredRooms().length,
                        itemBuilder: (context, index) {
                          final room = _getFilteredRooms()[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _buildRoomItem(room),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  List<Room> _getFilteredRooms() {
    var filtered = _rooms;
    if (_selectedFilter == 1) filtered = filtered.where((r) => r.difficulty == 'BEGINNER').toList();
    if (_selectedFilter == 2) filtered = filtered.where((r) => r.difficulty == 'INTERMEDIATE').toList();
    // Apply sorting
    switch (_selectedSort) {
      case 0: // Stake
        filtered.sort((a, b) => b.entry.compareTo(a.entry));
        break;
      case 1: // Players
        filtered.sort((a, b) => b.currentPlayers.compareTo(a.currentPlayers));
        break;
      case 2: // Pot
        filtered.sort((a, b) => b.pot.compareTo(a.pot));
        break;
    }
    return filtered;
  }

  String _getFilterLabel() => ['All', 'Beginner', 'Intermediate'][_selectedFilter];
  String _getSortLabel() => ['Stake', 'Players', 'Pot'][_selectedSort];

  Widget _buildRoomItem(Room room) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: Row(
        children: [
          // Table Icon
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.table_view, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Table ${room.id}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(room.difficulty, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStatChip('Entry', room.entry.toString(), Colors.green),
                    const SizedBox(width: 8),
                    _buildStatChip('Players', '${room.currentPlayers}/${room.maxPlayers}', Colors.blue),
                    const SizedBox(width: 8),
                    _buildStatChip('Pot', room.pot.toString(), Colors.orange),
                  ],
                ),
                const SizedBox(height: 8),
                Text(room.status, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text('Room ID: ${room.id}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
              ],
            ),
          ),
          // Join Game Button
          ElevatedButton(
            onPressed: room.isFull ? null : () => _joinRoom(room),
            style: ElevatedButton.styleFrom(
              backgroundColor: room.isFull ? Colors.grey : Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(room.isFull ? 'Room Full' : 'Join Game'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text('$label: $value', style: TextStyle(color: color, fontSize: 12)),
    );
  }

  // Commented out - real join API call
  /*
  Future<void> _joinRoom(Room room) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in')));
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://your-api.com/api/rooms/${widget.gameName.toLowerCase()}/${room.id}/join'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Joined Room ${room.id} for ${widget.gameName}')),
        );
        // Refresh rooms
        _fetchRooms();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Join failed: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  */

  void _joinRoom(Room room) {
    // Mock join for UI testing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Joined Room ${room.id} for ${widget.gameName}')),
    );
  }
}

// Room Model for Custom Backend
class Room {
  final int id;
  final String difficulty;
  final int entry;
  final int currentPlayers;
  final int maxPlayers;
  final int pot;
  final String status;
  final bool isFull;

  Room({
    required this.id,
    required this.difficulty,
    required this.entry,
    required this.currentPlayers,
    required this.maxPlayers,
    required this.pot,
    required this.status,
    this.isFull = false,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] ?? 0,
      difficulty: json['difficulty'] ?? 'BEGINNER',
      entry: json['entry'] ?? 0,
      currentPlayers: json['currentPlayers'] ?? 0,
      maxPlayers: json['maxPlayers'] ?? 2,
      pot: json['pot'] ?? 0,
      status: json['status'] ?? 'WAITING',
      isFull: (json['currentPlayers'] ?? 0) >= (json['maxPlayers'] ?? 2),
    );
  }
}