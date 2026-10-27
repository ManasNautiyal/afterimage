/// Audio service for AFTERIMAGE.
/// Gracefully handles missing audio assets.
class AudioService {
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _initialized = false;

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;

  /// Initialize audio. Currently uses no external assets.
  Future<void> init({
    bool soundEnabled = true,
    bool musicEnabled = true,
  }) async {
    _soundEnabled = soundEnabled;
    _musicEnabled = musicEnabled;
    _initialized = true;
  }

  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  void setMusicEnabled(bool enabled) {
    _musicEnabled = enabled;
    if (!enabled) {
      stopMusic();
    }
  }

  /// Play a sound effect by name. No-op if sound disabled or assets missing.
  void playSfx(String name) {
    if (!_soundEnabled || !_initialized) return;
    // Audio playback would go here with flame_audio or audioplayers
    // For now, gracefully no-op since we use procedural rendering
  }

  void playCollect() => playSfx('collect');
  void playExplosion() => playSfx('explosion');
  void playButtonTap() => playSfx('button_tap');
  void playNewRecord() => playSfx('new_record');

  void playMusic() {
    if (!_musicEnabled || !_initialized) return;
    // Music playback would go here
  }

  void stopMusic() {
    // Stop music playback
  }

  void dispose() {
    stopMusic();
    _initialized = false;
  }
}
