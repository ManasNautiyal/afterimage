import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../app/app_theme.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../models/run_result.dart';
import 'game_config.dart';
import 'game_state.dart';
import 'components/arena_component.dart';
import 'components/player_component.dart';
import 'components/ghost_component.dart';
import 'components/energy_fragment.dart';
import 'components/hazard_component.dart';
import 'components/particle_component.dart';
import 'systems/movement_system.dart';
import 'systems/ghost_replay_system.dart';
import 'systems/hazard_spawner.dart';
import 'systems/fragment_spawner.dart';
import 'systems/collision_system.dart';
import 'systems/difficulty_system.dart';
import 'systems/scoring_system.dart';

/// Main Flame game class for AFTERIMAGE.
class AfterimageGame extends FlameGame
    with HasCollisionDetection, KeyboardEvents {
  final StorageService storageService;
  final AudioService audioService;
  final int skinIndex;

  // Callbacks to Flutter UI
  final VoidCallback? onGameOverCallback;
  final void Function(GameState state)? onStateChanged;

  GameState _state = GameState.initializing;
  GameState get state => _state;

  // Core components
  ArenaComponent? arena;
  PlayerComponent? player;
  final List<GhostComponent> ghosts = [];
  final List<EnergyFragment> fragments = [];
  final List<HazardComponent> hazards = [];

  // Systems
  final MovementSystem movementSystem = MovementSystem();
  final GhostReplaySystem ghostReplaySystem = GhostReplaySystem();
  final HazardSpawner hazardSpawner = HazardSpawner();
  final FragmentSpawner fragmentSpawner = FragmentSpawner();
  final CollisionSystem collisionSystem = CollisionSystem();
  final DifficultySystem difficultySystem = DifficultySystem();
  final ScoringSystem scoringSystem = ScoringSystem();
  late ParticleSystem particleSystem;

  // Session data
  double _gameTime = 0.0;
  bool _reviveUsed = false;
  final Random _rng = Random();

  // Multi-version ghost tracking
  int _totalGhostsSpawned = 0;
  double get gameTime => _gameTime;

  // Keyboard input tracking
  final Set<LogicalKeyboardKey> _pressedKeys = {};

  // Background particles
  final List<_BackgroundParticle> _bgParticles = [];

  int _lastSavedCurrency = 0;
  bool _runIncremented = false;
  bool _usingKeyboard = false;
  bool _initialEntitiesSpawned = false;

  AfterimageGame({
    required this.storageService,
    required this.audioService,
    this.skinIndex = 0,
    this.onGameOverCallback,
    this.onStateChanged,
  });

  @override
  ui.Color backgroundColor() => const ui.Color(0xFF0A0A1A);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    particleSystem = ParticleSystem();
    add(particleSystem);

    // Systems are added once and persist across runs
    add(movementSystem);
    add(hazardSpawner);
    add(fragmentSpawner);
    add(collisionSystem);

    // Initialize background particles
    final initX = size.x > 0 ? size.x : 400.0;
    final initY = size.y > 0 ? size.y : 800.0;
    for (int i = 0; i < 30; i++) {
      _bgParticles.add(
        _BackgroundParticle(
          position: Vector2(
            _rng.nextDouble() * initX,
            _rng.nextDouble() * initY,
          ),
          speed: 5 + _rng.nextDouble() * 15,
          radius: 0.5 + _rng.nextDouble() * 1.5,
          alpha: 20 + _rng.nextInt(40),
        ),
      );
    }

    _setState(GameState.playing);
    startNewRun();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (arena != null) {
      arena!.updateBounds();
      if (!_initialEntitiesSpawned && arena!.arenaBounds.width > 50) {
        _spawnInitialEntities();
      }
    }
  }

  void _setState(GameState newState) {
    _state = newState;
    onStateChanged?.call(newState);
  }

  // --- Run lifecycle ---

  void startNewRun() {
    _cleanupRun();
    _setState(GameState.playing);

    // Create arena
    arena = ArenaComponent();
    add(arena!);

    // Create player
    final skinColor =
        skinIndex < AppTheme.skinColors.length
            ? AppTheme.skinColors[skinIndex]
            : AppTheme.playerCyan;
    player = PlayerComponent(color: skinColor);
    add(player!);

    // Center player in arena immediately
    player!.position = Vector2(
      arena!.arenaBounds.center.dx,
      arena!.arenaBounds.center.dy,
    );

    // Reset all systems
    ghostReplaySystem.reset();
    difficultySystem.reset();
    scoringSystem.reset();
    collisionSystem.reset();
    movementSystem.reset();
    hazardSpawner.reset();
    fragmentSpawner.reset();

    _gameTime = 0.0;
    _reviveUsed = false;
    _totalGhostsSpawned = 0;
    _lastSavedCurrency = 0;
    _runIncremented = false;
    _usingKeyboard = false;
    _initialEntitiesSpawned = false;

    // Spawn initial entities immediately if bounds are ready
    if (arena!.arenaBounds.width > 50) {
      _spawnInitialEntities();
    }
  }

  void _spawnInitialEntities() {
    if (_initialEntitiesSpawned || arena == null || player == null) return;
    _initialEntitiesSpawned = true;
    _spawnInitialHazards();
    fragmentSpawner.spawnInitialFragments();
    hazardSpawner.activate();
    fragmentSpawner.activate();
  }

  void _spawnInitialHazards() {
    if (arena == null || player == null) return;
    for (int i = 0; i < GameConfig.initialMineCount; i++) {
      final hazard = HazardComponent(type: HazardType.mine);
      hazard.position = arena!.randomPositionAwayFrom(
        _rng,
        player!.position,
        GameConfig.minSpawnDistanceFromPlayer,
      );
      addHazard(hazard);
    }
  }

  void _cleanupRun() {
    for (final ghost in [...ghosts]) {
      ghost.removeFromParent();
    }
    ghosts.clear();

    for (final fragment in [...fragments]) {
      fragment.removeFromParent();
    }
    fragments.clear();

    for (final hazard in [...hazards]) {
      hazard.removeFromParent();
    }
    hazards.clear();

    if (player != null) {
      player!.removeFromParent();
      player = null;
    }
    if (arena != null) {
      arena!.removeFromParent();
      arena = null;
    }

    particleSystem.clear();
  }

  // --- Entity management ---

  void addHazard(HazardComponent hazard) {
    hazards.add(hazard);
    add(hazard);
  }

  void addFragment(EnergyFragment fragment) {
    fragments.add(fragment);
    add(fragment);
  }

  // --- Game loop ---

  @override
  void update(double dt) {
    if (_state != GameState.playing) {
      _updateBackgroundParticles(dt);
      return;
    }

    _gameTime += dt;
    difficultySystem.update(dt);
    scoringSystem.update(dt);

    _handleKeyboardInput();
    movementSystem.applyMovement(dt);

    if (player != null) {
      ghostReplaySystem.recordPosition(_gameTime, player!.position);
    }

    _updateGhosts(dt);
    collisionSystem.checkCollisions();

    super.update(dt);
    _updateBackgroundParticles(dt);
  }

  void _updateGhosts(double dt) {
    if (_gameTime < GameConfig.firstGhostDelay) return;

    final targetConcurrent = difficultySystem.targetGhostCount;

    // 1. Maintain active cohort of multiple self-chasing versions
    while (ghosts.length < targetConcurrent) {
      final occupiedIndices = ghosts.map((g) => g.chainIndex).toSet();
      int nextChainIndex = 0;
      while (occupiedIndices.contains(nextChainIndex)) {
        nextChainIndex++;
      }

      final delay = difficultySystem.getGhostDelayForIndex(nextChainIndex);
      if (!ghostReplaySystem.hasHistoryForDelay(_gameTime, delay)) {
        break; // Not enough player history recorded yet for this ghost's delay
      }

      final spawned = _spawnChasingVersion(nextChainIndex, delay);
      if (!spawned) {
        break; // Position could not be sampled this frame, retry next frame
      }
    }

    // 2. Advance active time, replay path, and detect expired ghosts
    final toRemove = <GhostComponent>[];

    for (int i = 0; i < ghosts.length; i++) {
      final ghost = ghosts[i];
      if (!ghost.isActive) continue;

      ghost.advanceTime(dt);

      if (ghost.isExpired) {
        toRemove.add(ghost);
        continue;
      }

      final targetTime = ghost.targetHistoryTime;
      final pos = ghostReplaySystem.getPositionAtTime(targetTime);

      if (pos != null) {
        ghost.updateGhostPosition(pos);
      }
    }

    // 3. Remove old ghosts cleanly with dissolution particles
    for (final ghost in toRemove) {
      particleSystem.spawnBurst(
        ghost.position,
        ghost.color.withAlpha(160),
        count: 10,
      );
      ghost.removeFromParent();
      ghosts.remove(ghost);
    }
  }

  bool _spawnChasingVersion(int chainIndex, double delay) {
    // Initial position sampled from historical path at target time
    final targetTime = _gameTime - delay;
    final pos = ghostReplaySystem.getPositionAtTime(targetTime);
    if (pos == null) return false;

    final colorIdx = _totalGhostsSpawned % AppTheme.ghostColors.length;
    final ghost = GhostComponent(
      ghostIndex: _totalGhostsSpawned,
      chainIndex: chainIndex,
      color: AppTheme.ghostColors[colorIdx],
      delay: delay,
      intervalDuration: difficultySystem.ghostDuration,
      spawnGameTime: _gameTime,
    );

    ghost.updateGhostPosition(pos);
    particleSystem.spawnBurst(
      pos,
      AppTheme.ghostColors[colorIdx].withAlpha(180),
      count: 8,
    );

    _totalGhostsSpawned++;
    ghosts.add(ghost);
    add(ghost);
    return true;
  }

  // --- Input handling ---

  void onJoystickMove(Vector2 direction) {
    if (_state != GameState.playing) return;
    _usingKeyboard = false;
    movementSystem.setDirection(direction);
  }

  void _handleKeyboardInput() {
    final dir = Vector2.zero();
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowUp) ||
        _pressedKeys.contains(LogicalKeyboardKey.keyW)) {
      dir.y -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowDown) ||
        _pressedKeys.contains(LogicalKeyboardKey.keyS)) {
      dir.y += 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowLeft) ||
        _pressedKeys.contains(LogicalKeyboardKey.keyA)) {
      dir.x -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowRight) ||
        _pressedKeys.contains(LogicalKeyboardKey.keyD)) {
      dir.x += 1;
    }
    if (dir.length2 > 0) {
      _usingKeyboard = true;
      movementSystem.setDirection(dir.normalized());
    } else if (_usingKeyboard) {
      _usingKeyboard = false;
      movementSystem.setDirection(Vector2.zero());
    }
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    _pressedKeys.clear();
    _pressedKeys.addAll(keysPressed);
    return KeyEventResult.handled;
  }

  // --- Game state transitions ---

  void onGameOver() {
    if (_state == GameState.gameOver) return;
    _setState(GameState.gameOver);
    scoringSystem.freeze();
    hazardSpawner.deactivate();
    fragmentSpawner.deactivate();
    movementSystem.reset();

    onGameOverCallback?.call();
  }

  void pauseGame() {
    if (_state != GameState.playing) return;
    _setState(GameState.paused);
    scoringSystem.freeze();
    hazardSpawner.deactivate();
    fragmentSpawner.deactivate();
  }

  void resumeGame() {
    if (_state != GameState.paused) return;
    _setState(GameState.playing);
    scoringSystem.unfreeze();
    hazardSpawner.activate();
    fragmentSpawner.activate();
  }

  RunResult getRunResult() {
    final score = scoringSystem.score;
    final duration = scoringSystem.survivalTime;
    final frags = scoringSystem.fragmentsCollected;
    final currency = scoringSystem.currencyEarned;
    final bestScore = storageService.getBestScore();
    final bestDuration = storageService.getBestDuration();

    return RunResult(
      score: score,
      survivalTime: duration,
      fragmentsCollected: frags,
      ghostsSpawned: _totalGhostsSpawned,
      currencyEarned: currency,
      isNewBestScore: score > bestScore,
      isNewBestDuration: duration > bestDuration,
    );
  }

  Future<void> saveRunResults() async {
    final result = getRunResult();
    final newCurrency = result.currencyEarned - _lastSavedCurrency;
    if (newCurrency > 0) {
      await storageService.addCurrency(newCurrency);
      _lastSavedCurrency = result.currencyEarned;
    }
    if (!_runIncremented) {
      await storageService.incrementCompletedRuns();
      _runIncremented = true;
    }
    if (result.score > storageService.getBestScore()) {
      await storageService.setBestScore(result.score);
    }
    if (result.survivalTime > storageService.getBestDuration()) {
      await storageService.setBestDuration(result.survivalTime);
    }
  }

  void revivePlayer() {
    if (_reviveUsed || _state != GameState.gameOver) return;
    _reviveUsed = true;

    _setState(GameState.playing);
    scoringSystem.unfreeze();
    collisionSystem.reset();

    player?.setInvulnerable(GameConfig.reviveInvulnerabilityDuration);
    player?.resetTrail();

    final playerPos = player?.position;
    if (playerPos != null) {
      final toRemove =
          hazards.where((h) => h.position.distanceTo(playerPos) < 80).toList();
      for (final h in toRemove) {
        h.removeFromParent();
        hazards.remove(h);
      }
    }

    for (final ghost in ghosts) {
      ghost.resetTrail();
      ghost.isInNearMissZone = false;
    }

    hazardSpawner.activate();
    fragmentSpawner.activate();
  }

  bool get canRevive => !_reviveUsed && _state == GameState.gameOver;

  // --- Background particles ---

  void _updateBackgroundParticles(double dt) {
    for (final p in _bgParticles) {
      p.position.y -= p.speed * dt;
      if (p.position.y < -5) {
        p.position.y = size.y + 5;
        p.position.x = _rng.nextDouble() * size.x;
      }
    }
  }

  @override
  void render(ui.Canvas canvas) {
    for (final p in _bgParticles) {
      canvas.drawCircle(
        ui.Offset(p.position.x, p.position.y),
        p.radius,
        ui.Paint()..color = ui.Color.fromARGB(p.alpha, 0, 229, 255),
      );
    }
    super.render(canvas);
  }
}

class _BackgroundParticle {
  Vector2 position;
  double speed;
  double radius;
  int alpha;

  _BackgroundParticle({
    required this.position,
    required this.speed,
    required this.radius,
    required this.alpha,
  });
}
