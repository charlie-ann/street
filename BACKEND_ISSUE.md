# Backend Issue: Rooms Not Persisting

## Problem
Rooms created via POST requests are not being stored/returned by GET requests.

## Evidence
- POST `https://street-api-1kev.onrender.com/game/snooker/rooms` returns 201/200 (success)
- GET `https://street-api-1kev.onrender.com/game/ludo/rooms` returns 200 but with empty array `[]`
- GET `https://street-api-1kev.onrender.com/game/snooker/rooms` returns 200 but with empty array `[]`

## Expected Behavior
1. User creates a room via POST `/game/{gameName}/rooms`
2. Server stores the room in database/memory
3. GET `/game/{gameName}/rooms` returns all active rooms for that game
4. Other users can see and join these rooms

## Current Behavior
1. User creates a room via POST (returns success)
2. Room is NOT stored or immediately deleted
3. GET returns empty array
4. No rooms visible to any users

## Required Server-Side Fixes
1. **Persist rooms**: Store created rooms in database or in-memory storage
2. **Room lifecycle**: Keep rooms until game starts or all players leave
3. **GET endpoint**: Return all active rooms with status='WAITING'
4. **Cross-user visibility**: Ensure rooms created by one user are visible to all users

## API Endpoints That Need Fixing
- `POST /game/{gameName}/rooms` - Should persist room data
- `GET /game/{gameName}/rooms` - Should return all active rooms
- `GET /game/ludo/rooms` - Should return all Ludo rooms
- `GET /rooms` - (404 currently) - Optional global endpoint

## Room Data Structure Expected
```json
{
  "id": "room-uuid",
  "roomId": "room-uuid",
  "gameName": "Ludo",
  "host": {
    "id": "user-id",
    "username": "username"
  },
  "players": [],
  "entry": 100,
  "isPublic": true,
  "status": "WAITING",
  "maxPlayers": 2,
  "difficulty": "INTERMEDIATE"
}
```

## Testing
After fixing, test by:
1. Create room with user A
2. Login as user B
3. Check if user B can see user A's room in lobby
4. User B should be able to join the room

## Priority
**HIGH** - Core functionality is broken, users cannot see or join each other's rooms
