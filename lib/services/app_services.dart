import 'auth_service.dart';
import 'order_service.dart';
import 'product_service.dart';
import 'user_service.dart';

// Všechny služby aplikace pohromadě, aby se daly snadno předávat obrazovkám
// (místo předávání každé služby zvlášť).
class AppServices {
  final AuthService auth;
  final UserService users;
  final ProductService products;
  final OrderService orders;

  const AppServices({
    required this.auth,
    required this.users,
    required this.products,
    required this.orders,
  });
}
