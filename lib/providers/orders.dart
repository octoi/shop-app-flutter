import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shop_app/config.dart';
import 'package:http/http.dart' as http;
import './cart.dart';

class OrderItem {
  final String id;
  final double amount;
  final List<CartItem> products;
  final DateTime dateTime;

  OrderItem({
    required this.id,
    required this.amount,
    required this.products,
    required this.dateTime,
  });
}

class Orders with ChangeNotifier {
  List<OrderItem> _orders = [];
  final String authToken;

  Orders(this.authToken, this._orders);

  List<OrderItem> get orders => [..._orders];

  Future<void> fetchAndSetOrders() async {
    final url = SERVER_URL + '/orders.json?auth=${this.authToken}';
    final response = await http.get(Uri.parse(url));

    final List<OrderItem> loadedOrders = [];
    final decodeData = json.decode(response.body);
    if (decodeData == null) return;
    final extractedData = decodeData as Map<String, dynamic>;

    extractedData.forEach((orderId, orderData) {
      loadedOrders.add(
        OrderItem(
          id: orderId,
          amount: orderData['amount'],
          dateTime: DateTime.parse(orderData['dateTime']),
          products: (orderData['products'] as List<dynamic>)
              .map(
                (item) => CartItem(
                  id: item['id'],
                  title: item['title'],
                  quantity: item['quantity'],
                  price: item['price'],
                ),
              )
              .toList(),
        ),
      );
    });

    _orders = loadedOrders.reversed.toList();
    notifyListeners();
  }

  Future<void> addOrder(List<CartItem> cartProducts, double total) async {
    final url = SERVER_URL + '/orders.json?auth=${this.authToken}';
    final timestamp = DateTime.now();

    final response = await http.post(
      Uri.parse(url),
      body: json.encode({
        'amount': total,
        'dateTime': timestamp.toIso8601String(),
        'products': cartProducts
            .map((cp) => {
                  'id': cp.id,
                  'title': cp.title,
                  'quantity': cp.quantity,
                  'price': cp.price,
                })
            .toList(),
      }),
    );
    _orders.insert(
      0,
      OrderItem(
        id: json.decode(response.body)['name'],
        amount: total,
        dateTime: timestamp,
        products: cartProducts,
      ),
    );
    notifyListeners();
  }
}
