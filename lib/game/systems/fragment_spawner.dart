import 'dart:math';
import 'package:flame/components.dart';
import '../afterimage_game.dart';
import '../components/energy_fragment.dart';
import '../game_config.dart';

/// Spawns and manages energy fragments in the arena.
class FragmentSpawner extends Component with HasGameReference<AfterimageGame> {
  final Random _rng = Random();
  double _respawnTimer = 0.0;
  bool _active = false;

  void activate() => _active = true;
  void deactivate() => _active = false;

  @override
  void update(double dt) {
    super.update(dt);
    if (!_active) return;

    final activeFragments = game.fragments.where((f) => !f.isCollected).length;
    if (activeFragments < GameConfig.maxFragments) {
      _respawnTimer += dt;
      if (_respawnTimer >= GameConfig.fragmentRespawnDelay) {
        _respawnTimer = 0.0;
        _spawnFragment();
      }
    }
  }

  void spawnInitialFragments() {
    for (int i = 0; i < GameConfig.initialFragmentCount; i++) {
      _spawnFragment();
    }
  }

  void _spawnFragment() {
    final arena = game.arena;
    final player = game.player;
    if (arena == null) return;

    final fragment = EnergyFragment();
    final avoidPos = player?.position ?? Vector2.zero();
    fragment.position = arena.randomPositionAwayFrom(
      _rng,
      avoidPos,
      50,
      margin: 25,
    );

    game.addFragment(fragment);
  }

  void reset() {
    _respawnTimer = 0.0;
    _active = false;
  }
}
