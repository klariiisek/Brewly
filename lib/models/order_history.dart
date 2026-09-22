import 'order.dart';

class OrderHistory {
  final List<Order> orders = [];

  void addOrder(Order order) {
    orders.add(order);
  }
}