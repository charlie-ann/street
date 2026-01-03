import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:street/core/endpoints.dart';
import 'package:street/presentation/providers/auth_provider.dart';
import 'package:street/presentation/providers/rooms_provider.dart';

class CreateRoomModal extends StatefulWidget {
  final String gameName;

  const CreateRoomModal({super.key, required this.gameName});

  @override
  State<CreateRoomModal> createState() => _CreateRoomModalState();
}

class _CreateRoomModalState extends State<CreateRoomModal> {
  int _selectedStake = 100;
  bool _isPublic = true;
  String _difficulty = 'Intermediate';

  final List<int> stakes = [25, 50, 100, 250];
  final List<String> difficulties = ['Beginner', 'Intermediate', 'Pro'];

  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              color: Colors.black.withOpacity(0.8),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyan.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Create Room',
                          style: TextStyle(color: Colors.cyan, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.close, color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    const Text('Entry Stake', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: stakes.map((stake) {
                        final isSelected = _selectedStake == stake;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedStake = stake),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: isSelected ? const LinearGradient(colors: [Colors.green, Colors.lightGreen]) : null,
                              color: isSelected ? null : Colors.grey[800],
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: isSelected ? Colors.green : Colors.transparent),
                            ),
                            child: Text(
                              '$stake',
                              style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$_selectedStake',
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.token, color: Colors.amber, size: 20),
                          const Text(' Tokens', style: TextStyle(color: Colors.amber)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    const Text('Room Type', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _roomTypeButton('Public', Icons.public, _isPublic, Colors.cyan),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _roomTypeButton('Private', Icons.lock, !_isPublic, Colors.purple),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    const Text('Difficulty Level', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: difficulties.map((level) {
                        final isSelected = _difficulty == level;
                        return GestureDetector(
                          onTap: () => setState(() => _difficulty = level),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? level == 'Beginner'
                                      ? Colors.blue
                                      : level == 'Intermediate'
                                          ? Colors.orange
                                          : Colors.red
                                  : Colors.grey[800],
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              level,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 40),

                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => context.pop(),
                            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isCreating ? null : _createRoom,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            child: _isCreating
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('Create Room', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roomTypeButton(String label, IconData icon, bool selected, Color color) {
    return GestureDetector(
      onTap: () => setState(() => _isPublic = label == 'Public'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: selected ? LinearGradient(colors: [color, color.withOpacity(0.7)]) : null,
          color: selected ? null : Colors.grey[800],
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? Colors.white : Colors.white70, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: selected ? Colors.white : Colors.white70, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createRoom() async {
    if (_isCreating) return;
    setState(() => _isCreating = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final roomsProvider = Provider.of<RoomsProvider>(context, listen: false);
    final token = auth.token;

    if (token == null) {
      context.go('/auth');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${Endpoints.baseUrl}/game/${widget.gameName.toLowerCase()}/rooms'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'host': {
            'id': auth.userId ?? 'unknown',
            'username': auth.username ?? 'Player',
          },
          'entry': _selectedStake,
          'isPublic': _isPublic,
          'difficulty': _difficulty.toUpperCase(),
          'generateCode': !_isPublic, // Generate code for private rooms
          'gameName': widget.gameName, // Explicitly set game name
        }),
      );

      debugPrint('Create Room Response: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        final String roomId = data['roomId']?.toString() ?? '';

        if (roomId.isEmpty) {
          throw Exception('No room ID returned');
        }

        debugPrint('Room created successfully with ID: $roomId');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Room Created!'), backgroundColor: Colors.green),
        );

        if (mounted) context.pop();

        debugPrint('=== CREATE ROOM NAVIGATION ===');
        debugPrint('Selected stake: $_selectedStake');
        debugPrint('Room ID: $roomId');
        debugPrint('Navigation extra: ${{
          'roomId': roomId,
          'gameName': widget.gameName,
          'isPrivate': !_isPublic,
          'roomCode': data['code']?.toString(),
          'entryFee': _selectedStake,
        }}');
        debugPrint('==============================');
        
        context.push('/matchmaking', extra: {
          'roomId': roomId,
          'gameName': widget.gameName,
          'isPrivate': !_isPublic,
          'roomCode': data['roomCode']?.toString(),
          'entryFee': _selectedStake,
          'initialRoomData': data,
        });
      } else {
        final error = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error['message'] ?? 'Failed to create room')),
        );
      }
    } catch (e, stack) {
      debugPrint('Create room error: $e\n$stack');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create room')),
      );
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }
} 
      