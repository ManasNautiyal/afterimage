import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:afterimage/app/afterimage_app.dart';
import 'package:afterimage/services/storage_service.dart';
import 'package:afterimage/services/audio_service.dart';
import 'package:afterimage/services/ads_service.dart';

void main() {
  late StorageService storageService;
  late AudioService audioService;
  late AdsService adsService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storageService = StorageService();
    await storageService.init();
    audioService = AudioService();
    await audioService.init();
    adsService = AdsService();
    // Note: We don't call adsService.init() in tests to avoid MobileAds SDK
  });

  testWidgets('Main menu displays title and play button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      AfterimageApp(
        storageService: storageService,
        audioService: audioService,
        adsService: adsService,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('AFTERIMAGE'), findsOneWidget);
    expect(find.text('PLAY'), findsOneWidget);
    expect(find.text('SKINS'), findsOneWidget);
  });

  testWidgets('Sound toggle works', (WidgetTester tester) async {
    await tester.pumpWidget(
      AfterimageApp(
        storageService: storageService,
        audioService: audioService,
        adsService: adsService,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Find volume icon
    final volumeIcon = find.byIcon(Icons.volume_up);
    expect(volumeIcon, findsOneWidget);

    // Tap to toggle
    await tester.tap(volumeIcon);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Should now show volume_off
    expect(find.byIcon(Icons.volume_off), findsOneWidget);
    expect(storageService.getSoundEnabled(), false);
  });

  testWidgets('Navigate to skins screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      AfterimageApp(
        storageService: storageService,
        audioService: audioService,
        adsService: adsService,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('SKINS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('SKINS').first, findsOneWidget);
    expect(find.text('Neon Cyan'), findsOneWidget); // Default skin
  });

  testWidgets('Navigate to settings screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      AfterimageApp(
        storageService: storageService,
        audioService: audioService,
        adsService: adsService,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('SETTINGS'), findsOneWidget);
    expect(find.text('Sound Effects'), findsOneWidget);
    expect(find.text('Music'), findsOneWidget);
  });
}
