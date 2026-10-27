import 'package:flame/components.dart';
import '../afterimage_game.dart';
import '../game_config.dart';

/// Handles player movement from joystick input and keyboard.
class MovementSystem extends Component with HasGameReference<AfterimageGame> {
  Vector2 _inputDirection = Vector2.zero();

  void setDirection(Vector2 direction) {
    _inputDirection = direction;
  }

  void applyMovement(double dt) {
    final player = game.player;
    final arena = game.arena;
    if (player == null || arena == null) return;

    if (_inputDirection.length2 >
        GameConfig.joystickDeadZone * GameConfig.joystickDeadZone) {
      final moveVector =
          _inputDirection.normalized() * GameConfig.playerSpeed * dt;
      final newPos = player.position + moveVector;
      player.position = arena.clampToArena(newPos, GameConfig.playerRadius);
    }
  }

  void reset() {
    _inputDirection = Vector2.zero();
  }
}
