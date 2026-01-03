import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:street/core/endpoints.dart';
import 'package:street/presentation/providers/auth_provider.dart';

class JoinRoomModal extends StatefulWidget {
  final String gameName;

  const JoinRoomModal({super.key, required this.gameName});

  @override
  State<JoinRoomModal> createState() => _JoinRoomModalState();
}

class _JoinRoomModalState extends State<JoinRoomModal> {
  final TextEditingController _codeController = TextEditingController();
  bool _isJoining = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.cyan.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Join Private Room',
                  style: TextStyle(color: Colors.cyan, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Enter 6-digit room code',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.cyan),
                ),
              ),
              style: const TextStyle(color: Colors.white),
              maxLength: 6,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isJoining ? null : _joinRoom,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isJoining
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Join Room', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _joinRoom() async {
    final code = _codeController.text.trim();
    debugPrint('Join room attempt with code: $code');
    
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit code')),
      );
      return;
    }

    setState(() => _isJoining = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;

    if (token == null) {
      context.go('/auth');
      return;
    }

    try {
      // First, get all rooms to find the one with matching code
      final response = await http.get(
        Uri.parse('${Endpoints.baseUrl}/game/${widget.gameName.toLowerCase()}/rooms'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> rooms = json.decode(response.body);
        
        // Find room with matching code
        Map<String, dynamic>? targetRoom;
        for (final room in rooms) {
          if (room['code']?.toString() == code || room['roomCode']?.toString() == code) {
            targetRoom = room;
            break;
          }
        }
        
        if (targetRoom != null) {
          final roomId = targetRoom['id']?.toString() ?? targetRoom['roomId']?.toString();
          final entryFee = targetRoom['entry'] ?? 100;
          
          if (mounted && roomId != null) {
            Navigator.of(context).pop();
            context.push('/matchmaking', extra: {
              'roomId': roomId,
              'gameName': widget.gameName,
              'isPrivate': true,
              'roomCode': code,
              'entryFee': entryFee,
              'initialRoomData': targetRoom,
            });
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Room not found with that code')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load rooms')),
        );
      }
    } catch (e) {
      debugPrint('Join room error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}