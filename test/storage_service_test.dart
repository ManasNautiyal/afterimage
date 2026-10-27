import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:afterimage/services/storage_service.dart';

void main() {
  late StorageService storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = StorageService();
    await storage.init();
  });

  group('Best Score', () {
    test('returns 0 by default', () {
      expect(storage.getBestScore(), 0);
    });

    test('persists a best score', () async {
      await storage.setBestScore(500);
      expect(storage.getBestScore(), 500);
    });

    test('clamps negative scores to 0', () async {
      await storage.setBestScore(-10);
      expect(storage.getBestScore(), 0);
    });
  });

  group('Best Duration', () {
    test('returns 0.0 by default', () {
      expect(storage.getBestDuration(), 0.0);
    });

    test('persists a best duration', () async {
      await storage.setBestDuration(42.5);
      expect(storage.getBestDuration(), 42.5);
    });
  });

  group('Currency', () {
    test('returns 0 by default', () {
      expect(storage.getTotalCurrency(), 0);
    });

    test('adds currency correctly', () async {
      await storage.addCurrency(100);
      expect(storage.getTotalCurrency(), 100);
      await storage.addCurrency(50);
      expect(storage.getTotalCurrency(), 150);
    });

    test('deducts currency correctly', () async {
      await storage.setTotalCurrency(200);
      final result = await storage.deductCurrency(75);
      expect(result, true);
      expect(storage.getTotalCurrency(), 125);
    });

    test('rejects deduction when insufficient balance', () async {
      await storage.setTotalCurrency(30);
      final result = await storage.deductCurrency(50);
      expect(result, false);
      expect(storage.getTotalCurrency(), 30);
    });

    test('clamps negative currency to 0', () async {
      await storage.setTotalCurrency(-5);
      expect(storage.getTotalCurrency(), 0);
    });
  });

  group('Skins', () {
    test('default skin 0 is always owned', () {
      final skins = storage.getOwnedSkins();
      expect(skins.contains(0), true);
    });

    test('selected skin defaults to 0', () {
      expect(storage.getSelectedSkin(), 0);
    });

    test('unlocking a skin deducts currency', () async {
      await storage.setTotalCurrency(200);
      final result = await storage.unlockSkin(1, 100);
      expect(result, true);
      expect(storage.getTotalCurrency(), 100);
      expect(storage.getOwnedSkins().contains(1), true);
    });

    test('cannot unlock skin with insufficient currency', () async {
      await storage.setTotalCurrency(30);
      final result = await storage.unlockSkin(2, 100);
      expect(result, false);
      expect(storage.getOwnedSkins().contains(2), false);
    });

    test('selecting an owned skin works', () async {
      await storage.setTotalCurrency(200);
      await storage.unlockSkin(1, 50);
      final result = await storage.setSelectedSkin(1);
      expect(result, true);
      expect(storage.getSelectedSkin(), 1);
    });

    test('cannot select an unowned skin', () async {
      final result = await storage.setSelectedSkin(3);
      expect(result, false);
      expect(storage.getSelectedSkin(), 0);
    });

    test('unlocking an already owned skin does not deduct currency', () async {
      await storage.setTotalCurrency(200);
      await storage.unlockSkin(1, 50);
      expect(storage.getTotalCurrency(), 150);
      await storage.unlockSkin(1, 50); // Already owned
      expect(storage.getTotalCurrency(), 150); // No deduction
    });
  });

  group('Sound', () {
    test('sound is enabled by default', () {
      expect(storage.getSoundEnabled(), true);
    });

    test('sound can be toggled', () async {
      await storage.setSoundEnabled(false);
      expect(storage.getSoundEnabled(), false);
      await storage.setSoundEnabled(true);
      expect(storage.getSoundEnabled(), true);
    });
  });

  group('Run Counter', () {
    test('starts at 0', () {
      expect(storage.getCompletedRuns(), 0);
    });

    test('increments correctly', () async {
      await storage.incrementCompletedRuns();
      await storage.incrementCompletedRuns();
      expect(storage.getCompletedRuns(), 2);
    });
  });

  group('saveRunResult', () {
    test('updates best score, duration, and currency', () async {
      final stats = await storage.saveRunResult(
        score: 1000,
        duration: 60.0,
        currencyEarned: 25,
      );
      expect(stats.bestScore, 1000);
      expect(stats.bestDuration, 60.0);
      expect(stats.totalCurrency, 25);
    });

    test('does not downgrade best score', () async {
      await storage.saveRunResult(
        score: 1000,
        duration: 60.0,
        currencyEarned: 10,
      );
      await storage.saveRunResult(
        score: 500,
        duration: 30.0,
        currencyEarned: 5,
      );
      expect(storage.getBestScore(), 1000);
      expect(storage.getBestDuration(), 60.0);
      expect(storage.getTotalCurrency(), 15); // Cumulative
    });
  });
}
