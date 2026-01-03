import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:street/core/endpoints.dart';
import 'package:street/presentation/providers/auth_provider.dart';

class MatchmakingScreen extends StatefulWidget {
  final String roomId;
  final String gameName;
  final bool isPrivate;
  final String? roomCode;
  final int? entryFee;
  final Map<String, dynamic>? initialRoomData;

  const MatchmakingScreen({
    super.key,
    required this.roomId,
    required this.gameName,
    required this.isPrivate,
    this.roomCode,
    this.entryFee,
    this.initialRoomData,
  });

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen> {
  Map<String, dynamic>? roomData;
  Timer? _pollTimer;
  Timer? _countdownTimer;
  int _countdown = 0;
  bool _isLoading = true;
  bool _isStarting = false;
  bool _isPlayingWithAI = false;
  IO.Socket? _socket;

  @override
  void initState() {
    super.initState();
    if (widget.initialRoomData != null) {
      setState(() {
        roomData = widget.initialRoomData;
        _isLoading = false;
      });
    }
    _initSocket();
    _joinRoom(); // Join the room first
    _fetchRoom();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _fetchRoom());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    _socket?.disconnect();
    super.dispose();
  }

  void _initSocket() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    
    if (token == null) return;
    
    _socket = IO.io(Endpoints.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'extraHeaders': {'Authorization': 'Bearer $token'}
    });
    
    _socket?.connect();
    
    _socket?.on('roomUpdate', (room) {
      debugPrint('=== SOCKET ROOM UPDATE RECEIVED ===');
      debugPrint('Raw room data: $room');
      debugPrint('Room players: ${room?['players']}');
      debugPrint('Room playerCount: ${room?['playerCount']}');
      debugPrint('Room totalPot: ${room?['totalPot']}');
      
      if (mounted && room != null) {
        debugPrint('Processing socket room update...');
        setState(() {
          roomData = Map<String, dynamic>.from(room);
        });
        
        final updatedPlayers = _extractPlayers(roomData!['players']);
        debugPrint('After socket update - players count: ${updatedPlayers.length}');
        debugPrint('Updated players: $updatedPlayers');
        debugPrint('=== SOCKET UPDATE COMPLETE ===');
      } else {
        debugPrint('Socket update ignored - mounted: $mounted, room: ${room != null}');
      }
    });
    
    _socket?.on('connect', (_) {
      debugPrint('=== SOCKET CONNECTED ===');
      debugPrint('Joining room: ${widget.roomId}');
      _socket?.emit('joinRoom', widget.roomId);
    });
    
    _socket?.on('disconnect', (_) {
      debugPrint('=== SOCKET DISCONNECTED ===');
    });
    
    _socket?.on('connect_error', (error) {
      debugPrint('=== SOCKET CONNECTION ERROR ===');
      debugPrint('Error: $error');
    });
  }

  Future<void> _fetchRoom() async {
    if (!mounted) return;
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;

    if (token == null) {
      if (mounted) context.go('/auth');
      return;
    }

    try {
      debugPrint('=== FETCHING ROOM ${widget.roomId} ===');
      
      // Try all rooms endpoint first
      final allRoomsResp = await http.get(
        Uri.parse('${Endpoints.baseUrl}/game/${widget.gameName.toLowerCase()}/rooms'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      debugPrint('All rooms response status: ${allRoomsResp.statusCode}');
      
      if (allRoomsResp.statusCode == 200) {
        final allRoomsData = json.decode(allRoomsResp.body);
        debugPrint('All rooms count: ${allRoomsData is List ? allRoomsData.length : 'not a list'}');
        
        if (allRoomsData is List) {
          // Find our room
          Map<String, dynamic>? foundRoom;
          for (var room in allRoomsData) {
            final roomId = room['roomId']?.toString() ?? room['id']?.toString();
            debugPrint('Checking room: $roomId vs target: ${widget.roomId}');
            if (roomId == widget.roomId) {
              foundRoom = room;
              debugPrint('FOUND OUR ROOM: $foundRoom');
              break;
            }
          }
          
          if (foundRoom != null) {
            final playersData = foundRoom['players'];
            final hostData = foundRoom['host'];
            final hostId = hostData is Map<String, dynamic> ? hostData['id']?.toString() : 'unknown';
            
            debugPrint('Raw players data: $playersData');
            debugPrint('Players type: ${playersData.runtimeType}');
            debugPrint('Players length: ${playersData is List ? playersData.length : 'not a list'}');
            
            if (mounted) {
              setState(() {
                roomData = foundRoom;
                _isLoading = false;
              });
              // Force another setState to ensure UI updates
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) setState(() {});
              });
            }

            // Check for workaround Player 2 (current user joining)
            final currentUserId = auth.userId;
            final currentUsername = auth.username;
            
            // If current user ID is null but they match the host, update the user ID FIRST
            if (currentUserId == null && currentUsername != null && hostData is Map<String, dynamic>) {
              final hostUsername = hostData['username']?.toString();
              if (currentUsername == hostUsername) {
                final extractedHostId = (hostData['_id'] ?? hostData['id'])?.toString();
                if (extractedHostId != null) {
                  debugPrint('Updating null user ID with host ID: $extractedHostId');
                  auth.setUserId(extractedHostId);
                }
              }
            }
            
            // Get the updated user ID after potential fix
            final updatedUserId = auth.userId ?? currentUserId;
            
            final players = _extractPlayers(playersData ?? []);
            debugPrint('Extracted ${players.length} players: $players');
            debugPrint('Looking for host ID: $hostId in players');
            debugPrint('Updated user ID: $updatedUserId');
            debugPrint('All player IDs: ${players.map((p) => p['id']).toList()}');
            
            bool hasWorkaroundPlayer2 = false;
            if (updatedUserId != null && updatedUserId != hostId) {
              hasWorkaroundPlayer2 = true;
              
              // Add current user as Player 2 to the players array
              final currentUserPlayer = {
                'id': updatedUserId,
                'username': currentUsername ?? 'Player 2',
                'avatar': auth.avatar ?? 'https://api.dicebear.com/7.x/avataaars/png?seed=$updatedUserId&size=150',
              };
              
              // Check if current user is already in players array
              bool userAlreadyInArray = players.any((p) => p['id'] == updatedUserId);
              if (!userAlreadyInArray) {
                players.add(currentUserPlayer);
                debugPrint('Added current user as Player 2: $currentUserPlayer');
              }
            } else if (updatedUserId == null && currentUsername != null && hostData is Map<String, dynamic>) {
              final hostUsername = hostData['username']?.toString();
              hasWorkaroundPlayer2 = currentUsername != hostUsername;
            }
            
            final totalPlayers = players.length;
            debugPrint('Updated players array length: $totalPlayers');
            debugPrint('Updated players: $players');
            
            if (totalPlayers >= 2 && _countdown == 0 && mounted) {
              debugPrint('Starting countdown - 2+ players found');
              _startCountdown();
            }

            if (foundRoom['status'] == 'IN_PROGRESS' || foundRoom['status'] == 'STARTED') {
              _pollTimer?.cancel();
              _countdownTimer?.cancel();
              if (mounted) {
                final players = _extractPlayers(roomData!['players']);
                final hostId = hostData is Map<String, dynamic> ? (hostData['_id'] ?? hostData['id'])?.toString() ?? 'unknown' : 'unknown';
                context.go('/ludo/${widget.roomId}/$hostId', extra: {
                  'players': players,
                  'isHost': isCreator,
                  'gameName': widget.gameName,
                });
              }
            }
            return;
          } else {
            debugPrint('Room ${widget.roomId} not found in rooms list');
          }
        }
      }
      
      debugPrint('Fallback: trying direct room endpoints');
      // Fallback to direct endpoints
      final endpoints = [
        '${Endpoints.baseUrl}/game/${widget.gameName.toLowerCase()}/rooms/${widget.roomId}',
        '${Endpoints.baseUrl}/game/ludo/rooms/${widget.roomId}',
      ];
      
      for (final endpoint in endpoints) {
        try {
          final resp = await http.get(
            Uri.parse(endpoint),
            headers: {'Authorization': 'Bearer $token'},
          );
          
          debugPrint('Direct endpoint $endpoint: ${resp.statusCode}');
          
          if (resp.statusCode == 200) {
            final data = json.decode(resp.body);
            debugPrint('Direct room data: $data');
            
            if (mounted) {
              setState(() {
                roomData = data;
                _isLoading = false;
              });
            }
            return;
          }
        } catch (e) {
          debugPrint('Direct endpoint error: $e');
        }
      }
      
      debugPrint('All fetch attempts failed');
    } catch (e) {
      debugPrint('Fetch room error: $e');
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startCountdown() {
    setState(() => _countdown = 10);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
        _autoStartGame();
      }
    });
  }

  Future<void> _joinRoom() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;

    if (token == null) return;

    try {
      await http.post(
        Uri.parse('${Endpoints.baseUrl}/game/ludo/rooms/${widget.roomId}/join'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      debugPrint('Joined room successfully');
    } catch (e) {
      debugPrint('Join room error: $e');
    }
  }

  Future<void> _autoStartGame() async {
    debugPrint('=== AUTO START GAME ===');
    
    if (!mounted) return;
    
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Starting game...'), backgroundColor: Colors.green),
      );
      final players = roomData != null ? _extractPlayers(roomData!['players']) : [];
      final hostData = roomData?['host'];
      final hostId = hostData is Map<String, dynamic> ? (hostData['_id'] ?? hostData['id'])?.toString() ?? 'unknown' : 'unknown';
      context.go('/ludo/${widget.roomId}/$hostId', extra: {
        'players': players,
        'isHost': isCreator,
        'gameName': widget.gameName,
      });
    } catch (e) {
      debugPrint('Auto start game error: $e');
      if (mounted) {
        final players = roomData != null ? _extractPlayers(roomData!['players']) : [];
        final hostData = roomData?['host'];
        final hostId = hostData is Map<String, dynamic> ? (hostData['_id'] ?? hostData['id'])?.toString() ?? 'unknown' : 'unknown';
        context.go('/ludo/${widget.roomId}/$hostId', extra: {
          'players': players,
          'isHost': isCreator,
          'gameName': widget.gameName,
        });
      }
    }
  }

  Future<void> _forceStartGame() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;

    if (token == null) return;

    setState(() => _isStarting = true);

    try {
      await http.post(
        Uri.parse('${Endpoints.baseUrl}/game/ludo/rooms/${widget.roomId}/start'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Game Started!'), backgroundColor: Colors.green),
      );
      
      final players = roomData != null ? _extractPlayers(roomData!['players']) : [];
      final hostData = roomData?['host'];
      final hostId = hostData is Map<String, dynamic> ? (hostData['_id'] ?? hostData['id'])?.toString() ?? 'unknown' : 'unknown';
      context.go('/ludo/${widget.roomId}/$hostId', extra: {
        'players': players,
        'isHost': isCreator,
        'gameName': widget.gameName,
      });
    } catch (e) {
      debugPrint('Start game error: $e');
      final players = roomData != null ? _extractPlayers(roomData!['players']) : [];
      final hostData = roomData?['host'];
      final hostId = hostData is Map<String, dynamic> ? (hostData['_id'] ?? hostData['id'])?.toString() ?? 'unknown' : 'unknown';
      context.go('/ludo/${widget.roomId}/$hostId', extra: {
        'players': players,
        'isHost': isCreator,
        'gameName': widget.gameName,
      });
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  Future<void> _kickPlayer(String playerId) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    try {
      final resp = await http.post(
        Uri.parse('${Endpoints.baseUrl}/game/rooms/${widget.roomId}/kick'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'playerId': playerId}),
      );

      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Player kicked'), backgroundColor: Colors.green),
        );
        _fetchRoom();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kick failed')));
    }
  }

  void _shareRoom() {
    final code = widget.roomCode ?? widget.roomId;
    final link = 'https://streetgame.app/join/$code';
    Share.share('Join my ${widget.gameName} room!\nRoom: $code\n$link', subject: 'Play ${widget.gameName} with me!');
  }

  void _copyCode() {
    final code = widget.roomCode ?? widget.roomId;
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Room ID copied!'), backgroundColor: Colors.green),
    );
  }

  void _playWithAI() {
    setState(() => _isPlayingWithAI = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Playing with AI!'), backgroundColor: Colors.blue),
    );
    _forceStartGame();
  }

  bool get isCreator {
    if (!mounted) return false;
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = auth.userId;
    final currentUsername = auth.username;
    final hostData = roomData?['host'];
    
    debugPrint('=== IS CREATOR CHECK ===');
    debugPrint('Current user ID: $currentUserId');
    debugPrint('Current username: $currentUsername');
    debugPrint('Host data: $hostData');
    
    // If no room data yet, assume current user is creator (they just created the room)
    if (roomData == null) {
      debugPrint('No room data - assuming creator');
      return true;
    }
    
    // Check if current user is the host (room creator)
    if (hostData is Map<String, dynamic>) {
      final hostId = (hostData['_id'] ?? hostData['id'])?.toString();
      final hostUsername = hostData['username']?.toString();
      debugPrint('Host ID: $hostId, Host username: $hostUsername');
      
      // Primary check: user ID matches host ID (only if user ID is not null)
      if (currentUserId != null && hostId != null && currentUserId == hostId) {
        debugPrint('User ID matches host ID - is creator');
        return true;
      }
      
      // Fallback check: username matches host username
      if (currentUsername != null && hostUsername != null && currentUsername == hostUsername) {
        debugPrint('Username matches host username - is creator');
        return true;
      }
    }
    
    // If current user ID is null, check if they're the only player (likely the creator)
    if (currentUserId == null && currentUsername != null && roomData != null) {
      final players = _extractPlayers(roomData!['players']);
      debugPrint('Current user ID is null, players count: ${players.length}');
      // Check if current username matches any player (and they're likely the host)
      for (var player in players) {
        if (player['username'] == currentUsername) {
          debugPrint('Username found in players - assuming creator if only 1 player');
          return players.length <= 1;
        }
      }
    }
    
    debugPrint('User is not creator');
    return false;
  }

  int _safeParseInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? fallback;
    }
    if (value is double) return value.toInt();
    return fallback;
  }

  List<Map<String, dynamic>> _extractPlayers(dynamic rawPlayers) {
    if (rawPlayers == null || rawPlayers is! List) return [];

    return rawPlayers.map<Map<String, dynamic>?>((p) {
      if (p is Map<String, dynamic>) {
        return {
          'id': (p['_id'] ?? p['id'])?.toString() ?? 'unknown',
          'username': p['username']?.toString() ?? 'Player',
          'avatar': p['avatar']?.toString() ?? 'https://api.dicebear.com/7.x/avataaars/png?seed=${p['_id'] ?? p['id']}&size=150',
        };
      }
      if (p is Map) {
        final converted = Map<String, dynamic>.from(p);
        return {
          'id': (converted['_id'] ?? converted['id'])?.toString() ?? 'unknown',
          'username': converted['username']?.toString() ?? 'Player',
          'avatar': converted['avatar']?.toString() ?? 'https://api.dicebear.com/7.x/avataaars/png?seed=${converted['_id'] ?? converted['id']}&size=150',
        };
      }
      return null;
    }).where((p) => p != null).cast<Map<String, dynamic>>().toList();
  }

  String _getPlayerAvatar(Map<String, dynamic> player, AuthProvider auth) {
    final playerId = player['id']?.toString();
    final playerUsername = player['username']?.toString();
    
    // If this player is the current user, use their avatar from auth provider
    if (playerId == auth.userId || playerUsername == auth.username) {
      return auth.avatar ?? 'https://api.dicebear.com/7.x/avataaars/png?seed=${auth.userId ?? playerId}&size=150';
    }
    
    // For other players, use their avatar or generate one based on their ID
    return player['avatar']?.toString() ?? 'https://api.dicebear.com/7.x/avataaars/png?seed=$playerId&size=150';
  }

  @override
  Widget build(BuildContext context) {
    // Handle initial state when roomData is null
    final List<Map<String, dynamic>> players = roomData != null ? _extractPlayers(roomData!['players']) : [];
    final int maxPlayers = _safeParseInt(roomData?['maxPlayers'], 2);
    final int currentEntryFee = _safeParseInt(roomData?['entry'], widget.entryFee ?? 100);
    final bool isFull = players.length >= maxPlayers;
    
    // Debug the current state
    debugPrint('=== BUILD DEBUG ===');
    debugPrint('RoomData: $roomData');
    debugPrint('Players from roomData: ${roomData?['players']}');
    debugPrint('Extracted players: $players');
    debugPrint('Players count: ${players.length}');
    debugPrint('==================');

    // Fixed: Safe host username extraction with fallbacks
    String hostUsername = 'Unknown';
    final hostData = roomData?['host'];
    if (hostData is Map<String, dynamic>) {
      hostUsername = hostData['username']?.toString() ?? 'Unknown';
    }
    
    // If still unknown, try to get from first player (who is usually the host)
    if (hostUsername == 'Unknown' && players.isNotEmpty) {
      hostUsername = players[0]['username']?.toString() ?? 'Unknown';
    }
    
    // If roomData is null, use current user as host (since they just created the room)
    if (hostUsername == 'Unknown' && roomData == null) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      hostUsername = auth.username ?? 'You';
    }
    
    // Calculate actual player count from the updated players array
    int actualPlayerCount = players.length;
    
    // Update total pot calculation
    final totalPot = currentEntryFee * actualPlayerCount;
    
    // Ensure hostUsername is properly set for display
    if (hostUsername == 'Unknown') {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      hostUsername = auth.username ?? 'You';
    }

    // Debug prints
    debugPrint('=== MATCHMAKING DEBUG ===');
    debugPrint('Widget entryFee: ${widget.entryFee}');
    debugPrint('RoomData entry: $currentEntryFee');
    debugPrint('Current entryFee: $currentEntryFee');
    debugPrint('Players count: $actualPlayerCount');
    debugPrint('RoomData host: $hostUsername');
    debugPrint('Players: $players');
    
    debugPrint('Final hostUsername: $hostUsername');
    debugPrint('Actual player count: $actualPlayerCount');
    debugPrint('Extracted players count: $actualPlayerCount');
    debugPrint('Entry fee: $currentEntryFee');
    debugPrint('========================');

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_ios, color: Colors.white)),
                    Text('${widget.gameName} - $hostUsername', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        IconButton(onPressed: _copyCode, icon: const Icon(Icons.copy, color: Colors.cyan)),
                        IconButton(onPressed: _shareRoom, icon: const Icon(Icons.share, color: Colors.green)),
                      ],
                    ),
                  ],
                ),
                if (widget.isPrivate && widget.roomCode != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.purple.withOpacity(0.3), borderRadius: BorderRadius.circular(30)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock, color: Colors.purpleAccent),
                        const SizedBox(width: 8),
                        Text(widget.roomCode!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                if (_countdown > 0)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange, width: 2),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.timer, color: Colors.orange, size: 32),
                        const SizedBox(height: 8),
                        const Text(
                          'Game starting in',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        Text(
                          '$_countdown',
                          style: const TextStyle(color: Colors.orange, fontSize: 48, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                Expanded(
                  child: _buildPlayersGrid(players, maxPlayers, isFull, currentEntryFee),
                ),

                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.shade700),
                  ),
                  child: Column(
                    children: [
                      const Text('Total Pot', style: TextStyle(color: Colors.white70)),
                      Text(
                        '$totalPot Tokens',
                        style: const TextStyle(color: Colors.amber, fontSize: 36, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                if (isCreator && actualPlayerCount >= 1 && !_isStarting)
                  ElevatedButton.icon(
                    onPressed: (actualPlayerCount >= 1 && !_isStarting) ? _forceStartGame : null,
                    icon: _isStarting
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                        : const Icon(Icons.play_arrow_rounded),
                    label: _isStarting ? const Text('Starting...') : const Text('Start Game'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: actualPlayerCount >= 1 ? Colors.green : Colors.grey,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),

                if (isCreator && actualPlayerCount < maxPlayers && !_isPlayingWithAI)
                  ElevatedButton.icon(
                    onPressed: _playWithAI,
                    icon: const Icon(Icons.computer),
                    label: const Text('Play with AI'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),

                const SizedBox(height: 10),

                ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Leave Room', style: TextStyle(fontSize: 16)),
                ),

                const SizedBox(height: 10),
                Text(
                  'Spectators: ${roomData?['spectators']?.length ?? 0}',
                  style: const TextStyle(color: Colors.white60),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildPlayersGrid(List<Map<String, dynamic>> players, int maxPlayers, bool isFull, int entryFee) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    // Player 1 is players[0] (host)
    final player1 = players.isNotEmpty ? players[0] : null;
    // Player 2 is players[1]
    final player2 = players.length > 1 ? players[1] : null;
    
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              const Text('Player 1', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                width: 150,
                height: 150,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.purple.withOpacity(0.7), Colors.purple.withOpacity(0.3)]),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.purple, width: 2),
                ),
                child: player1 != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(_getPlayerAvatar(player1, auth)),
                            onBackgroundImageError: (_, __) {},
                          ),
                          const SizedBox(height: 8),
                          Text(
                            player1['username'],
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('HOST', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.cyan),
                          SizedBox(height: 10),
                          Text('Loading...', style: TextStyle(color: Colors.white60)),
                        ],
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            children: [
              const Text('Player 2', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                width: 150,
                height: 150,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.green.withOpacity(0.7), Colors.green.withOpacity(0.3)]),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: player2 != null ? Colors.green : Colors.white24, width: 2),
                ),
                child: player2 != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(_getPlayerAvatar(player2, auth)),
                            onBackgroundImageError: (_, __) {},
                          ),
                          const SizedBox(height: 8),
                          Text(
                            player2['username'],
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              color: Colors.cyan,
                              strokeWidth: 3,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Waiting for\nopponent...',
                            style: TextStyle(color: Colors.white60, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerSlot(Map<String, dynamic>? player, int index, bool isFull, int entryFee, {bool isHost = false}) {
    final colors = [Colors.red, Colors.green, Colors.yellow, Colors.blue];
    final color = colors[index % colors.length];

    final String username = player?['username']?.toString() ?? 'Player';
    final String avatar = _getPlayerAvatar(player ?? {}, Provider.of<AuthProvider>(context, listen: false));
    
    debugPrint('Player slot $index: username=$username, avatar=$avatar, isHost=$isHost');

    if (player == null) {
      return Container(
        height: 180,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white24)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    color: Colors.cyan,
                    strokeWidth: 2,
                  ),
                ),
                Icon(Icons.person_add, size: 30, color: Colors.white30),
              ],
            ),
            const SizedBox(height: 10),
            const Text('Waiting for player...', style: TextStyle(color: Colors.white60)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
              child: Text('$entryFee Tokens', style: const TextStyle(color: Colors.amber)),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withOpacity(0.7), color.withOpacity(0.3)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color, width: 3),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 38,
                backgroundImage: NetworkImage(avatar),
                onBackgroundImageError: (_, __) {},
                child: null,
              ),
              const SizedBox(height: 10),
              Text(username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Player ${index + 1}', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                  if (isHost) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('HOST', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: Colors.amber.withOpacity(0.3), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.amber)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.token, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text('$entryFee Tokens', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),

        if (isCreator && !isFull && player['id'] != null && player['id'] != Provider.of<AuthProvider>(context).userId)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _kickPlayer(player['id']?.toString() ?? ''),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
      ],
    );
  }
}