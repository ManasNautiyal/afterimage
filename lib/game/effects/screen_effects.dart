import 'dart:ui' as ui;
import 'package:flame/components.dart';
import '../afterimage_game.dart';

/// Screen-level visual effects (flash on death, etc.).
class ScreenEffects extends Component with HasGameReference<AfterimageGame> {
  double _flashAlpha = 0.0;
  ui.Color _flashColor = const ui.Color(0xFFFF1744);

  void flash(ui.Color color, {double intensity = 0.6}) {
    _flashColor = color;
    _flashAlpha = intensity;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_flashAlpha > 0) {
      _flashAlpha -= dt * 3;
      if (_flashAlpha < 0) _flashAlpha = 0;
    }
  }

  @override
  void render(ui.Canvas canvas) {
    if (_flashAlpha > 0) {
      canvas.drawRect(
        ui.Rect.fromLTWH(0, 0, game.size.x, game.size.y),
        ui.Paint()..color = _flashColor.withAlpha((_flashAlpha * 255).toInt()),
      );
    }
  }
}
