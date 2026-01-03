import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/effects.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:street/core/sound_manager.dart';
import 'state/player.dart';
import 'component/home/home.dart';
import 'state/token_manager.dart';
import 'state/event_bus.dart';
import 'component/home/home_spot.dart';
import 'state/game_state.dart';
import 'state/audio_manager.dart';
import 'component/controller/upper_controller.dart';
import 'component/controller/lower_controller.dart';
import 'ludo_board.dart';
import 'component/ui_components/token.dart';
import 'component/ui_components/spot.dart';
import 'component/ui_components/ludo_dice.dart';
import 'component/ui_components/rank_modal_component.dart';

class Ludo extends FlameGame
    with HasCollisionDetection, KeyboardEvents, TapDetector {
  List<String> teams;
  final BuildContext context;
  final String roomId;
  final String gameName;
  final List<dynamic> players;
  final bool isHost;

  // Add an unnamed constructor
  Ludo(this.teams, this.context, {required this.roomId, this.gameName = 'Ludo', this.players = const [], this.isHost = false});

  final rand = Random();
  double get width => size.x;
  double get height => size.y;

  ColorEffect? _greenBlinkEffect;
  ColorEffect? _greenStaticEffect;

  ColorEffect? _blueBlinkEffect;
  ColorEffect? _blueStaticEffect;

  ColorEffect? _yellowBlinkEffect;
  ColorEffect? _yellowStaticEffect;

  ColorEffect? _redBlinkEffect;
  ColorEffect? _redStaticEffect;

  @override
  void onLoad() async {
    super.onLoad();
    camera = CameraComponent.withFixedResolution(
      width: width,
      height: height,
    );
    camera.viewfinder.anchor = Anchor.topLeft;

    world.add(UpperController(
        position: Vector2(0, width * 0.05),
        width: width,
        height: width * 0.20));
    world.add(LudoBoard(
        width: width, height: width, position: Vector2(0, height * 0.175)));
    world.add(LowerController(
        position: Vector2(0, width + (width * 0.35)),
        width: width,
        height: width * 0.20));

    /*
    add(FpsTextComponent(
      position: Vector2(10, 10), // Adjust position as needed
      anchor: Anchor.topLeft, // Set anchor to align top-left
    ));
    */

    GameState().ludoBoard = world.children.whereType<LudoBoard>().first;
    final ludoBoard = GameState().ludoBoard as PositionComponent;
    GameState().ludoBoardAbsolutePosition = ludoBoard.absolutePosition;

    EventBus().on<OpenPlayerModalEvent>((event) {
      showPlayerModal();
    });

    EventBus().on<SwitchPointerEvent>((event) {
      switchOffPointer();
    });

    EventBus().on<BlinkGreenBaseEvent>((event) {
      blinkGreenBase(true);
      blinkYellowBase(true);
      blinkBlueBase(false);
      blinkRedBase(false);
      // Add dice for Player 2 (GP/YP)
      final player = GameState().currentPlayer;
      if (player.playerId == 'GP' || player.playerId == 'YP') {
        _addDiceForPlayer(player, false); // false for right position
      }
    });

    EventBus().on<BlinkBlueBaseEvent>((event) {
      blinkBlueBase(true);
      blinkRedBase(true);
      blinkGreenBase(false);
      blinkYellowBase(false);
      // Add dice for Player 1 (BP/RP)
      final player = GameState().currentPlayer;
      if (player.playerId == 'BP' || player.playerId == 'RP') {
        _addDiceForPlayer(player, true); // true for left position
      }
    });

    EventBus().on<BlinkRedBaseEvent>((event) {
      blinkRedBase(true);
      blinkGreenBase(false);
      blinkBlueBase(false);
      blinkYellowBase(false);
    });

    EventBus().on<BlinkYellowBaseEvent>((event) {
      blinkYellowBase(true);
      blinkGreenBase(false);
      blinkBlueBase(false);
      blinkRedBase(false);
    });

    await startGame();
  }

  void switchOffPointer() {
    final player = GameState().players[GameState().currentPlayerIndex];
    final lowerController = world.children.whereType<LowerController>().first;
    lowerController.hidePointer(player.playerId);
    final upperController = world.children.whereType<UpperController>().first;
    upperController.hidePointer(player.playerId);
  }

  void blinkRedBase(bool shouldBlink) {
    final childrenOfLudoBoard = GameState().ludoBoard?.children.toList();
    final child = childrenOfLudoBoard![0];
    final home = child.children.toList();
    final homePlate = home[0] as Home;

    _redBlinkEffect ??= ColorEffect(
      const Color(0xffa3333d),
      EffectController(
        duration: 0.2,
        reverseDuration: 0.2,
        infinite: true,
        alternate: true,
      ),
    );

    _redStaticEffect ??= ColorEffect(
      GameState().red,
      EffectController(
        duration: 0.2,
        reverseDuration: 0.2,
        infinite: true,
        alternate: true,
      ),
    );

    homePlate.add(shouldBlink ? _redBlinkEffect! : _redStaticEffect!);
  }

  void blinkYellowBase(bool shouldBlink) {
    final childrenOfLudoBoard = GameState().ludoBoard?.children.toList();
    final child = childrenOfLudoBoard![8];
    final home = child.children.toList();
    final homePlate = home[0] as Home;

    // Initialize effects if they haven't been created yet
    _yellowBlinkEffect ??= ColorEffect(
      Colors.yellowAccent,
      EffectController(
        duration: 0.2,
        reverseDuration: 0.2,
        infinite: true,
        alternate: true,
      ),
    );

    _yellowStaticEffect ??= ColorEffect(
      GameState().yellow,
      EffectController(
        duration: 0.2,
        reverseDuration: 0.2,
        infinite: true,
        alternate: true,
      ),
    );

    final lowerController = world.children.whereType<LowerController>().first;
    final lowerControllerComponents = lowerController.children.toList();
    final rightDice = lowerControllerComponents[2]
        .children
        .whereType<RectangleComponent>()
        .first;

    final rightDiceContainer =
        rightDice.children.whereType<RectangleComponent>().first;

    // Add the appropriate effect based on shouldBlink
    homePlate.add(shouldBlink ? _yellowBlinkEffect! : _yellowStaticEffect!);

    if (shouldBlink) {
      final player = GameState().players[GameState().currentPlayerIndex];
      if (player.playerId == 'YP') {
        rightDiceContainer.add(LudoDice(
          player: player,
          faceSize: rightDice.size.x * 0.70,
        ));
        lowerController.showPointer(player.playerId);
      }
    } else {
      final ludoDice =
          rightDiceContainer.children.whereType<LudoDice>().firstOrNull;
      if (ludoDice != null) {
        rightDiceContainer.remove(ludoDice);
      }
    }
  }

  void blinkBlueBase(bool shouldBlink) {
    final childrenOfLudoBoard = GameState().ludoBoard?.children.toList();
    final child = childrenOfLudoBoard![6];
    final home = child.children.toList();
    final homePlate = home[0] as Home;

    // Initialize effects if they haven't been created yet
    _blueBlinkEffect ??= ColorEffect(
      Colors.lightBlueAccent,
      EffectController(
        duration: 0.2,
        reverseDuration: 0.2,
        infinite: true,
        alternate: true,
      ),
    );

    _blueStaticEffect ??= ColorEffect(
      GameState().blue,
      EffectController(
        duration: 0.2,
        reverseDuration: 0.2,
        infinite: true,
        alternate: true,
      ),
    );

    // dice for player blue
    final lowerController = world.children.whereType<LowerController>().first;
    final lowerControllerComponents = lowerController.children.toList();
    final leftDice = lowerControllerComponents[0]
        .children
        .whereType<RectangleComponent>()
        .first;

    final leftDiceContainer =
        leftDice.children.whereType<RectangleComponent>().first;

    // Add the appropriate effect based on shouldBlink
    homePlate.add(shouldBlink ? _blueBlinkEffect! : _blueStaticEffect!);

    if (shouldBlink) {
      final ludoDice =
          leftDiceContainer.children.whereType<LudoDice>().firstOrNull;
      if (ludoDice == null) {
        if (GameState().players.isNotEmpty) {
          final player = GameState().players[GameState().currentPlayerIndex];
          if (player.playerId == 'BP') {
            leftDiceContainer.add(LudoDice(
              player: player,
              faceSize: leftDice.size.x * 0.70,
            ));
            lowerController.showPointer(player.playerId);
          }
        }
      }
    } else {
      final ludoDice =
          leftDiceContainer.children.whereType<LudoDice>().firstOrNull;
      if (ludoDice != null) {
        leftDiceContainer.remove(ludoDice);
      }
    }
  }

  void blinkGreenBase(bool shouldBlink) {
    final childrenOfLudoBoard = GameState().ludoBoard?.children.toList();
    final child = childrenOfLudoBoard![2];
    final home = child.children.toList();
    final homePlate = home[0] as Home;

    _greenBlinkEffect ??= ColorEffect(
      Colors.lightGreenAccent,
      EffectController(
        duration: 0.2,
        reverseDuration: 0.2,
        infinite: true,
        alternate: true,
      ),
    );

    _greenStaticEffect ??= ColorEffect(
      GameState().green,
      EffectController(
        duration: 0.2,
        reverseDuration: 0.2,
        infinite: true,
        alternate: true,
      ),
    );

    homePlate.add(shouldBlink ? _greenBlinkEffect! : _greenStaticEffect!);
  }

  Future<void> startGame() async {
    await TokenManager().clearTokens();
    await GameState().clearPlayers();
    await AudioManager.dispose();

    AudioManager.initialize();

    // Initialize Player 1 (controls BP and RP houses)
    Player? player1;
    // Initialize Player 2 (controls GP and YP houses)  
    Player? player2;
    
    bool player1Created = false;
    bool player2Created = false;

    for (var team in teams) {
      if (team == 'BP') {
        TokenManager().initializeTokens(TokenManager().blueTokensBase);
        _initializeTokensForHouse(6, TokenManager().getBlueTokens(), const Color(0xFF0D92F4), const Color(0xFF77CDFF));
        
        if (!player1Created) {
          player1 = Player(
            playerId: 'BP',
            tokens: TokenManager().getBlueTokens(),
            isCurrentTurn: true,
            enableDice: true,
          );
          GameState().players.add(player1);
          player1Created = true;
          blinkBlueBase(true);
          blinkRedBase(true);
          _addDiceForPlayer(player1, true); // true for lower controller left
        }
        
        for (var token in TokenManager().getBlueTokens()) {
          token.playerId = 'BP';
        }
      } else if (team == 'RP') {
        TokenManager().initializeTokens(TokenManager().redTokensBase);
        _initializeTokensForHouse(0, TokenManager().getRedTokens(), const Color(0xff780000), const Color(0xffFF5B5B));
        
        if (!player1Created) {
          player1 = Player(
            playerId: 'RP',
            tokens: TokenManager().getRedTokens(),
            isCurrentTurn: true,
            enableDice: true,
          );
          GameState().players.add(player1);
          player1Created = true;
          blinkRedBase(true);
          blinkBlueBase(true);
          _addDiceForPlayer(player1, true); // true for lower controller left
        } else if (player1 != null) {
          // Add red tokens to existing player1
          player1.tokens.addAll(TokenManager().getRedTokens());
        }
        
        for (var token in TokenManager().getRedTokens()) {
          token.playerId = player1?.playerId ?? 'RP';
        }
      } else if (team == 'GP') {
        TokenManager().initializeTokens(TokenManager().greenTokensBase);
        _initializeTokensForHouse(2, TokenManager().getGreenTokens(), const Color(0xFF54C392), const Color(0xFF73EC8B));
        
        if (!player2Created) {
          player2 = Player(
            playerId: 'GP',
            tokens: TokenManager().getGreenTokens(),
            isCurrentTurn: false,
            enableDice: false,
          );
          GameState().players.add(player2);
          player2Created = true;
        }
        
        for (var token in TokenManager().getGreenTokens()) {
          token.playerId = 'GP';
        }
      } else if (team == 'YP') {
        TokenManager().initializeTokens(TokenManager().yellowTokensBase);
        _initializeTokensForHouse(8, TokenManager().getYellowTokens(), const Color(0xffc9a227), const Color(0xffFFDF5B));
        
        if (!player2Created) {
          player2 = Player(
            playerId: 'YP',
            tokens: TokenManager().getYellowTokens(),
            isCurrentTurn: false,
            enableDice: false,
          );
          GameState().players.add(player2);
          player2Created = true;
        } else if (player2 != null) {
          // Add yellow tokens to existing player2
          player2.tokens.addAll(TokenManager().getYellowTokens());
        }
        
        for (var token in TokenManager().getYellowTokens()) {
          token.playerId = player2?.playerId ?? 'YP';
        }
      }
    }
    return Future.value();
  }
  
  void _initializeTokensForHouse(int homeSpotIndex, List<Token> tokens, Color sideColor, Color topColor) {
    const homeSpotSizeFactorX = 0.10;
    const homeSpotSizeFactorY = 0.05;
    const tokenSizeFactorX = 0.80;
    const tokenSizeFactorY = 1.05;
    
    for (var token in tokens) {
      final homeSpot = getHomeSpot(world, homeSpotIndex)
          .whereType<HomeSpot>()
          .firstWhere((spot) => spot.uniqueId == token.positionId);
      final spot = SpotManager().findSpotById(token.positionId);
      
      spot.position = Vector2(
        homeSpot.absolutePosition.x +
            (homeSpot.size.x * homeSpotSizeFactorX) -
            GameState().ludoBoardAbsolutePosition.x,
        homeSpot.absolutePosition.y -
            (homeSpot.size.x * homeSpotSizeFactorY) -
            GameState().ludoBoardAbsolutePosition.y,
      );
      
      token.sideColor = sideColor;
      token.topColor = topColor;
      token.position = spot.position;
      token.size = Vector2(
        homeSpot.size.x * tokenSizeFactorX,
        homeSpot.size.x * tokenSizeFactorY,
      );
      GameState().ludoBoard?.add(token);
    }
  }
  
  void _addDiceForPlayer(Player player, bool isLeftPosition) {
    final lowerController = world.children.whereType<LowerController>().first;
    final lowerControllerComponents = lowerController.children.toList();
    
    if (isLeftPosition) {
      // Left dice for Player 1 (BP/RP)
      final leftDice = lowerControllerComponents[0]
          .children
          .whereType<RectangleComponent>()
          .first;
      final leftDiceContainer = leftDice.children.whereType<RectangleComponent>().first;
      
      // Remove any existing dice first
      final existingDice = leftDiceContainer.children.whereType<LudoDice>().toList();
      for (var dice in existingDice) {
        leftDiceContainer.remove(dice);
      }
      
      leftDiceContainer.add(LudoDice(
        player: player,
        faceSize: leftDice.size.x * 0.70,
      ));
      lowerController.showPointer(player.playerId);
    } else {
      // Right dice for Player 2 (GP/YP)
      final rightDice = lowerControllerComponents[2]
          .children
          .whereType<RectangleComponent>()
          .first;
      final rightDiceContainer = rightDice.children.whereType<RectangleComponent>().first;
      
      // Remove any existing dice first
      final existingDice = rightDiceContainer.children.whereType<LudoDice>().toList();
      for (var dice in existingDice) {
        rightDiceContainer.remove(dice);
      }
      
      rightDiceContainer.add(LudoDice(
        player: player,
        faceSize: rightDice.size.x * 0.70,
      ));
      lowerController.showPointer(player.playerId);
    }
  }

  @override
  Color backgroundColor() => const Color.fromARGB(0, 0, 0, 0);

  RankModalComponent? _playerModal;

  void showPlayerModal() {
    _playerModal = RankModalComponent(
      players: GameState().players,
      position: Vector2(size.x * 0.05, size.y * 0.10),
      size: Vector2(size.x * 0.90, size.y * 0.90),
      context: context,
    );
    world.add(_playerModal!);
  }

  void hidePlayerModal() {
    _playerModal?.removeFromParent();
    _playerModal = null;
  }
}

List<Component> getHomeSpot(world, i) {
  final childrenOfLudoBoard = GameState().ludoBoard?.children.toList();
  final child = childrenOfLudoBoard![i];
  final home = child.children.toList();
  final homePlate = home[0].children.toList();
  final homeSpotContainer = homePlate[1].children.toList();
  final homeSpotList = homeSpotContainer[1].children.toList();
  return homeSpotList;
}

void moveOutOfBase({
  required World world,
  required Token token,
  required List<String> tokenPath,
}) async {
  // Update token position to the first position in the path
  token.positionId = tokenPath.first;
  token.state = TokenState.onBoard;

  await _applyEffect(
      token,
      MoveToEffect(SpotManager().findSpotById(tokenPath.first).tokenPosition,
          EffectController(duration: 0.1, curve: Curves.easeInOut)));

  tokenCollision(world, token);
}

void tokenCollision(World world, Token attackerToken) async {
  final tokensOnSpot = TokenManager()
      .allTokens
      .where((token) => token.positionId == attackerToken.positionId)
      .toList();

  // Initialize the flag to track if any token was attacked
  bool wasTokenAttacked = false;

  // only attacker token on spot, return
  if (tokensOnSpot.length > 1 &&
      !['B04', 'B23', 'R22', 'R10', 'G02', 'G21', 'Y30', 'Y42']
          .contains(attackerToken.positionId)) {
    // Batch token movements
    final tokensToMove = tokensOnSpot
        .where((token) => token.playerId != attackerToken.playerId)
        .toList();

    if (tokensToMove.isNotEmpty) {
      wasTokenAttacked = true;
    }

    // Wait for all movements to complete
    await Future.wait(tokensToMove.map((token) => moveBackward(
          world: world,
          token: token,
          tokenPath: GameState().getTokenPath(token.playerId),
          ludoBoard: GameState().ludoBoard as PositionComponent,
        )));
  }

  // Grant another turn or switch to next player
  final player = GameState()
      .players
      .firstWhere((player) => player.playerId == attackerToken.playerId);

  if (wasTokenAttacked) {
    if (player.hasRolledThreeConsecutiveSixes()) {
      player.resetExtraTurns();
    }
    player.grantAnotherTurn();
  } else {
    if (GameState().diceNumber != 6) {
      GameState().switchToNextPlayer();
    }
  }

  player.enableDice = true;

  if (GameState().diceNumber == 6 || wasTokenAttacked == true) {
    final lowerController = world.children.whereType<LowerController>().first;
    final upperController = world.children.whereType<UpperController>().first;
    lowerController.showPointer(player.playerId);
    upperController.showPointer(player.playerId);
  }

  for (var token in player.tokens) {
    token.enableToken = false;
  }

  // Call the function to resize tokens after moveBackward is complete
  resizeTokensOnSpot(world);
}

void resizeTokensOnSpot(World world) {
  final positionIncrements = {
    1: 0,
    2: 10,
    3: 5,
  };

  // Group tokens by position ID
  final Map<String, List<Token>> tokensByPositionId = {};
  for (var token in TokenManager().allTokens) {
    if (!tokensByPositionId.containsKey(token.positionId)) {
      tokensByPositionId[token.positionId] = [];
    }
    tokensByPositionId[token.positionId]!.add(token);
  }

  tokensByPositionId.forEach((positionId, tokenList) {
    // Precompute spot global position and adjusted position
    final spot = SpotManager().findSpotById(positionId);

    // Compute size factor and position increment
    final positionIncrement = positionIncrements[tokenList.length] ?? 5;

    // Resize and reposition tokens
    for (var i = 0; i < tokenList.length; i++) {
      final token = tokenList[i];
      if (token.state == TokenState.inBase) {
        token.position = spot.position;
      } else if (token.state == TokenState.onBoard ||
          token.state == TokenState.inHome) {
        token.position = Vector2(
            spot.tokenPosition.x + i * positionIncrement, spot.tokenPosition.y);
      }
    }
  });
}

void addTokenTrail(List<Token> tokensInBase, List<Token> tokensOnBoard) {
  var trailingTokens = [];

  for (var token in tokensOnBoard) {
    if (!token.spaceToMove()) {
      continue;
    }
    trailingTokens.add(token);
  }

  if (GameState().diceNumber == 6) {
    for (var token in tokensInBase) {
      trailingTokens.add(token);
    }
  }

  for (var token in trailingTokens) {
    token.enableCircleAnimation();
  }
}

Future<void> moveBackward({
  required World world,
  required Token token,
  required List<String> tokenPath,
  required PositionComponent ludoBoard,
}) async {
  final currentIndex = tokenPath.indexOf(token.positionId);
  const finalIndex = 0;

  // Preload audio to avoid delays during playback
  bool audioPlayed = false;

  for (int i = currentIndex; i >= finalIndex; i--) {
    token.positionId = tokenPath[i];

    if (!audioPlayed) {
      SoundManager().playMove();
      audioPlayed = true;
    }

    await _applyEffect(
      token,
      MoveToEffect(
        SpotManager()
            .getSpots()
            .firstWhere((spot) => spot.uniqueId == token.positionId)
            .tokenPosition,
        EffectController(duration: 0.1, curve: Curves.easeInOut),
      ),
    );
  }

  if (token.playerId == 'BP') {
    await moveTokenToBase(
      world: world,
      token: token,
      tokenBase: TokenManager().blueTokensBase,
      homeSpotIndex: 6,
      ludoBoard: ludoBoard,
    );
  } else if (token.playerId == 'GP') {
    await moveTokenToBase(
      world: world,
      token: token,
      tokenBase: TokenManager().greenTokensBase,
      homeSpotIndex: 2,
      ludoBoard: ludoBoard,
    );
  } else if (token.playerId == 'RP') {
    await moveTokenToBase(
      world: world,
      token: token,
      tokenBase: TokenManager().redTokensBase,
      homeSpotIndex: 0,
      ludoBoard: ludoBoard,
    );
  } else if (token.playerId == 'YP') {
    await moveTokenToBase(
      world: world,
      token: token,
      tokenBase: TokenManager().yellowTokensBase,
      homeSpotIndex: 8,
      ludoBoard: ludoBoard,
    );
  }
}

Future<void> moveForward({
  required World world,
  required Token token,
  required List<String> tokenPath,
  required int diceNumber,
}) async {
  // get all spots
  final currentIndex = tokenPath.indexOf(token.positionId);
  final finalIndex = currentIndex + diceNumber;

  for (int i = currentIndex + 1; i <= finalIndex && i < tokenPath.length; i++) {
    token.positionId = tokenPath[i];
    await _applyEffect(
      token,
      MoveToEffect(
        SpotManager()
            .getSpots()
            .firstWhere((spot) => spot.uniqueId == token.positionId)
            .tokenPosition,
        EffectController(duration: 0.12, curve: Curves.easeInOut),
      ),
    );

    // Add a small delay to reduce CPU strain and smooth the animation
    Future.delayed(const Duration(milliseconds: 120));
  }

  // if token is in home
  bool isTokenInHome = await checkTokenInHomeAndHandle(token, world);

  if (isTokenInHome) {
    resizeTokensOnSpot(world);
  } else {
    tokenCollision(world, token);
  }
  clearTokenTrail();
  
}

void clearTokenTrail() {
  final tokens = TokenManager().allTokens;
  for (var token in tokens) {
    token.disableCircleAnimation();
  }
}

Future<void> _applyEffect(PositionComponent component, Effect effect) {
  final completer = Completer<void>();
  effect.onComplete = completer.complete;
  component.add(effect);
  return completer.future;
}

Future<void> moveTokenToBase({
  required World world,
  required Token token,
  required Map<String, String> tokenBase,
  required int homeSpotIndex,
  required PositionComponent ludoBoard,
}) async {
  for (var entry in tokenBase.entries) {
    var tokenId = entry.key;
    var homePosition = entry.value;
    if (token.tokenId == tokenId) {
      token.positionId = homePosition;
      token.state = TokenState.inBase;
    }
  }

  await _applyEffect(
    token,
    MoveToEffect(
      SpotManager().findSpotById(token.positionId).position,
      EffectController(duration: 0.03, curve: Curves.easeInOut),
    ),
  );
  Future.delayed(const Duration(milliseconds: 30));
}

Future<bool> checkTokenInHomeAndHandle(Token token, World world) async {
  // Define home position IDs
  const homePositions = ['BF', 'GF', 'YF', 'RF'];

  // Check if the token is in home
  if (!homePositions.contains(token.positionId)) return false;

  token.state = TokenState.inHome;

  // Cache players from GameState
  // final players = GameState().players;
  final player =
      GameState().players.firstWhere((p) => p.playerId == token.playerId);
  player.updateTokensInHomeCount();

  // Handle win condition
  if (player.totalTokensInHome == 4) {
    player.hasWon = true;

    // Get winners and non-winners
    final playersWhoWon = GameState().players.where((p) => p.hasWon).toList();
    final playersWhoNotWon =
        GameState().players.where((p) => !p.hasWon).toList();

    // End game condition
    if (playersWhoWon.length == GameState().players.length - 1) {
      playersWhoNotWon.first.rank =
          GameState().players.length; // Rank last player
      player.rank = playersWhoWon.length; // Set rank for current player
      // Disable dice for all players
      for (var p in GameState().players) {
        p.enableDice = false;
      }
      for (var t in TokenManager().allTokens) {
        t.enableToken = false;
      }
      EventBus().emit(OpenPlayerModalEvent());
    } else {
      // Set rank for current player
      player.rank = playersWhoWon.length;
    }
    return true;
  }

  // Grant another turn if not all tokens are home

  player.enableDice = true;
  final lowerController = world.children.whereType<LowerController>().first;
  lowerController.showPointer(player.playerId);
  final upperController = world.children.whereType<UpperController>().first;
  upperController.showPointer(player.playerId);

  // Disable tokens for current player
  for (var t in player.tokens) {
    t.enableToken = false;
  }

  // Reset extra turns if applicable
  if (player.hasRolledThreeConsecutiveSixes()) {
    await player.resetExtraTurns();
  }

  player.grantAnotherTurn();
  return true;
}