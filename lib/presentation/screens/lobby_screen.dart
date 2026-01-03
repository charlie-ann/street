// lib/presentation/lobby/lobby_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:street/core/endpoints.dart';
import 'package:street/presentation/providers/auth_provider.dart';
import 'package:street/presentation/widgets/authenticated_screen.dart';
import 'package:street/presentation/widgets/create_room_modal.dart';
import 'package:street/presentation/widgets/join_room_modal.dart';

class LobbyScreen extends AuthenticatedScreen {
  final String gameName;

  const LobbyScreen({super.key, required this.gameName});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends AuthenticatedScreenState<LobbyScreen> {
  List<Room> _rooms = [];
  bool _isLoading = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _fetchRooms();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchRooms());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

// 3. UPDATE LOBBY SCREEN _fetchRooms() 
// lib/presentation/lobby/lobby_screen.dart
void _showError(String message) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<void> _fetchRooms() async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final token = authProvider.token;

  if (token == null || token.isEmpty) {
    if (mounted) context.go('/auth');
    return;
  }

  try {
    final response = await http.get(
      Uri.parse('${Endpoints.baseUrl}/game/${widget.gameName.toLowerCase()}/rooms'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      debugPrint('=== ROOMS DEBUG ===');
      debugPrint('API returned ${data.length} rooms');
      debugPrint('Current game: ${widget.gameName}');
      
      final allRooms = data.map((json) => Room.fromJson(json)).toList();
      debugPrint('Parsed ${allRooms.length} rooms');
      
      for (final room in allRooms) {
        debugPrint('Room ${room.id}: game=${room.gameName}, public=${room.isPublic}, status=${room.status}, full=${room.isFull}');
      }
      
      setState(() {
        _rooms = allRooms
            .where((room) => 
              room.isPublic && 
              room.status == 'WAITING' && 
              !room.isFull &&
              room.gameName.toLowerCase() == widget.gameName.toLowerCase())
            .toList();
      });
      
      debugPrint('Filtered to ${_rooms.length} rooms for ${widget.gameName}');
      debugPrint('==================');
    } else {
      debugPrint('API failed: ${response.statusCode}');
      _showError('Failed to load rooms: ${response.statusCode}');
    }
  } catch (e) {
    _showError('Network error: $e');
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  Future<void> _quickMatch() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null) return;

    try {
      final resp = await http.post(
        Uri.parse('${Endpoints.baseUrl}/api/quick-match/${widget.gameName.toLowerCase()}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final roomId = data['roomId'] ?? data['id'];
        final roomCode = data['code'];

        context.push('/matchmaking', extra: {
          'roomId': roomId,
          'gameName': widget.gameName,
          'isPrivate': false,
          'roomCode': roomCode,
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Quick match failed: $e')));
    }
  }

 // 5. UPDATE JOIN ROOM in LOBBY SCREEN
// lib/presentation/lobby/lobby_screen.dart
Future<void> _joinRoom(Room room) async {
  // Navigate directly to matchmaking screen
  context.push('/matchmaking', extra: {
    'roomId': room.id,
    'gameName': widget.gameName,
    'isPrivate': !room.isPublic,
    'roomCode': null,
    'entryFee': room.entry,
  });
}

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final balance = authProvider.walletBalance;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
        title: Text(widget.gameName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                const Icon(Icons.token, color: Colors.amber, size: 18),
                const SizedBox(width: 6),
                Text(balance.toStringAsFixed(2), style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Match + Create Room
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _quickMatch,
                    icon: const Icon(Icons.flash_on),
                    label: const Text('Quick Match'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.all(16)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => CreateRoomModal(gameName: widget.gameName),
                      );
                    },
                    icon: const Icon(Icons.add_box),
                    label: const Text('Create Room'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, padding: const EdgeInsets.all(16)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => JoinRoomModal(gameName: widget.gameName),
                      );
                    },
                    icon: const Icon(Icons.vpn_key),
                    label: const Text('Join Private Room'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade700, padding: const EdgeInsets.all(16)),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Colors.white24),

          // Rooms List
          Expanded(
            child: _rooms.isEmpty
                ? const Center(child: Text('No active rooms', style: TextStyle(color: Colors.white70, fontSize: 18)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _rooms.length,
                    itemBuilder: (context, index) {
                      final room = _rooms[index];
                      return _buildRoomCard(room);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard(Room room) {
    final isFull = room.currentPlayers >= 2;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.purple.withOpacity(0.3), Colors.blue.withOpacity(0.2)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purpleAccent.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('${widget.gameName} - ${room.username}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.3), borderRadius: BorderRadius.circular(20)),
                      child: Text(room.difficulty, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 10)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _chip('Entry: ${room.entry}', Icons.token, Colors.amber),
                    _chip('${room.currentPlayers}/2', Icons.people, Colors.cyan),
                    _chip('Pot: ${room.pot}', Icons.monetization_on, Colors.green),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            child: ElevatedButton(
              onPressed: isFull ? null : () => _joinRoom(room),
              style: ElevatedButton.styleFrom(
                backgroundColor: isFull ? Colors.grey : Colors.green,
                disabledBackgroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              child: Text(isFull ? 'Full' : 'Join'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// === ROOM MODEL ===
class Room {
  final String id;
  final String username;
  final String difficulty;
  final int entry;
  final int currentPlayers;
  final int maxPlayers;
  final int pot;
  final String status;
  final bool isPublic;
  final String gameName;

  Room({
    required this.id,
    required this.username,
    required this.difficulty,
    required this.entry,
    required this.currentPlayers,
    required this.maxPlayers,
    required this.pot,
    required this.status,
    required this.isPublic,
    required this.gameName,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    final playersData = json['players'] as List?;
    final current = playersData?.length ?? json['currentPlayers'] ?? 1;
    final max = json['maxPlayers'] ?? 2;
    final entryFee = json['entry'] ?? 100;
    
    // Extract host username
    String hostUsername = 'Unknown';
    final hostData = json['host'];
    if (hostData is Map<String, dynamic>) {
      hostUsername = hostData['username']?.toString() ?? 'Unknown';
    } else if (playersData != null && playersData.isNotEmpty) {
      final firstPlayer = playersData[0];
      if (firstPlayer is Map<String, dynamic>) {
        hostUsername = firstPlayer['username']?.toString() ?? 'Unknown';
      }
    }
    
    return Room(
      id: json['id']?.toString() ?? json['roomId']?.toString() ?? 'unknown',
      username: hostUsername,
      difficulty: (json['difficulty'] ?? 'INTERMEDIATE').toString().toUpperCase(),
      entry: entryFee is int ? entryFee : int.tryParse(entryFee.toString()) ?? 100,
      currentPlayers: current,
      maxPlayers: max,
      pot: json['pot'] ?? (entryFee * current),
      status: json['status'] ?? 'WAITING',
      isPublic: json['isPublic'] ?? true,
      gameName: json['gameName']?.toString() ?? json['game']?.toString() ?? 'Ludo',
    );
  }

  bool get isFull => currentPlayers >= maxPlayers;
}