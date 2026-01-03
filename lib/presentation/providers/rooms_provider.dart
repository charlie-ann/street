import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:street/core/endpoints.dart';
import 'package:street/presentation/providers/auth_provider.dart';

class Room {
  final String id;
  final String game;
  final int entry;
  final int currentPlayers;
  final int maxPlayers;
  final bool isPublic;
  final String? code;
  final Map<String, dynamic> creator;  // Host info
  final List<Map<String, dynamic>> players; // Full list of players

  Room({
    required this.id,
    required this.game,
    required this.entry,
    required this.currentPlayers,
    required this.maxPlayers,
    required this.isPublic,
    this.code,
    required this.creator,
    required this.players,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    // Safe number parser — handles string or int
    int safeParseInt(dynamic value, int fallback) {
      if (value == null) return fallback;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    // Extract creator (host) safely
    Map<String, dynamic> cleanCreator = {'id': 'unknown', 'username': 'Player'};
    dynamic hostData = json['host'] ?? json['creator'];
    if (hostData != null && hostData is Map) {
      if (hostData['host'] is Map) {
        cleanCreator = Map.from(hostData['host']);
      } else {
        cleanCreator = Map.from(hostData);
      }
    }

    // Extract players safely from nested structure
    List<Map<String, dynamic>> cleanPlayers = [];
    final playersList = json['players'] as List?;
    if (playersList != null) {
      cleanPlayers = playersList.map((p) {
        if (p is Map) {
          if (p['host'] is Map) return Map<String, dynamic>.from(p['host']);
          return Map<String, dynamic>.from(p);
        }
        return {'id': 'unknown', 'username': 'Player'};
      }).toList();
    }

    return Room(
      id: (json['id'] ?? json['roomId'] ?? '').toString(),
      game: (json['gameName'] ?? json['game'] ?? json['gameId'] ?? 'ludo').toString().toLowerCase(),
      entry: safeParseInt(json['entry'], 100),
      currentPlayers: cleanPlayers.length,
      maxPlayers: safeParseInt(json['maxPlayers'], 4),
      isPublic: json['isPublic'] == true,
      code: json['code'] as String?,
      creator: cleanCreator,
      players: cleanPlayers, // Now available for MatchmakingScreen
    );
  }
}

class RoomsProvider with ChangeNotifier {
  List<Room> _rooms = [];
  bool _isLoading = true;
  String? _error;

  List<Room> get rooms => List.unmodifiable(_rooms);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchRooms(String gameName, BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;

    if (token == null) {
      _error = 'Not authenticated';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Try multiple endpoints to get all public rooms
      final endpoints = [
        '${Endpoints.baseUrl}/game/${gameName.toLowerCase()}/rooms',
        '${Endpoints.baseUrl}/game/ludo/rooms',
        '${Endpoints.baseUrl}/rooms',
      ];
      
      http.Response? response;
      
      for (final endpoint in endpoints) {
        try {
          response = await http.get(
            Uri.parse(endpoint),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );
          
          if (response.statusCode == 200) {
            break;
          }
        } catch (e) {
          continue;
        }
      }

      if (response?.statusCode == 200) {
        final List<dynamic> rawData = json.decode(response!.body);
        _rooms = rawData
            .map((json) => Room.fromJson(json as Map<String, dynamic>))
            .where((room) => 
              room.isPublic && 
              room.currentPlayers < room.maxPlayers &&
              room.game.toLowerCase() == gameName.toLowerCase())
            .toList();
      } else {
        _error = 'Failed to load rooms (${response?.statusCode})';
      }
    } catch (e) {
      debugPrint('Fetch rooms error: $e');
      _error = 'Network error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add or update room (used after create or join)
  void upsertRoom(Room room) {
    final index = _rooms.indexWhere((r) => r.id == room.id);
    if (index != -1) {
      _rooms[index] = room; // Update existing
    } else {
      _rooms.insert(0, room); // New room at top
    }
    notifyListeners();
  }

  // Legacy compatibility
  void addRoomAndNotify(Room room) => upsertRoom(room);

  // Update specific room (for future real-time)
  void updateRoom(String roomId, Room updatedRoom) => upsertRoom(updatedRoom);

  // Clear all
  void clear() {
    _rooms.clear();
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}