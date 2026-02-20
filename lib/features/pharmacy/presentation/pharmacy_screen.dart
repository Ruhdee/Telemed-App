import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_logger.dart';



import '../../../shared/widgets/glass_panel.dart';
import '../../auth/providers/auth_provider.dart';


/// Pharmacy screen matching `pharmacy/page.tsx`.
///
/// Displays nearby pharmacies, order status, and delivery requests.
class PharmacyScreen extends ConsumerStatefulWidget {
  const PharmacyScreen({super.key});

  @override
  ConsumerState<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends ConsumerState<PharmacyScreen> {
  final List<Map<String, dynamic>> _pharmacies = [];
  bool _isLoading = true;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadPharmacies();
  }

  Future<void> _loadPharmacies() async {
    AppLogger.info('PHARMACY', 'Loading pharmacies');
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('/pharmacies');
      final data = response.data;
      if (data is List) {
        setState(() {
          _pharmacies.addAll(data.cast<Map<String, dynamic>>());
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      AppLogger.error('PHARMACY', 'Failed to load pharmacies', e);
      setState(() => _isLoading = false);
      // Show dummy data for UI
      setState(() {
        _pharmacies.addAll([
          {'name': 'MedPlus Pharmacy', 'address': '123 Health St', 'distance': '0.5 km', 'rating': 4.5, 'availability': 'Open'},
          {'name': 'Apollo Pharmacy', 'address': '456 Care Ave', 'distance': '1.2 km', 'rating': 4.8, 'availability': 'Open'},
          {'name': 'LifeCare Pharmacy', 'address': '789 Wellness Rd', 'distance': '2.0 km', 'rating': 4.2, 'availability': 'Closed'},
        ]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pharmacy')),
      body: Column(
        children: [
          // Tab bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _TabButton(label: 'Nearby', selected: _selectedTab == 0, onTap: () => setState(() => _selectedTab = 0)),
                const SizedBox(width: 8),
                _TabButton(label: 'Orders', selected: _selectedTab == 1, onTap: () => setState(() => _selectedTab = 1)),
                const SizedBox(width: 8),
                _TabButton(label: 'Delivery', selected: _selectedTab == 2, onTap: () => setState(() => _selectedTab = 2)),
              ],
            ),
          ),

          Expanded(
            child: _selectedTab == 0
                ? _NearbyTab(pharmacies: _pharmacies, isLoading: _isLoading)
                : _selectedTab == 1
                    ? const _OrdersTab()
                    : const _DeliveryTab(),
          ),
        ],
      ),
    );
  }
}

// ── Tab Button ─────────────────────────────────────────────────

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.selected, required this.onTap});

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

// ── Nearby Tab ─────────────────────────────────────────────────

class _NearbyTab extends StatelessWidget {
  final List<Map<String, dynamic>> pharmacies;
  final bool isLoading;

  const _NearbyTab({required this.pharmacies, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.goldPrimary));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pharmacies.length,
      itemBuilder: (context, index) {
        final p = pharmacies[index];
        final isOpen = p['availability'] == 'Open';
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassPanel(
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isOpen ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(LucideIcons.pill, color: isOpen ? AppColors.success : AppColors.error, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(p['address']?.toString() ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 12, color: AppColors.goldPrimary),
                          const SizedBox(width: 4),
                          Text('${p['rating'] ?? "N/A"}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 12),
                          Text(p['distance']?.toString() ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOpen ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isOpen ? 'Open' : 'Closed',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isOpen ? AppColors.success : AppColors.error),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: (index * 60).ms),
        );
      },
    );
  }
}

// ── Orders Tab ─────────────────────────────────────────────────

class _OrdersTab extends StatelessWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.package, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 16),
          const Text('No orders yet', style: TextStyle(fontSize: 16, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          const Text('Your medication orders will appear here', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ],
      ),
    ).animate().fadeIn();
  }
}

// ── Delivery Tab ───────────────────────────────────────────────

class _DeliveryTab extends StatelessWidget {
  const _DeliveryTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.truck, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 16),
          const Text('No active deliveries', style: TextStyle(fontSize: 16, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          const Text('Track your medicine deliveries here', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ],
      ),
    ).animate().fadeIn();
  }
}
