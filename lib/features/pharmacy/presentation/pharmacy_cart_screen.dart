import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/constants/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/glass_panel.dart';
import '../providers/pharmacy_provider.dart';

class PharmacyCartScreen extends ConsumerStatefulWidget {
  const PharmacyCartScreen({super.key});

  @override
  ConsumerState<PharmacyCartScreen> createState() => _PharmacyCartScreenState();
}

class _PharmacyCartScreenState extends ConsumerState<PharmacyCartScreen> {
  final TextEditingController _addressController = TextEditingController();
  bool _isCheckingOut = false;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _checkout() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    if (_addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter delivery address'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isCheckingOut = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      
      final items = cart.map((item) => {
        'id': item.medicine['id'],
        'qty': item.quantity,
        'price': item.medicine['price'],
      }).toList();

      await apiClient.post(
        ApiConstants.pharmaCheckoutEndpoint,
        data: {
          'items': items,
          'address': _addressController.text,
          'totalAmount': ref.read(cartProvider.notifier).totalAmount,
        },
      );

      ref.read(cartProvider.notifier).clearCart();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully!'), backgroundColor: AppColors.success),
        );
        context.pop();
      }
    } catch (e) {
      AppLogger.error('Pharmacy Cart', 'Checkout failed', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checkout failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final total = ref.read(cartProvider.notifier).totalAmount;

    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: cart.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.shoppingCart, size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  const Text('Your cart is empty', style: TextStyle(fontSize: 18, color: AppColors.textMuted)),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Browse Medicines',
                    variant: AppButtonVariant.primary,
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.length,
                    itemBuilder: (context, index) {
                      final item = cart[index];
                      final med = item.medicine;
                      final price = (med['price'] as num?)?.toDouble() ?? 0.0;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassPanel(
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: AppColors.goldLight.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(LucideIcons.pill, color: AppColors.goldDark),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(med['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    Text('\$${price.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.goldDark, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(LucideIcons.minusCircle),
                                    onPressed: () => ref.read(cartProvider.notifier).updateQuantity(med['id'], item.quantity - 1),
                                  ),
                                  Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(LucideIcons.plusCircle),
                                    onPressed: () => ref.read(cartProvider.notifier).updateQuantity(med['id'], item.quantity + 1),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                GlassPanel(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          hintText: 'Delivery Address',
                          prefixIcon: const Icon(LucideIcons.mapPin),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.goldDark)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        label: 'Checkout',
                        variant: AppButtonVariant.primary,
                        isLoading: _isCheckingOut,
                        onPressed: _checkout,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
