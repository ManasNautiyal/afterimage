import 'package:flutter/material.dart';
import '../app/app_theme.dart';
import '../app/app_constants.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../widgets/currency_display.dart';

/// Skins selection screen with preview, purchase, and equip.
class SkinsScreen extends StatefulWidget {
  final StorageService storageService;
  final AudioService audioService;
  final VoidCallback onBack;

  const SkinsScreen({
    super.key,
    required this.storageService,
    required this.audioService,
    required this.onBack,
  });

  @override
  State<SkinsScreen> createState() => _SkinsScreenState();
}

class _SkinsScreenState extends State<SkinsScreen> {
  late Set<int> _ownedSkins;
  late int _selectedSkin;
  late int _currency;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _ownedSkins = widget.storageService.getOwnedSkins();
    _selectedSkin = widget.storageService.getSelectedSkin();
    _currency = widget.storageService.getTotalCurrency();
  }

  Future<void> _buySkin(int index) async {
    final price = AppConstants.skinPrices[index];
    if (_currency < price) {
      _showMessage('Not enough energy!');
      return;
    }
    final success = await widget.storageService.unlockSkin(index, price);
    if (success) {
      widget.audioService.playCollect();
      setState(() => _loadData());
    } else {
      _showMessage('Purchase failed');
    }
  }

  Future<void> _selectSkin(int index) async {
    if (!_ownedSkins.contains(index)) return;
    final success = await widget.storageService.setSelectedSkin(index);
    if (success) {
      widget.audioService.playButtonTap();
      setState(() => _selectedSkin = index);
    }
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.surface,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'SKINS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                  CurrencyDisplay(amount: _currency),
                ],
              ),
            ),
            // Skin list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                itemCount: AppTheme.skinColors.length,
                itemBuilder: (context, index) {
                  final color = AppTheme.skinColors[index];
                  final name = AppTheme.skinNames[index];
                  final price =
                      index < AppConstants.skinPrices.length
                          ? AppConstants.skinPrices[index]
                          : 999;
                  final owned = _ownedSkins.contains(index);
                  final selected = _selectedSkin == index;
                  final canAfford = _currency >= price;

                  return _SkinCard(
                    color: color,
                    name: name,
                    price: price,
                    owned: owned,
                    selected: selected,
                    canAfford: canAfford,
                    onTap: () {
                      if (owned) {
                        _selectSkin(index);
                      } else {
                        _buySkin(index);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkinCard extends StatelessWidget {
  final Color color;
  final String name;
  final int price;
  final bool owned;
  final bool selected;
  final bool canAfford;
  final VoidCallback onTap;

  const _SkinCard({
    required this.color,
    required this.name,
    required this.price,
    required this.owned,
    required this.selected,
    required this.canAfford,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected ? color.withAlpha(20) : AppTheme.surface,
          border: Border.all(
            color: selected ? color.withAlpha(150) : AppTheme.surfaceLight,
            width: selected ? 2 : 1,
          ),
          boxShadow:
              selected
                  ? [
                    BoxShadow(
                      color: color.withAlpha(30),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                  : null,
        ),
        child: Row(
          children: [
            // Preview circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color.lerp(color, Colors.white, 0.3)!,
                    color,
                    color.withAlpha(180),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withAlpha(60),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: owned ? color : AppTheme.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (selected)
                    const Text(
                      'EQUIPPED',
                      style: TextStyle(
                        color: AppTheme.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                ],
              ),
            ),
            // Action
            if (owned && !selected)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withAlpha(80)),
                ),
                child: Text(
                  'EQUIP',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else if (!owned)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color:
                      canAfford
                          ? AppTheme.fragmentGold.withAlpha(20)
                          : Colors.transparent,
                  border: Border.all(
                    color:
                        canAfford
                            ? AppTheme.fragmentGold.withAlpha(80)
                            : AppTheme.textMuted.withAlpha(40),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bolt,
                      color:
                          canAfford
                              ? AppTheme.fragmentGold
                              : AppTheme.textMuted,
                      size: 14,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '$price',
                      style: TextStyle(
                        color:
                            canAfford
                                ? AppTheme.fragmentGold
                                : AppTheme.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
