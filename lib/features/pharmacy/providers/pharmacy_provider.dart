import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents an item in the cart
class CartItem {
  final Map<String, dynamic> medicine;
  int quantity;

  CartItem({required this.medicine, this.quantity = 1});
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addItem(Map<String, dynamic> medicine) {
    // Backend uses 'id' for Inventory model PK
    final medId = medicine['id'];
    final existingIndex = state.indexWhere((item) => item.medicine['id'] == medId);
    
    if (existingIndex >= 0) {
      final updated = List<CartItem>.from(state);
      updated[existingIndex] = CartItem(medicine: medicine, quantity: updated[existingIndex].quantity + 1);
      state = updated;
    } else {
      state = [...state, CartItem(medicine: medicine)];
    }
  }

  void removeItem(int medicineId) {
    state = state.where((item) => item.medicine['id'] != medicineId).toList();
  }

  void updateQuantity(int medicineId, int quantity) {
    if (quantity <= 0) {
      removeItem(medicineId);
      return;
    }
    final index = state.indexWhere((item) => item.medicine['id'] == medicineId);
    if (index >= 0) {
      final updated = List<CartItem>.from(state);
      updated[index] = CartItem(medicine: state[index].medicine, quantity: quantity);
      state = updated;
    }
  }

  void clearCart() {
    state = [];
  }

  double get totalAmount {
    return state.fold(0, (sum, item) {
      final price = (item.medicine['price'] as num?)?.toDouble() ?? 0.0;
      return sum + (price * item.quantity);
    });
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});
