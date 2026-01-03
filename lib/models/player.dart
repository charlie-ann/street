// 2. CREATE PLAYER MODEL
// lib/models/player.dart
class Player {
  final String id;
  final String username;
  final String? avatar;

  Player({
    required this.id,
    required this.username,
    this.avatar,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'avatar': avatar,
  };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
    id: json['id'],
    username: json['username'],
    avatar: json['avatar'],
  );
}