class Endpoints {
  // Base URL - Update for dev/prod
  static const String baseUrl = 'https://street-api-1kev.onrender.com';
  
  // Debug flag for real device testing
  static const bool isDebug = true;

  // Auth endpoints
  static const String login = '$baseUrl/auth/login';
  static const String signup = '$baseUrl/auth/signup';

  // Other endpoints (add as needed)
 // static const String rooms = '$baseUrl/game/gameId/rooms';
  static const String walletbalance = '$baseUrl/users/userId';
  static const String rooms = '$baseUrl/game/gameId/rooms';
  static const String joinRoom = '$baseUrl/game/rooms/roomId/join';
  static const String spectateRoom = '$baseUrl/game/rooms/roomId/start';
  static const String startGame = '$baseUrl/game/rooms/roomId/startGame';

  static const String quickMatch = '$baseUrl/quick-match';
  //static const String joinRoom = '$baseUrl/rooms/{game}/{roomId}/join'; // Use string interpolation in calls
}