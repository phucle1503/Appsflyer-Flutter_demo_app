import 'package:flutter/material.dart';
import 'package:af_flutter_sample/model/cart.dart';
import 'checkout_page.dart';
// import 'package:clevertap_plugin/clevertap_plugin.dart';

class Cartpage extends StatelessWidget {
  const Cartpage({super.key});

  void _purchase(BuildContext context) {
    final chargeDetails = {
      'Amount': Cart.totalPrice(),
      'Payment Mode': 'Credit Card',
      'Charged ID': 'ORDER_${DateTime.now().millisecondsSinceEpoch}',
    };

    final List<Map<String, dynamic>> itemData = Cart.items
        .map((item) => {
              'Product Id': item.product.id,
              'Product Name': item.product.name,
              'Category': item.product.category,
              'Price': item.product.price,
              'Quantity': item.qty,
            })
        .toList();

    // CleverTapPlugin.recordChargedEvent(chargeDetails, itemData);

    for (final item in Cart.items) {
      item.product.stock =
          (item.product.stock - item.qty).clamp(0, double.infinity).toInt();
    }

    Cart.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đặt hàng thành công!')),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Checkoutpage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = Cart.items;
    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: cartItems.isEmpty
          ? const Center(child: Text('Giỏ hàng trống'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cartItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final c = cartItems[index];
                return ListTile(
                  title: Text(c.product.name),
                  subtitle:
                      Text('Category: ${c.product.category}  •  Qty: ${c.qty}'),
                  trailing:
                      Text('\$${(c.qty * c.product.price).toStringAsFixed(2)}'),
                );
              },
            ),
      bottomNavigationBar: Cart.items.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () => _purchase(context),
                child: const Text('Purchase'),
              ),
            ),
    );
  }
}
