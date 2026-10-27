import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/afterimage_app.dart';
import 'services/storage_service.dart';
import 'services/audio_service.dart';
import 'services/ads_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0A1A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize services
  final storageService = StorageService();
  await storageService.init();

  final audioService = AudioService();
  await audioService.init(
    soundEnabled: storageService.getSoundEnabled(),
    musicEnabled: storageService.getMusicEnabled(),
  );

  final adsService = AdsService();
  // Initialize ads in background - don't block app start
  adsService.init(interstitialFrequency: 3);

  runApp(
    AfterimageApp(
      storageService: storageService,
      audioService: audioService,
      adsService: adsService,
    ),
  );
}
