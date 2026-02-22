import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/constants/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/glass_panel.dart';
import '../../../shared/widgets/app_button.dart';
import '../providers/pharmacy_provider.dart';

class PharmacyScreen extends ConsumerStatefulWidget {
  const PharmacyScreen({super.key});

  @override
  ConsumerState<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends ConsumerState<PharmacyScreen> {
  final List<Map<String, dynamic>> _medicines = [];
  bool _isLoading = true;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  Future<void> _loadMedicines() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get(
        ApiConstants.pharmaInventoryEndpoint,
      );
      final data = response.data;
      if (data is List) {
        setState(() {
          _medicines.addAll(data.cast<Map<String, dynamic>>());
        });
      }
    } catch (e) {
      AppLogger.error('PHARMACY', 'Failed to load medicines', e);
      // Fallback data
      setState(() {
        _medicines.addAll([
          {
            'id': 1,
            'name': 'Paracetamol 500mg',
            'description': 'Pain reliever and fever reducer.',
            'price': 5.99,
            'stock': 100,
            'requiresPrescription': false,
          },
          {
            'id': 2,
            'name': 'Amoxicillin 250mg',
            'description': 'Antibiotic used to treat bacterial infections.',
            'price': 12.50,
            'stock': 50,
            'requiresPrescription': true,
          },
          {
            'id': 3,
            'name': 'Vitamin C Supplement',
            'description': 'Immune system support.',
            'price': 8.99,
            'stock': 200,
            'requiresPrescription': false,
          },
        ]);
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('pharmacyStore')),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.shoppingCart),
                onPressed: () => context.push('/dashboard/pharmacy-cart'),
              ),
              if (cart.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${cart.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _TabButton(
                  label: loc.translate('medicines'),
                  selected: _selectedTab == 0,
                  onTap: () => setState(() => _selectedTab = 0),
                ),
                const SizedBox(width: 12),
                _TabButton(
                  label: loc.translate('orders'),
                  selected: _selectedTab == 1,
                  onTap: () => setState(() => _selectedTab = 1),
                ),
              ],
            ),
          ),

          Expanded(
            child: _selectedTab == 0
                ? _MedicinesTab(medicines: _medicines, isLoading: _isLoading)
                : const _OrdersTab(),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.goldPrimary : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MedicinesTab extends ConsumerWidget {
  final List<Map<String, dynamic>> medicines;
  final bool isLoading;

  const _MedicinesTab({required this.medicines, required this.isLoading});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    if (isLoading)
      return const Center(
        child: CircularProgressIndicator(color: AppColors.goldPrimary),
      );

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: medicines.length,
      itemBuilder: (context, index) {
        final med = medicines[index];
        final rawPrice = med['price'];
        final price = rawPrice is num
            ? rawPrice.toDouble()
            : double.tryParse(rawPrice?.toString() ?? '') ?? 0.0;
        final stock = med['stock'] ?? 0;
        final isRx = med['requiresPrescription'] == true;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassPanel(
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.goldLight.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    LucideIcons.pill,
                    color: AppColors.goldDark,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med['name'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      if (isRx)
                        Container(
                          margin: const EdgeInsets.only(top: 4, bottom: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            loc.translate('rxRequired'),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.warning,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        med['description'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹${price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.goldDark,
                            ),
                          ),
                          AppButton(
                            label: loc.translate('add'),
                            icon: const Icon(
                              LucideIcons.plus,
                              size: 16,
                              color: Colors.white,
                            ),
                            variant: AppButtonVariant.primary,
                            onPressed: stock > 0
                                ? () {
                                    ref
                                        .read(cartProvider.notifier)
                                        .addItem(med);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          loc.translate('addedToCart'),
                                        ),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: (index * 50).ms),
        );
      },
    );
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.package, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            loc.translate('noOrdersYet'),
            style: const TextStyle(fontSize: 16, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            loc.translate('yourMedicationOrders'),
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}
