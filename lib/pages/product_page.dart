import 'package:flutter/material.dart';
import 'package:clevertap_plugin/clevertap_plugin.dart';
import 'package:af_flutter_sample/model/product.dart';
import 'package:af_flutter_sample/model/cart.dart';
import 'cart_page.dart';

class Productpage extends StatelessWidget {
  Productpage({super.key});

  final List<Product> products = [
    Product(
      id: 'P001',
      name: 'Laptop Pro 15',
      price: 1299.99,
      category: 'Electronics',
      stock: 10,
    ),
    Product(
      id: 'P002',
      name: 'Gaming Mouse',
      price: 59.99,
      category: 'Accessories',
      stock: 25,
    ),
    Product(
      id: 'P003',
      name: 'Bluetooth Speaker',
      price: 89.99,
      category: 'Audio',
      stock: 18,
    ),
    Product(
      id: 'P004',
      name: 'Smart Watch',
      price: 149.99,
      category: 'Wearables',
      stock: 12,
    ),
  ];

  void _addToCart(BuildContext context, Product product) {
    Cart.add(product);

    final eventData = {
      'ProductId': product.id,
      'Price': product.price,
      'Category': product.category,
      'Quantity': 1,
    };
    CleverTapPlugin.recordEvent("Add to Cart", eventData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} đã được thêm vào giỏ hàng.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product Page')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('ID: ${product.id}'),
                  Text('Price: \$${product.price.toStringAsFixed(2)}'),
                  Text('Category: ${product.category}'),
                  Text('Stock Available: ${product.stock}'),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => _addToCart(context, product),
                      child: const Text('Add to Cart'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const Cartpage()),
        ),
        icon: const Icon(Icons.shopping_cart),
        label: const Text('Go to Cart'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
